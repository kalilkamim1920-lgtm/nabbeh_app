package com.nabbeh.app.service

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import com.nabbeh.app.db.ActionType
import com.nabbeh.app.db.Actions
import com.nabbeh.app.db.AppDatabase
import com.nabbeh.app.db.AppSettingEntity
import com.nabbeh.app.db.Categories
import com.nabbeh.app.db.NotificationEntity
import com.nabbeh.app.db.TaskEntity
import com.nabbeh.app.db.TaskStatus
import com.nabbeh.app.db.TransactionEntity
import com.nabbeh.app.logic.CalendarHelper
import com.nabbeh.app.logic.RulesEngine
import com.nabbeh.app.ml.ClassificationResult
import com.nabbeh.app.ml.ClassifierHelper
import com.nabbeh.app.security.CryptoHelper
import com.nabbeh.app.util.EventBus
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.util.concurrent.ConcurrentHashMap

/**
 * خدمة التقاط الإشعارات — قلب نبّه النابض
 *
 * دورة حياة كل إشعار:
 * 1) فلترة سريعة (إشعاراتنا، الجارية، الفارغة)
 * 2) التحقق من المفتاح الرئيسي وإعدادات التطبيق المصدر (الخصوصية)
 * 3) تقييم قواعد المستخدم أولاً — ثم المصنّف المحلي
 * 4) حفظ الإشعار مشفراً في قاعدة SQLCipher
 * 5) تنفيذ القواعد الأوتوماتيكية ونبض الواجهة عبر EventBus
 */
class NotificationService : NotificationListenerService() {

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val recentFingerprints = ConcurrentHashMap<String, Long>()

    override fun onDestroy() {
        serviceScope.cancel()
        super.onDestroy()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        // 1) تجاهل إشعارات نبّه نفسه كي لا نصنع حلقة لا نهائية
        if (sbn.packageName == packageName) return
        val extras = sbn.notification?.extras ?: return
        if (sbn.isOngoing) return // الإشعارات الجارية (مثل مشغل الموسيقى) تُتجاهل

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim() ?: ""
        val body = (
            extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
                ?: extras.getCharSequence(Notification.EXTRA_TEXT)
            )?.toString()?.trim() ?: ""
        if (title.isBlank() && body.isBlank()) return

        serviceScope.launch {
            try {
                val crypto = CryptoHelper.getInstance(applicationContext)
                if (!crypto.isMasterEnabled()) return@launch // المفتاح الرئيسي متوقف

                val db = AppDatabase.getInstance(applicationContext)
                val now = System.currentTimeMillis()

                // منع تكرار نفس الإشعار خلال ثانيتين (بعض التطبيقات تنشره مرتين)
                val fingerprint = "${sbn.packageName}|$title|$body"
                val lastSeen = recentFingerprints[fingerprint]
                if (lastSeen != null && now - lastSeen < 2000) return@launch
                recentFingerprints[fingerprint] = now
                if (recentFingerprints.size > 200) recentFingerprints.clear()

                // 2) الخصوصية: تحقق من إعدادات التطبيق المصدر
                val appSetting = db.appSettingDao().get(sbn.packageName)
                if (appSetting == null) {
                    // أول إشعار من تطبيق جديد → نضيفه للقائمة مفعلاً (يستطيع المستخدم تعطيله)
                    db.appSettingDao().upsert(
                        AppSettingEntity(
                            packageName = sbn.packageName,
                            appName = getAppName(sbn.packageName),
                            enabled = true,
                            lastUsedAt = now
                        )
                    )
                } else if (!appSetting.enabled) {
                    return@launch // المستخدم عطّل هذا التطبيق — لا قراءة ولا حفظ
                }

                // 3) قواعد المستخدم أولاً ثم المصنّف المحلي
                val matchedRule = RulesEngine(db.ruleDao()).evaluate(sbn.packageName, title, body)
                val result = ClassifierHelper.classify(title, body)
                val category = matchedRule?.let {
                    RulesEngine.ruleToCategory(it.actionType)
                } ?: result.category.name

                val actionTaken = when {
                    matchedRule != null && matchedRule.actionType != ActionType.IGNORE -> Actions.AUTO_RULE
                    matchedRule != null -> Actions.DISMISSED
                    category == Categories.TAJAHUL -> Actions.DISMISSED
                    else -> Actions.PENDING
                }

                // 4) حفظ مشفر
                val notificationId = db.notificationDao().insert(
                    NotificationEntity(
                        packageName = sbn.packageName,
                        appName = getAppName(sbn.packageName),
                        title = title,
                        body = body,
                        timestamp = sbn.postTime,
                        category = category,
                        confidence = matchedRule?.let { 1f } ?: result.confidence,
                        dueDate = result.dueDate,
                        amount = result.amount,
                        merchant = result.merchant,
                        actionTaken = actionTaken,
                        createdAt = now
                    )
                )

                // 5) تنفيذ القاعدة الأوتوماتيكية إن كانت من نوع إنشاء
                if (matchedRule != null && matchedRule.actionType != ActionType.IGNORE) {
                    executeRule(db, matchedRule, notificationId, title, body, result)
                }

                // نبض الواجهة
                EventBus.send(
                    JSONObject()
                        .put("type", "new_notification")
                        .put("id", notificationId)
                        .put("category", category)
                        .toString()
                )
            } catch (e: Exception) {
                Log.e(TAG, "خطأ في معالجة الإشعار", e)
            }
        }
    }

