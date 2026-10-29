package com.nabbeh.app.security

import android.content.Context
import android.content.SharedPreferences
import android.util.Base64
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import java.security.SecureRandom

/**
 * خزنة الإعدادات الحساسة:
 * - EncryptedSharedPreferences بمفتاح رئيسي محفوظ في Android Keystore
 * - تخزن: المفتاح الرئيسي للتصنيف، تنفيذ القواعد التلقائي، العملة، مفتاح قاعدة البيانات
 * - خطة بديلة عند فشل Keystore على بعض الأجهزة: تخزين عادي مع استمرار العمل
 */
class CryptoHelper private constructor(context: Context) {

    private val prefs: SharedPreferences = try {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        EncryptedSharedPreferences.create(
            context,
            PREFS_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    } catch (e: Exception) {
        // خطة بديلة — التطبيق يستمر بالعمل ولو بقدر حماية أقل للإعدادات
        context.getSharedPreferences("${PREFS_NAME}_fallback", Context.MODE_PRIVATE)
    }

    // ===== المفتاح الرئيسي =====
    fun isMasterEnabled(): Boolean = prefs.getBoolean(KEY_MASTER_ENABLED, true)
    fun setMasterEnabled(value: Boolean) =
        prefs.edit().putBoolean(KEY_MASTER_ENABLED, value).apply()

    // ===== تنفيذ القواعد تلقائياً =====
    fun isAutoApplyRules(): Boolean = prefs.getBoolean(KEY_AUTO_RULES, false)
    fun setAutoApplyRules(value: Boolean) =
        prefs.edit().putBoolean(KEY_AUTO_RULES, value).apply()

    // ===== العملة =====
    fun getCurrency(): String = prefs.getString(KEY_CURRENCY, "SAR") ?: "SAR"
    fun setCurrency(value: String) = prefs.edit().putString(KEY_CURRENCY, value).apply()

    /**
     * مفتاح تشفير قاعدة البيانات: 32 بايت عشوائية تُولَّد مرة واحدة ثم تُخزن مشفرة
     */
    @Synchronized
    fun getDbPassphrase(): ByteArray {
        val saved = prefs.getString(KEY_DB_PASSPHRASE, null)
        if (saved != null) return Base64.decode(saved, Base64.NO_WRAP)
        val bytes = ByteArray(32).also { SecureRandom().nextBytes(it) }
        prefs.edit()
            .putString(KEY_DB_PASSPHRASE, Base64.encodeToString(bytes, Base64.NO_WRAP))
            .apply()
        return bytes
    }

    /**
     * زر "احذف كل بياناتي": يمسح كل الإعدادات المشفرة
     * مع الحفاظ على مفتاح قاعدة البيانات لأن ملفها يُمسح عبر DAO وليس حذف الملف
     */
    @Synchronized
    fun deleteAll() {
        val passphrase = Base64.encodeToString(getDbPassphrase(), Base64.NO_WRAP)
        prefs.edit().clear().putString(KEY_DB_PASSPHRASE, passphrase).commit()
    }

    companion object {
        private const val PREFS_NAME = "nabbeh_secure_prefs"
        private const val KEY_MASTER_ENABLED = "master_enabled"
        private const val KEY_AUTO_RULES = "auto_apply_rules"
        private const val KEY_CURRENCY = "currency"
        private const val KEY_DB_PASSPHRASE = "db_passphrase"

        @Volatile
        private var instance: CryptoHelper? = null

        fun getInstance(context: Context): CryptoHelper =
            instance ?: synchronized(this) {
                instance ?: CryptoHelper(context.applicationContext).also { instance = it }
            }
    }
}

/** مزود مفتاح قاعدة البيانات يفصل الاعتماد بين AppDatabase و CryptoHelper */
object CryptoPassphraseProvider {
    fun getPassphrase(context: Context): ByteArray =
        CryptoHelper.getInstance(context).getDbPassphrase()
}
