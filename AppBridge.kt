package com.nabbeh.app.bridge

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import com.nabbeh.app.db.ActionType
import com.nabbeh.app.db.Actions
import com.nabbeh.app.db.AppDatabase
import com.nabbeh.app.db.AppSettingEntity
import com.nabbeh.app.db.NotificationEntity
import com.nabbeh.app.db.RuleEntity
import com.nabbeh.app.db.TaskEntity
import com.nabbeh.app.db.TaskStatus
import com.nabbeh.app.db.TransactionEntity
import com.nabbeh.app.logic.CalendarHelper
import com.nabbeh.app.security.CryptoHelper
import com.nabbeh.app.util.EventBus
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/** حامل مرجع النشاط الحالي لطلبات الصلاحيات */
object ActivityHolder {
    var activity: Activity? = null
}

/**
 * الجسر الرئيسي بين Flutter وKotlin
 * كل الطلبات تصل كنص JSON وتُرد كنص JSON — بينما تُخزن البيانات مشفرة في SQLCipher
 */
class AppBridge(
    private val context: Context,
    messenger: BinaryMessenger
) : EventChannel.StreamHandler {

    private val mainScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var eventJob: kotlinx.coroutines.Job? = null
    private var permissionDeferred: CompletableDeferred<Boolean>? = null

    init {
        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            mainScope.launch { handleMethod(call, result) }
        }
        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(this)
    }

    // ===== بث الأحداث إلى Flutter =====
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventJob = mainScope.launch {
            EventBus.events.collect { json ->
                try {
                    events?.success(json)
                } catch (_: Exception) {
                }
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        eventJob?.cancel()
        eventJob = null
    }

    fun dispose() {
        mainScope.cancel()
    }

    /** تُستدعى من MainActivity بعد رد النظام على طلب الصلاحيات */
    fun onPermissionResult(granted: Boolean) {
        permissionDeferred?.complete(granted)
        permissionDeferred = null
    }

    // ===== الموزع الرئيسي =====
    private suspend fun handleMethod(call: MethodCall, result: MethodChannel.Result) {
        try {
            val db = AppDatabase.getInstance(context)
            val crypto = CryptoHelper.getInstance(context)
            val args: JSONObject? = (call.arguments as? String)?.let { JSONObject(it) }

            val reply: String = when (call.method) {
                "getDashboard" -> getDashboard(db, crypto)
                "getNotifications" -> getNotifications(db, args)
                "confirmNotification" -> confirmNotification(db, crypto, args)
                "dismissNotification" -> {
                    db.notificationDao().updateAction(args!!.getLong("id"), Actions.DISMISSED)
                    ok()
                }
                "getTasks" -> getTasks(db, args?.getBoolean("isAppointment") ?: false)
                "addTask" -> addTask(db, args)
                "toggleTask" -> {
                    val done = args!!.getBoolean("done")
                    db.taskDao().updateStatus(
                        args.getLong("id"),
                        if (done) TaskStatus.DONE else TaskStatus.PENDING,
                        System.currentTimeMillis()
                    )
                    ok()
                }
                "deleteTask" -> {
                    db.taskDao().delete(args!!.getLong("id"))
                    ok()
                }
                "addTaskToCalendar" -> addTaskToCalendar(db, args)
                "getTransactions" -> getTransactions(db, args)
                "addTransaction" -> addTransaction(db, crypto, args)
                "deleteTransaction" -> {
                    db.transactionDao().delete(args!!.getLong("id"))
                    ok()
                }
                "getRules" -> rulesToJson(db.ruleDao().getAll())
                "addRule" -> addRule(db, args)
                "toggleRule" -> {
                    db.ruleDao().setEnabled(args!!.getLong("id"), args.getBoolean("enabled"))
                    ok()
                }
                "deleteRule" -> {
                    db.ruleDao().delete(args!!.getLong("id"))
                    ok()
                }
                "getAppSettings" -> appSettingsToJson(db.appSettingDao().getAll())
                "setAppEnabled" -> {
                    db.appSettingDao().setEnabled(
                        args!!.getString("packageName"),
                        args.getBoolean("enabled")
                    )
                    ok()
                }
                "getGlobalSettings" -> globalToJson(crypto)
                "setGlobalSetting" -> setGlobalSetting(crypto, args)
                "isNotificationAccessGranted" ->
                    JSONObject().put("granted", isNotificationAccessGranted()).toString()
                "isCalendarAccessGranted" ->
                    JSONObject().put("granted", CalendarHelper.hasCalendarPermission(context)).toString()
                "openNotificationAccessSettings" -> {
                    openNotificationAccessSettings()
                    ok()
                }
                "requestCalendarPermissions" ->
                    JSONObject().put("granted", requestCalendarPermissions()).toString()
                "deleteAllData" -> deleteAllData(db, crypto)
                else -> throw IllegalArgumentException("طريقة غير معروفة: ${call.method}")
            }
            result.success(reply)
        } catch (e: Exception) {
            result.error("NABBEH_ERROR", e.message ?: "خطأ غير معروف", null)
        }
    }

    // ===== لوحة اليوم =====
    private suspend fun getDashboard(db: AppDatabase, crypto: CryptoHelper): String {
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
        }
        val dayStart = cal.timeInMillis
        val dayEnd = dayStart + 86_400_000L - 1
        cal.set(Calendar.DAY_OF_MONTH, 1)
        val monthStart = cal.timeInMillis

        val tasks = db.taskDao().getBetween(dayStart, dayEnd, false)
        val appointments = db.taskDao().getBetween(dayStart, dayEnd, true)
        val transactions = db.transactionDao().getBetween(dayStart, dayEnd)
        val pending = db.notificationDao().getPending()
        val monthTotal = db.transactionDao().sumBetween(monthStart, dayEnd)

        return JSONObject().apply {
            put("date", dayStart)
            put("currency", crypto.getCurrency())
            put("monthTotal", monthTotal)
            put("tasks", tasksToJson(tasks))
            put("appointments", tasksToJson(appointments))
            put("transactions", transactionsToJson(transactions))
            put("pending", notificationsToJson(pending))
        }.toString()
    }

    // ===== الإشعارات =====
    private suspend fun getNotifications(db: AppDatabase, args: JSONObject?): String {
        val limit = args?.optInt("limit", 300) ?: 300
        val offset = args?.optInt("offset", 0) ?: 0
        val category = args?.optString("category", "") ?: ""
        val list = if (category.isBlank() || category == "ALL") {
            db.notificationDao().getRecent(limit, offset)
        } else {
            db.notificationDao().getByCategory(category, limit, offset)
        }
        return notificationsToJson(list)
    }

    private suspend fun confirmNotification(
        db: AppDatabase,
        crypto: CryptoHelper,
        args: JSONObject?
    ): String {
        val a = args ?: throw IllegalArgumentException("وسائط مفقودة")
        val id = a.getLong("id")
        val n = db.notificationDao().getById(id) ?: throw Exception("الإشعار غير موجود")
        val now = System.currentTimeMillis()
        val newTitle = a.optString("title", n.title).ifBlank { n.title }

        return when (n.category) {
            com.nabbeh.app.db.Categories.MOHTIME -> {
                val due = a.optLongOrNull("dueDate") ?: n.dueDate
                val taskId = db.taskDao().insert(
                    TaskEntity(
                        title = newTitle, notes = n.body, dueDate = due,
                        isAppointment = true, location = null, status = TaskStatus.PENDING,
                        sourceNotificationId = id, calendarEventId = null,
                        createdAt = now, updatedAt = now
                    )
                )
                var eventId = -1L
                if (due != null && CalendarHelper.hasCalendarPermission(context)) {
                    eventId = CalendarHelper.addEvent(context, newTitle, n.body, due)
                    if (eventId > 0) db.taskDao().setCalendarEvent(taskId, eventId)
                }
                db.notificationDao().updateAction(id, Actions.CONFIRMED_EVENT)
                JSONObject().put("ok", true).put("taskId", taskId).put("eventId", eventId).toString()
            }

            com.nabbeh.app.db.Categories.MAHMMA -> {
                val due = a.optLongOrNull("dueDate") ?: n.dueDate
                val taskId = db.taskDao().insert(
                    TaskEntity(
                        title = newTitle, notes = n.body, dueDate = due,
                        isAppointment = false, location = null, status = TaskStatus.PENDING,
                        sourceNotificationId = id, calendarEventId = null,
                        createdAt = now, updatedAt = now
                    )
                )
                db.notificationDao().updateAction(id, Actions.CONFIRMED_TASK)
                JSONObject().put("ok", true).put("taskId", taskId).put("eventId", -1).toString()
            }

            com.nabbeh.app.db.Categories.MASROOF -> {
                val amount = a.optDoubleOrNull("amount") ?: n.amount ?: 0.0
                val spentAt = a.optLongOrNull("spentAt") ?: n.timestamp
                val merchant = a.optString("merchant", n.merchant ?: "")
                val txId = db.transactionDao().insert(
                    TransactionEntity(
                        amount = amount, currency = crypto.getCurrency(),
                        merchant = merchant, description = newTitle,
                        category = "عام", spentAt = spentAt,
                        sourceNotificationId = id, createdAt = now
                    )
                )
                db.notificationDao().updateAction(id, Actions.CONFIRMED_TRANSACTION)
                JSONObject().put("ok", true).put("transactionId", txId).toString()
            }

            else -> throw Exception("لا يمكن تأكيد إشعار متجاهل")
        }
    }

    // ===== المهام =====
    private suspend fun getTasks(db: AppDatabase, isAppointment: Boolean): String =
        tasksToJson(db.taskDao().getAll(isAppointment))

    private suspend fun addTask(db: AppDatabase, args: JSONObject?): String {
        val a = args ?: throw IllegalArgumentException("وسائط مفقودة")
        val id = db.taskDao().insert(
            TaskEntity(
                title = a.getString("title"),
                notes = a.optString("notes", ""),
                dueDate = a.optLongOrNull("dueDate"),
                isAppointment = a.getBoolean("isAppointment"),
                location = a.optStringOrNull("location"),
                status = TaskStatus.PENDING,
                sourceNotificationId = null,
                calendarEventId = null,
                createdAt = System.currentTimeMillis(),
                updatedAt = System.currentTimeMillis()
            )
        )
        return JSONObject().put("ok", true).put("id", id).toString()
    }

    private suspend fun addTaskToCalendar(db: AppDatabase, args: JSONObject?): String {
        val a = args ?: throw IllegalArgumentException("وسائط مفقودة")
        val task = db.taskDao().getById(a.getLong("id"))
            ?: throw Exception("العنصر غير موجود")
        if (task.calendarEventId != null && task.calendarEventId > 0) {
            return JSONObject().put("ok", true).put("eventId", task.calendarEventId).toString()
        }
        val due = task.dueDate ?: throw Exception("لا يوجد وقت محدد لهذا العنصر")
        if (!CalendarHelper.hasCalendarPermission(context)) {
            throw Exception("صلاحية التقويم غير ممنوحة — امنحها من الإعدادات")
        }
        val eventId = CalendarHelper.addEvent(context, task.title, task.notes, due)
        if (eventId > 0) db.taskDao().setCalendarEvent(task.id, eventId)
        return JSONObject().put("ok", true).put("eventId", eventId).toString()
    }

    // ===== المصاريف =====
    private suspend fun getTransactions(db: AppDatabase, args: JSONObject?): String {
        val from = args?.optLong("from", 0L) ?: 0L
        val to = args?.optLong("to", 0L) ?: 0L
        val list = if (from > 0 && to > from) {
            db.transactionDao().getBetween(from, to)
        } else {
            db.transactionDao().getAll()
        }
        return transactionsToJson(list)
    }

    private suspend fun addTransaction(
        db: AppDatabase,
        crypto: CryptoHelper,
        args: JSONObject?
    ): String {
        val a = args ?: throw IllegalArgumentException("وسائط مفقودة")
        val id = db.transactionDao().insert(
            TransactionEntity(
                amount = a.getDouble("amount"),
                currency = crypto.getCurrency(),
                merchant = a.optString("merchant", ""),
                description = a.optString("description", ""),
                category = a.optString("category", "عام"),
                spentAt = a.optLong("spentAt", System.currentTimeMillis()),
                sourceNotificationId = a.optLongOrNull("sourceNotificationId"),
                createdAt = System.currentTimeMillis()
            )
        )
        return JSONObject().put("ok", true).put("id", id).toString()
    }

    // ===== القواعد =====
    private suspend fun addRule(db: AppDatabase, args: JSONObject?): String {
        val a = args ?: throw IllegalArgumentException("وسائط مفقودة")
        val actionType = a.getString("actionType")
        if (actionType !in ActionType.ALL) {
            throw IllegalArgumentException("نوع إجراء غير صالح: $actionType")
        }
        val id = db.ruleDao().insert(
            RuleEntity(
                appFilter = a.getString("appFilter"),
                keyword = a.optString("keyword", ""),
                actionType = actionType,
                enabled = true,
                createdAt = System.currentTimeMillis()
            )
        )
        return JSONObject().put("ok", true).put("id", id).toString()
    }

    // ===== الإعدادات العامة =====
    private fun globalToJson(crypto: CryptoHelper): String = JSONObject().apply {
        put("masterEnabled", crypto.isMasterEnabled())
        put("autoApplyRules", crypto.isAutoApplyRules())
        put("currency", crypto.getCurrency())
    }.toString()

    private fun setGlobalSetting(crypto: CryptoHelper, args: JSONObject?): String {
        val a = args ?: throw IllegalArgumentException("وسائط مفقودة")
        when (a.getString("key")) {
            "masterEnabled" -> crypto.setMasterEnabled(a.getBoolean("value"))
            "autoApplyRules" -> crypto.setAutoApplyRules(a.getBoolean("value"))
            "currency" -> crypto.setCurrency(a.getString("value"))
            else -> throw IllegalArgumentException("إعداد غير معروف")
        }
        return ok()
    }

    // ===== الصلاحيات =====
    private fun isNotificationAccessGranted(): Boolean {
        val listeners = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners"
        ) ?: return false
        return listeners.contains(context.packageName)
    }

    private fun openNotificationAccessSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    private suspend fun requestCalendarPermissions(): Boolean {
        if (CalendarHelper.hasCalendarPermission(context)) return true
        val activity = ActivityHolder.activity ?: return false
        val deferred = CompletableDeferred<Boolean>()
        permissionDeferred = deferred
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.READ_CALENDAR, Manifest.permission.WRITE_CALENDAR),
            REQUEST_CALENDAR
        )
        return withTimeoutOrNull(60_000) { deferred.await() } ?: false
    }

    // ===== منطقة الخطر =====
    private suspend fun deleteAllData(db: AppDatabase, crypto: CryptoHelper): String {
        db.notificationDao().deleteAll()
        db.taskDao().deleteAll()
        db.transactionDao().deleteAll()
        db.ruleDao().deleteAll()
        db.appSettingDao().deleteAll()
        crypto.deleteAll()
        EventBus.send(JSONObject().put("type", "deleted").toString())
        return ok()
    }

    // ===== أدوات التسلسل JSON =====
    private fun notificationToJson(n: NotificationEntity) = JSONObject().apply {
        put("id", n.id)
        put("packageName", n.packageName)
        put("appName", n.appName)
        put("title", n.title)
        put("body", n.body)
        put("timestamp", n.timestamp)
        put("category", n.category)
        put("confidence", n.confidence.toDouble())
        putNullable("dueDate", n.dueDate)
        putNullable("amount", n.amount)
        putNullable("merchant", n.merchant)
        put("actionTaken", n.actionTaken)
        put("createdAt", n.createdAt)
    }

    private fun notificationsToJson(list: List<NotificationEntity>): String =
        JSONArray().apply { list.forEach { put(notificationToJson(it)) } }.toString()

    private fun taskToJson(t: TaskEntity) = JSONObject().apply {
        put("id", t.id)
        put("title", t.title)
        put("notes", t.notes)
        putNullable("dueDate", t.dueDate)
        put("isAppointment", t.isAppointment)
        putNullable("location", t.location)
        put("status", t.status)
        putNullable("sourceNotificationId", t.sourceNotificationId)
        putNullable("calendarEventId", t.calendarEventId)
        put("createdAt", t.createdAt)
        put("updatedAt", t.updatedAt)
    }

    private fun tasksToJson(list: List<TaskEntity>): String =
        JSONArray().apply { list.forEach { put(taskToJson(it)) } }.toString()

    private fun transactionToJson(t: TransactionEntity) = JSONObject().apply {
        put("id", t.id)
        put("amount", t.amount)
        put("currency", t.currency)
        put("merchant", t.merchant)
        put("description", t.description)
        put("category", t.category)
        put("spentAt", t.spentAt)
        putNullable("sourceNotificationId", t.sourceNotificationId)
        put("createdAt", t.createdAt)
    }

    private fun transactionsToJson(list: List<TransactionEntity>): String =
        JSONArray().apply { list.forEach { put(transactionToJson(it)) } }.toString()

    private fun ruleToJson(r: RuleEntity) = JSONObject().apply {
        put("id", r.id)
        put("appFilter", r.appFilter)
        put("keyword", r.keyword)
        put("actionType", r.actionType)
        put("enabled", r.enabled)
        put("createdAt", r.createdAt)
    }

    private fun rulesToJson(list: List<RuleEntity>): String =
        JSONArray().apply { list.forEach { put(ruleToJson(it)) } }.toString()

    private fun appSettingToJson(a: AppSettingEntity) = JSONObject().apply {
        put("packageName", a.packageName)
        put("appName", a.appName)
        put("enabled", a.enabled)
    }

    private fun appSettingsToJson(list: List<AppSettingEntity>): String =
        JSONArray().apply { list.forEach { put(appSettingToJson(it)) } }.toString()

    private fun ok(): String = JSONObject().put("ok", true).toString()

    companion object {
        const val METHOD_CHANNEL = "nabbeh/methods"
        const val EVENT_CHANNEL = "nabbeh/events"
        private const val REQUEST_CALENDAR = 4242
    }
}

// ===== امتدادات JSONObject الآمنة =====

fun JSONObject.optLongOrNull(name: String): Long? =
    if (has(name) && !isNull(name)) getLong(name) else null

fun JSONObject.optDoubleOrNull(name: String): Double? =
    if (has(name) && !isNull(name)) getDouble(name) else null

fun JSONObject.optStringOrNull(name: String): String? =
    if (has(name) && !isNull(name)) getString(name) else null

fun JSONObject.putNullable(name: String, value: Long?) {
    if (value == null) put(name, JSONObject.NULL) else put(name, value)
}

fun JSONObject.putNullable(name: String, value: Double?) {
    if (value == null) put(name, JSONObject.NULL) else put(name, value)
}

fun JSONObject.putNullable(name: String, value: String?) {
    if (value == null) put(name, JSONObject.NULL) else put(name, value)
}
