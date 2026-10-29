package com.nabbeh.app.ml

import java.util.Calendar
import java.util.Locale

/**
 * المصنّف المحلي — يعمل 100% على الجهاز بدون أي نموذج سحابي
 *
 * آلية العمل (تصنيف هجين):
 * 1) قوائم كلمات مفتاحية عربية/إنجليزية بأوزان لكل تصنيف
 * 2) تطبيع النص العربي (إزالة التشكيل وتوحيد الحروف) لرفع دقة المطابقة
 * 3) استخراج جانبي: الوقت (الساعة/التاريخ/غداً) والمبلغ والجهة
 * 4) جاهزية لاستبدال/دمج نموذج TFLite محلي مستقبلاً (أنشئ مجلد assets
 *    وضع فيه nabbeh_classifier.tflite وحلّل النتيجة في classifyWithModel)
 */
enum class Category { MOHTIME, MASROOF, MAHMMA, TAJAHUL }

data class ClassificationResult(
    val category: Category,
    val confidence: Float,
    val dueDate: Long?,
    val amount: Double?,
    val merchant: String?
)

class ClassifierHelper {

    companion object {

        /** أقل مجموع أوزان لإعادة تصنيف غير المُتجاهَل */
        const val MIN_SCORE = 2.0f

        // ===== كلمات المواعيد =====
        private val MOHTIME_KEYWORDS = mapOf(
            "موعد" to 2f, "اجتماع" to 2f, "تذكير" to 1f, "مقابلة" to 2f,
            "حجز" to 1.5f, "دعوة" to 1.5f, "الساعة" to 1f, "غدا" to 1f,
            "دورة" to 1f, "ورشة" to 1.5f, "زيارة" to 1.5f, "موعدك" to 2f,
            "meeting" to 2f, "appointment" to 2.5f, "reminder" to 1f,
            "event" to 1.5f, "schedule" to 1.5f, "reservation" to 1.5f,
            "booking" to 1.5f, "invite" to 1.5f, "interview" to 2f,
            "webinar" to 1.5f, "tomorrow at" to 1.5f
        )

        // ===== كلمات المصاريف =====
        private val MASROOF_KEYWORDS = mapOf(
            "تم خصم" to 3f, "خصم" to 2f, "دفعت" to 2f, "سددت" to 2f,
            "فاتورة" to 2f, "اشتراك" to 1.5f, "عملية شراء" to 2.5f,
            "تمت عملية" to 2f, "بطاقتك" to 2f, "محفظتك" to 2f,
            "مبلغ" to 1f, "إيصال" to 2f, "دفع" to 1.5f, "تحويل مالي" to 2f,
            "شراء" to 1.5f, "رصيدك" to 1.5f, "استهلاك" to 1f,
            "paid" to 2f, "payment" to 2f, "purchase" to 2.5f, "spent" to 2f,
            "deducted" to 3f, "invoice" to 2f, "subscription" to 1.5f,
            "receipt" to 2f, "charged" to 2.5f, "debit" to 2f, "bill" to 1.5f,
            "order" to 1.5f, "transaction" to 1.5f, "wallet" to 1.5f
        )

        // ===== كلمات المهام =====
        private val MAHMMA_KEYWORDS = mapOf(
            "مهمة" to 2f, "لا تنس" to 2.5f, "تسليم" to 2f, "يرجى" to 1f,
            "إجراء مطلوب" to 3f, "استكمل" to 1.5f, "انتهاء" to 1.5f,
            "الموعد النهائي" to 2.5f, "موعد نهائي" to 3f, "نهائي" to 1f,
            "قبل تاريخ" to 2f, "تحديث بياناتك" to 2f, "تحقق" to 1.5f,
            "أكمل" to 1.5f, "تأكد" to 1.5f, "فعّل" to 1.5f, "قائمة" to 1f,
            "task" to 2f, "deadline" to 2.5f, "todo" to 2f,
            "action required" to 3f, "complete your" to 2f, "submit" to 2f,
            "verify" to 1.5f, "don't forget" to 2.5f, "expires" to 2f,
            "due" to 2f, "required" to 1.5f, "update your" to 1.5f, "renew" to 2f
        )

        // استخراج المبلغ مع رموز عملات عربية وإنجليزية
        private val AMOUNT_REGEX = Regex(
            "(?:SR|SAR|ريال|ر\\.?س|درهم|AED|جنيه|EGP|USD|KWD|QAR|JOD|\\$|€|£)\\s*([0-9]+(?:[.,][0-9]+)?)" +
                "|([0-9]+(?:[.,][0-9]+)?)\\s*(?:ريال|ر\\.?س|SAR|SR|درهم|AED|جنيه|USD|KWD|QAR|JOD)",
            RegexOption.IGNORE_CASE
        )
        private val ANY_NUMBER_REGEX = Regex("\\d+(?:[.,]\\d+)?")
        private val TIME_REGEX = Regex(
            "(?:الساعة|في الساعة|at)\\s*(\\d{1,2})(?:[:.٫:](\\d{2}))?",
            RegexOption.IGNORE_CASE
        )
        private val DATE_REGEX = Regex("(\\d{1,2})[/\\-](\\d{1,2})(?:[/\\-](\\d{2,4}))?")
        private val AFTER_DAYS_REGEX = Regex("بعد\\s*(\\d+)\\s*يوم")
        private val TOMORROW_REGEX = Regex("غدا|بكرة|بكره|tomorrow", RegexOption.IGNORE_CASE)

        /** تطبيع النص العربي: إزالة التشكيل + توحيد الألف والتاء المربوطة والألف المقصورة */
        fun normalize(text: String): String =
            text
                .replace(Regex("[\\u064B-\\u065F\\u0670]"), "")
                .replace('أ', 'ا').replace('إ', 'ا').replace('آ', 'ا')
                .replace('ة', 'ه').replace('ى', 'ي')
                .lowercase(Locale.ROOT)

        /** حساب مجموع أوزان الكلمات الموجودة في النص */
        private fun score(keywords: Map<String, Float>, text: String): Float =
            keywords.entries.fold(0f) { acc, (kw, w) ->
                if (text.contains(normalize(kw))) acc + w else acc
            }

        /** النقطة الرئيسية: تصنيف نص الإشعار */
        fun classify(rawTitle: String, rawBody: String): ClassificationResult {
            val title = normalize(rawTitle)
            val body = normalize(rawBody)
            val fullText = "$title $body"
            val rawSource = rawBody.ifBlank { rawTitle }

            val moh = score(MOHTIME_KEYWORDS, fullText)
            val mas = score(MASROOF_KEYWORDS, fullText)
            val mah = score(MAHMMA_KEYWORDS, fullText)
            val best = maxOf(moh, mas, mah)

            // الأولوية عند التعادل: مصروف ثم موعد ثم مهمة (المال أدق من الوقت)
            val category = when {
                best < MIN_SCORE -> Category.TAJAHUL
                mas >= moh && mas >= mah -> Category.MASROOF
                moh >= mah -> Category.MOHTIME
                else -> Category.MAHMMA
            }

            val due = extractDueDate(rawSource)
            val amount = extractAmount(rawSource)
                ?: if (category == Category.MASROOF) extractLargestNumber(rawSource) else null
            val merchant = if (category == Category.MASROOF) extractMerchant(rawTitle, rawBody) else null

            val confidence = if (category == Category.TAJAHUL) {
                0.5f
            } else {
                (best / (best + 2f)).coerceIn(0f, 1f)
            }

            return ClassificationResult(category, confidence, due, amount, merchant)
        }

        // ===== الاستخراجات المساعدة =====

        /** استخراج المبلغ المرتبط برمز عملة */
        fun extractAmount(rawText: String): Double? {
            val m = AMOUNT_REGEX.find(rawText) ?: return null
            val number = (m.groupValues[1].ifBlank { m.groupValues[2] }).replace(",", ".")
            return number.toDoubleOrNull()
        }

        /** خطة بديلة: أكبر رقم في النص (يُستخدم للمصاريف فقط) */
        fun extractLargestNumber(rawText: String): Double? =
            ANY_NUMBER_REGEX.findAll(rawText)
                .mapNotNull { it.value.replace(",", ".").toDoubleOrNull() }
                .maxOrNull()

        /**
         * استخراج وقت الموعد من نص عربي أو إنجليزي
         * يدعم: "الساعة 9:30"، "غداً"، "اليوم"، "بعد 3 يوم"، "15/3"
         */
        fun extractDueDate(rawText: String): Long? {
            if (rawText.isBlank()) return null
            val text = normalize(rawText)
            val nowCal = Calendar.getInstance()
            val target = (nowCal.clone() as Calendar)
            var matched = false

            // تاريخ صريح يوم/شهر[/سنة]
            val dateMatch = DATE_REGEX.find(text)
            if (dateMatch != null) {
                val day = dateMatch.groupValues[1].toIntOrNull() ?: 0
                val month = dateMatch.groupValues[2].toIntOrNull() ?: 0
                var year = dateMatch.groupValues[3].takeIf { it.isNotBlank() }
                    ?.toIntOrNull() ?: nowCal.get(Calendar.YEAR)
                if (year < 100) year += 2000
                if (month in 1..12 && day in 1..31) {
                    target.set(year, month - 1, day, 9, 0, 0)
                    target.set(Calendar.MILLISECOND, 0)
                    matched = true
                }
            }

            // بعد N يوم
            AFTER_DAYS_REGEX.find(text)?.let { m ->
                val days = m.groupValues[1].toIntOrNull() ?: 0
                if (days > 0) {
                    target.add(Calendar.DAY_OF_YEAR, days)
                    matched = true
                }
            }

            // غداً
            if (TOMORROW_REGEX.containsMatchIn(text)) {
                target.add(Calendar.DAY_OF_YEAR, 1)
                matched = true
            }

            // وقت الساعة
            val timeMatch = TIME_REGEX.find(text)
            if (timeMatch != null) {
                val hour = timeMatch.groupValues[1].toIntOrNull() ?: -1
                val minute = timeMatch.groupValues[2].takeIf { it.isNotBlank() }
                    ?.toIntOrNull() ?: 0
                if (hour in 0..23 && minute in 0..59) {
                    target.set(Calendar.HOUR_OF_DAY, hour)
                    target.set(Calendar.MINUTE, minute)
                    target.set(Calendar.SECOND, 0)
                    target.set(Calendar.MILLISECOND, 0)
                    matched = true
                    // الوقت فات اليوم ولم يُذكر غد أو تاريخ مستقبلي → نفترض غداً
                    if (target.timeInMillis <= nowCal.timeInMillis &&
                        !TOMORROW_REGEX.containsMatchIn(text) && dateMatch == null
                    ) {
                        target.add(Calendar.DAY_OF_YEAR, 1)
                    }
                }
            }

            return if (matched) target.timeInMillis else null
        }

        /** محاولة استخراج اسم الجهة/المتجر من النص */
        fun extractMerchant(rawTitle: String, rawBody: String): String? {
            val text = "$rawTitle $rawBody"
            val patterns = listOf(
                Regex("من\\s+(?:متجر|تطبيق|موقع|شركة)?\\s*([^\\d،,.!؟?\\n]{2,25})"),
                Regex("(?:متجر|تطبيق|موقع)\\s+([^\\d،,.!؟?\\n]{2,25})")
            )
            for (p in patterns) {
                val m = p.find(text) ?: continue
                val candidate = m.groupValues[1].trim()
                if (candidate.length in 2..25) return candidate
            }
            return rawTitle.trim().takeIf { it.length in 2..25 }
        }
    }
}
