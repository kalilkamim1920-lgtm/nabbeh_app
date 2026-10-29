import '../../domain/repositories/nabbeh_repository.dart';
import '../datasource/local_data_source.dart';
import '../models/misc_models.dart';
import '../models/notification_model.dart';
import '../models/rule_model.dart';
import '../models/task_model.dart';
import '../models/transaction_model.dart';

/// تنفيذ المستودع — يفوّض كل العمليات إلى قناة الاتصال الأصلية
class NabbehRepositoryImpl implements NabbehRepository {
  NabbehRepositoryImpl(this._ds);
  final LocalDataSource _ds;

  @override
  Future<DashboardData> getDashboard() => _ds.getDashboard();

  @override
  Future<List<NotificationItem>> getNotifications({
    String? category,
    int limit = 300,
    int offset = 0,
  }) =>
      _ds.getNotifications(category: category, limit: limit, offset: offset);

  @override
  Future<void> confirmNotification(
    int id, {
    String? title,
    double? amount,
    int? dueDate,
    String? merchant,
    int? spentAt,
  }) =>
      _ds.confirmNotification(
        id,
        title: title,
        amount: amount,
        dueDate: dueDate,
        merchant: merchant,
        spentAt: spentAt,
      );

  @override
  Future<void> dismissNotification(int id) => _ds.dismissNotification(id);

  @override
  Future<List<TaskItem>> getTasks({required bool isAppointment}) =>
      _ds.getTasks(isAppointment: isAppointment);

  @override
  Future<int> addTask({
    required String title,
    String notes = '',
    int? dueDate,
    required bool isAppointment,
    String? location,
  }) =>
      _ds.addTask(
        title: title,
        notes: notes,
        dueDate: dueDate,
        isAppointment: isAppointment,
        location: location,
      );

  @override
  Future<void> toggleTask(int id, {required bool done}) =>
      _ds.toggleTask(id, done: done);

  @override
  Future<void> deleteTask(int id) => _ds.deleteTask(id);

  @override
  Future<int> addTaskToCalendar(int taskId) => _ds.addTaskToCalendar(taskId);

  @override
  Future<List<TransactionItem>> getTransactions({int? from, int? to}) =>
      _ds.getTransactions(from: from, to: to);

  @override
  Future<int> addTransaction({
    required double amount,
    required String merchant,
    required String description,
    required int spentAt,
    String category = 'عام',
  }) =>
      _ds.addTransaction(
        amount: amount,
        merchant: merchant,
        description: description,
        spentAt: spentAt,
        category: category,
      );

  @override
  Future<void> deleteTransaction(int id) => _ds.deleteTransaction(id);

  @override
  Future<List<RuleItem>> getRules() => _ds.getRules();

  @override
  Future<int> addRule({
    required String appFilter,
    required String keyword,
    required String actionType,
  }) =>
      _ds.addRule(appFilter: appFilter, keyword: keyword, actionType: actionType);

  @override
  Future<void> toggleRule(int id, {required bool enabled}) =>
      _ds.toggleRule(id, enabled: enabled);

  @override
  Future<void> deleteRule(int id) => _ds.deleteRule(id);

  @override
  Future<List<AppSettingItem>> getAppSettings() => _ds.getAppSettings();

  @override
  Future<void> setAppEnabled(String packageName, {required bool enabled}) =>
      _ds.setAppEnabled(packageName, enabled: enabled);

  @override
  Future<GlobalSettings> getGlobalSettings() => _ds.getGlobalSettings();

  @override
  Future<void> setGlobalSetting(String key, Object value) =>
      _ds.setGlobalSetting(key, value);

  @override
  Future<bool> isNotificationAccessGranted() =>
      _ds.isNotificationAccessGranted();

  @override
  Future<bool> isCalendarAccessGranted() => _ds.isCalendarAccessGranted();

  @override
  Future<void> openNotificationAccessSettings() =>
      _ds.openNotificationAccessSettings();

  @override
  Future<bool> requestCalendarPermissions() =>
      _ds.requestCalendarPermissions();

  @override
  Future<void> deleteAllData() => _ds.deleteAllData();

  @override
  Stream<Map<String, dynamic>> get eventStream => _ds.eventStream;
}
