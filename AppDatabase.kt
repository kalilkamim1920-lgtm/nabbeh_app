package com.nabbeh.app.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.nabbeh.app.security.CryptoPassphraseProvider
import net.sqlcipher.database.SQLiteDatabase
import net.sqlcipher.database.SupportOpenHelperFactory

/**
 * قاعدة البيانات المشفرة — Room فوق SQLCipher
 * ملف قاعدة البيانات مشفر بمفتاح 256-بت عشوائي يُولَّد مرة واحدة
 * ويُخزن داخل EncryptedSharedPreferences (المحمي بـ Android Keystore)
 */
@Database(
    entities = [
        NotificationEntity::class,
        TaskEntity::class,
        TransactionEntity::class,
        RuleEntity::class,
        AppSettingEntity::class
    ],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {

    abstract fun notificationDao(): NotificationDao
    abstract fun taskDao(): TaskDao
    abstract fun transactionDao(): TransactionDao
    abstract fun ruleDao(): RuleDao
    abstract fun appSettingDao(): AppSettingDao

    companion object {
        private const val DB_NAME = "nabbeh_encrypted.db"

        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: build(context.applicationContext).also { INSTANCE = it }
            }

        private fun build(context: Context): AppDatabase {
            // مفتاح التشفير من الخزنة الآمنة
            val passphrase = CryptoPassphraseProvider.getPassphrase(context)
            SQLiteDatabase.loadLibs(context)
            val factory = SupportOpenHelperFactory(passphrase)

            return Room.databaseBuilder(context, AppDatabase::class.java, DB_NAME)
                .openHelperFactory(factory)
                .fallbackToDestructiveMigration()
                .build()
        }
    }
}
