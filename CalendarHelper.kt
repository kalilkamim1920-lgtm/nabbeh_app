package com.nabbeh.app.logic

import android.Manifest
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.provider.CalendarContract
import androidx.core.content.ContextCompat
import java.util.TimeZone

/**
 * مساعد التقويم — يضيف المواعيد إلى تقويم جهاز المستخدم
 * يستخدم CalendarContract الرسمي، ولا يعمل إلا بعد منح صلاحيتي القراءة والكتابة
 */
object CalendarHelper {

    fun hasCalendarPermission(context: Context): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.WRITE_CALENDAR) ==
            PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CALENDAR) ==
            PackageManager.PERMISSION_GRANTED

    /** معرف تقويم المستخدم الأساسي أو أول تقويم متاح */
    private fun getPrimaryCalendarId(context: Context): Long? {
        if (!hasCalendarPermission(context)) return null
        return try {
            context.contentResolver.query(
                CalendarContract.Calendars.CONTENT_URI,
                arrayOf(
                    CalendarContract.Calendars._ID,
                    CalendarContract.Calendars.IS_PRIMARY
                ),
                null,
                null,
                null
            )?.use { cursor ->
                var primaryId: Long? = null
                var firstId: Long? = null
                while (cursor.moveToNext()) {
                    val id = cursor.getLong(0)
                    if (firstId == null) firstId = id
                    val isPrimary =
                        if (cursor.columnCount > 1) cursor.getInt(1) == 1 else false
                    if (isPrimary && primaryId == null) primaryId = id
                }
                primaryId ?: firstId
            }
        } catch (e: Exception) {
            null
        }
    }

    /**
     * إضافة حدث للتقويم
     * @return معرف الحدث الجديد أو -1 عند الفشل أو نقص الصلاحيات
     */
    fun addEvent(
        context: Context,
        title: String,
        description: String,
        beginMillis: Long,
        durationMinutes: Long = 60,
        location: String? = null
    ): Long {
        if (!hasCalendarPermission(context)) return -1
        val calendarId = getPrimaryCalendarId(context) ?: return -1
        return try {
            val values = ContentValues().apply {
                put(CalendarContract.Events.CALENDAR_ID, calendarId)
                put(CalendarContract.Events.TITLE, title)
                put(CalendarContract.Events.DESCRIPTION, description)
                put(CalendarContract.Events.DTSTART, beginMillis)
                put(CalendarContract.Events.DTEND, beginMillis + durationMinutes * 60_000L)
                put(CalendarContract.Events.EVENT_TIMEZONE, TimeZone.getDefault().id)
                location?.let { put(CalendarContract.Events.EVENT_LOCATION, it) }
            }
            val uri = context.contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)
            uri?.lastPathSegment?.toLongOrNull() ?: -1
        } catch (e: Exception) {
            -1
        }
    }
}
