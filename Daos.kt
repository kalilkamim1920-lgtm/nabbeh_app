package com.nabbeh.app.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query

/**
 * واجهات الوصول للبيانات (DAO) — كل الاستعلامات عبر Coroutines
 */

@Dao
interface NotificationDao {
    @Insert
    suspend fun insert(n: NotificationEntity): Long

    @Query(
        "SELECT * FROM notifications WHERE actionTaken = 'PENDING' AND category != 'TAJAHUL' " +
            "ORDER BY timestamp DESC"
    )
    suspend fun getPending(): List<NotificationEntity>

    @Query("SELECT * FROM notifications ORDER BY timestamp DESC LIMIT :limit OFFSET :offset")
    suspend fun getRecent(limit: Int, offset: Int): List<NotificationEntity>

    @Query(
        "SELECT * FROM notifications WHERE category = :category " +
            "ORDER BY timestamp DESC LIMIT :limit OFFSET :offset"
    )
    suspend fun getByCategory(category: String, limit: Int, offset: Int): List<NotificationEntity>

    @Query("SELECT * FROM notifications WHERE id = :id")
    suspend fun getById(id: Long): NotificationEntity?

    @Query("UPDATE notifications SET actionTaken = :action WHERE id = :id")
    suspend fun updateAction(id: Long, action: String)

    @Query("DELETE FROM notifications")
    suspend fun deleteAll()

    @Query("DELETE FROM notifications WHERE timestamp < :before")
    suspend fun deleteOlderThan(before: Long)
}

@Dao
interface TaskDao {
    @Insert
    suspend fun insert(t: TaskEntity): Long

    @Query(
        "SELECT * FROM tasks WHERE dueDate BETWEEN :from AND :to AND isAppointment = :isAppointment " +
            "ORDER BY dueDate ASC"
    )
    suspend fun getBetween(from: Long, to: Long, isAppointment: Boolean): List<TaskEntity>

    @Query(
        "SELECT * FROM tasks WHERE isAppointment = :isAppointment " +
            "ORDER BY CASE status WHEN 'PENDING' THEN 0 ELSE 1 END, dueDate IS NULL, dueDate ASC"
    )
    suspend fun getAll(isAppointment: Boolean): List<TaskEntity>

    @Query("SELECT * FROM tasks WHERE id = :id")
    suspend fun getById(id: Long): TaskEntity?

    @Query("UPDATE tasks SET status = :status, updatedAt = :updatedAt WHERE id = :id")
    suspend fun updateStatus(id: Long, status: String, updatedAt: Long)

    @Query("UPDATE tasks SET calendarEventId = :eventId WHERE id = :id")
    suspend fun setCalendarEvent(id: Long, eventId: Long)

    @Query("DELETE FROM tasks WHERE id = :id")
    suspend fun delete(id: Long)

    @Query("DELETE FROM tasks")
    suspend fun deleteAll()
}

@Dao
interface TransactionDao {
    @Insert
    suspend fun insert(t: TransactionEntity): Long

    @Query("SELECT * FROM transactions WHERE spentAt BETWEEN :from AND :to ORDER BY spentAt DESC")
    suspend fun getBetween(from: Long, to: Long): List<TransactionEntity>

    @Query("SELECT * FROM transactions ORDER BY spentAt DESC LIMIT 500")
    suspend fun getAll(): List<TransactionEntity>

    @Query("SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE spentAt BETWEEN :from AND :to")
    suspend fun sumBetween(from: Long, to: Long): Double

    @Query("DELETE FROM transactions WHERE id = :id")
    suspend fun delete(id: Long)

    @Query("DELETE FROM transactions")
    suspend fun deleteAll()
}

@Dao
interface RuleDao {
    @Insert
    suspend fun insert(r: RuleEntity): Long

    @Query("SELECT * FROM rules WHERE enabled = 1 ORDER BY createdAt ASC")
    suspend fun getEnabled(): List<RuleEntity>

    @Query("SELECT * FROM rules ORDER BY createdAt ASC")
    suspend fun getAll(): List<RuleEntity>

    @Query("UPDATE rules SET enabled = :enabled WHERE id = :id")
    suspend fun setEnabled(id: Long, enabled: Boolean)

    @Query("DELETE FROM rules WHERE id = :id")
    suspend fun delete(id: Long)

    @Query("DELETE FROM rules")
    suspend fun deleteAll()
}

@Dao
interface AppSettingDao {
    @Insert
    suspend fun upsert(setting: AppSettingEntity)

    @Query("SELECT * FROM app_settings WHERE packageName = :packageName")
    suspend fun get(packageName: String): AppSettingEntity?

    @Query("SELECT * FROM app_settings ORDER BY appName ASC")
    suspend fun getAll(): List<AppSettingEntity>

    @Query("UPDATE app_settings SET enabled = :enabled WHERE packageName = :packageName")
    suspend fun setEnabled(packageName: String, enabled: Boolean)

    @Query("DELETE FROM app_settings")
    suspend fun deleteAll()
}
