import '../../data/models/misc_models.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/rule_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/transaction_model.dart';

/// عقد المستودع — طبقة النطاق (Domain)
/// كل عمليات التخزين والاستعلام تمر عبر هذا العقد فقط
abstract class NabbehRepository {
  // ===== لوحة اليوم =====
  Future<DashboardData> getDashboard();

  // ===== الإشعارات المصنفة =====
  Future<List<NotificationItem>> getNotifications({
    String? category,
    int limit = 300,
    int offset = 0,
  });

  /// تأكيد الإشعار وتحويله لمهمة/موعد/مصروف
  Future<void> confirmNotification(
    int id, {
    String? title,
    double? amount,
    int? dueDate,
    String? merchant,
    int? spentAt,
  });

  Future<void> dismissNotification(int id);

  // ===== المهام والمواعيد =====
  Future<List<TaskItem>> getTasks({required bool isAppointment});

  Future<int> addTask({
    required String title,
    String notes = '',
    int? dueDate,
    required bool isAppointment,
    String? location,
  });

  Future<void> toggleTask(int id, {required bool done});

  Future<void> deleteTask(int id);

  /// إضافة الموعد إلى تقويم الجهاز، تُرجع معرف الحدث أو -1 عند الفشل
  Future<int> addTaskToCalendar(int taskId);

  // ===== المصاريف =====
  Future<List<TransactionItem>> getTransactions({int? from, int? to});

  Future<int> addTransaction({
    required double amount,
    required String merchant,
    required String description,
    required int spentAt,
    String category = 'عام',
  });

  Future<void> deleteTransaction(int id);

  // ===== القواعد =====
  Future<List<RuleItem>> getRules();

  Future<int> addRule({
    required String appFilter,
    required String keyword,
    required String actionType,
  });

  Future<void> toggleRule(int id, {required bool enabled});

  Future<void> deleteRule(int id);

  // ===== الإعدادات والخصوصية =====
  Future<List<AppSettingItem>> getAppSettings();

  Future<void> setAppEnabled(String packageName, {required bool enabled});

  Future<GlobalSettings> getGlobalSettings();

  Future<void> setGlobalSetting(String key, Object value);

  Future<bool> isNotificationAccessGranted();

  Future<bool> isCalendarAccessGranted();

  Future<void> openNotificationAccessSettings();

  Future<bool> requestCalendarPermissions();

  /// زر "احذف كل بياناتي" — مسح فوري لكل ما خزنه التطبيق
  Future<void> deleteAllData();

  // ===== أحداث مباشرة من طبقة النظام =====
  Stream<Map<String, dynamic>> get eventStream;
}