    /** تنفيذ قاعدة مستخدم من نوع إنشاء مباشرة بدون سؤال */
    private suspend fun executeRule(
        db: AppDatabase,
        rule: com.nabbeh.app.db.RuleEntity,
        notificationId: Long,
        title: String,
        body: String,
        result: ClassificationResult
    ) {
        when (rule.actionType) {
            ActionType.CREATE_TASK, ActionType.CREATE_EVENT -> {
                val isAppointment = rule.actionType == ActionType.CREATE_EVENT
                val taskId = db.taskDao().insert(
                    TaskEntity(
                        title = title.ifBlank { body.take(50) },
                        notes = body,
                        dueDate = result.dueDate,
                        isAppointment = isAppointment,
                        location = null,
                        status = TaskStatus.PENDING,
                        sourceNotificationId = notificationId,
                        calendarEventId = null,
                        createdAt = System.currentTimeMillis(),
                        updatedAt = System.currentTimeMillis()
                    )
                )
                // الموعدات تضاف للتقويم تلقائياً عند توفر الصلاحية والوقت
                if (isAppointment && result.dueDate != null &&
                    CalendarHelper.hasCalendarPermission(applicationContext)
                ) {
                    val eventId = CalendarHelper.addEvent(
                        applicationContext,
                        title.ifBlank { "موعد من نبّه" },
                        body,
                        result.dueDate
                    )
                    if (eventId > 0) db.taskDao().setCalendarEvent(taskId, eventId)
                }
                db.notificationDao().updateAction(
                    notificationId,
                    if (isAppointment) Actions.CONFIRMED_EVENT else Actions.CONFIRMED_TASK
                )
            }

            ActionType.CREATE_TRANSACTION -> {
                val amount = result.amount ?: return // بلا مبلغ → نتركه للمراجعة اليدوية
                db.transactionDao().insert(
                    TransactionEntity(
                        amount = amount,
                        currency = CryptoHelper.getInstance(applicationContext).getCurrency(),
                        merchant = result.merchant ?: "",
                        description = title,
                        category = "عام",
                        spentAt = System.currentTimeMillis(),
                        sourceNotificationId = notificationId,
                        createdAt = System.currentTimeMillis()
                    )
                )
                db.notificationDao().updateAction(notificationId, Actions.CONFIRMED_TRANSACTION)
            }
        }
    }

    private fun getAppName(pkg: String): String = try {
        packageManager.getApplicationLabel(
            packageManager.getApplicationInfo(pkg, 0)
        ).toString()
    } catch (e: Exception) {
        pkg
    }

    companion object {
        private const val TAG = "NabbehService"
    }
}
