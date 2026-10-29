package com.nabbeh.app.db

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * تعريف جداول قاعدة البيانات المشفرة (Room + SQLCipher)
 * كل الجداول محلية بالكامل ولا تغادر الهاتف أبداً
 */

/** تصنيفات المصنّف الثابتة — تُخزَّن كنص */
object Categories {
    const val MOHTIME = "MOHTIME" // موعد
    const val MASROOF = "MASROOF" // مصروف
    const val MAHMMA = "MAHMMA"   // مهمة
    const val TAJAHUL = "TAJAHUL" // تجاهل
}

/** الإجراء المتخذ على الإشعار */
object Actions {
    const val PENDING = "PENDING"                        // بانتظار تأكيد المستخدم
    const val CONFIRMED_TASK = "CONFIRMED_TASK"          // أُضيفت مهمة
    const val CONFIRMED_EVENT = "CONFIRMED_EVENT"        // أُضيف موعد
    const val CONFIRMED_TRANSACTION = "CONFIRMED_TRANSACTION" // سُجّل مصروف
    const val AUTO_RULE = "AUTO_RULE"                    // نُفِّذت قاعدة تلقائية
    const val DISMISSED = "DISMISSED"                    // تجاهل
}

/** حالة المهمة */
object TaskStatus {
    const val PENDING = "PENDING"
    const val DONE = "DONE"
}

/** جدول الإشعارات المُلتقطة والمصنَّفة */
@Entity(tableName = "notifications")
data class NotificationEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val packageName: String,
    val appName: String,
    val title: String,
    val body: String,
    val timestamp: Long,
    val category: String,
    val confidence: Float,
    val dueDate: Long?,      // الوقت المستخرج من نص الإشعار إن وُجد
    val amount: Double?,     // المبلغ المستخرج إن وُجد
    val merchant: String?,   // الجهة المستخرجة إن وُجدت
    val actionTaken: String,
    val createdAt: Long
)

/** جدول المهام والمواعيد (الموعد = مهمة بتاريخ وقت تضاف للتقويم) */
@Entity(tableName = "tasks")
data class TaskEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val title: String,
    val notes: String,
    val dueDate: Long?,
    val isAppointment: Boolean,
    val location: String?,
    val status: String,
    val sourceNotificationId: Long?,
    val calendarEventId: Long?, // معرف الحدث في تقويم النظام بعد الإضافة
    val createdAt: Long,
    val updatedAt: Long
)

/** جدول المعاملات المالية */
@Entity(tableName = "transactions")
data class TransactionEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val amount: Double,
    val currency: String,
    val merchant: String,
    val description: String,
    val category: String,
    val spentAt: Long,
    val sourceNotificationId: Long?,
    val createdAt: Long
)

/** جدول قواعد المستخدم: تطبيق + كلمة + إجراء */
@Entity(tableName = "rules")
data class RuleEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val appFilter: String,  // اسم حزمة التطبيق أو "*" لكل التطبيقات
    val keyword: String,    // كلمة مفتاحية (فارغة = أي نص)
    val actionType: String, // CREATE_TASK / CREATE_EVENT / CREATE_TRANSACTION / IGNORE
    val enabled: Boolean,
    val createdAt: Long
)

/** جدول إعدادات مراقبة التطبيقات (الخصوصية: تفعيل/تعطيل لكل تطبيق) */
@Entity(tableName = "app_settings")
data class AppSettingEntity(
    @PrimaryKey val packageName: String,
    val appName: String,
    val enabled: Boolean,
    val lastUsedAt: Long
)
