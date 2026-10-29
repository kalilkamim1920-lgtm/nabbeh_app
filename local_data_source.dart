import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/misc_models.dart';
import '../models/notification_model.dart';
import '../models/rule_model.dart';
import '../models/task_model.dart';
import '../models/transaction_model.dart';

/// جسر الاتصال مع كود Kotlin الأصلي
/// كل البيانات تنتقل كنص JSON بينما تُخزن مشفرة داخل SQLCipher في الطرف الآخر
class LocalDataSource {
  static const MethodChannel _channel = MethodChannel('nabbeh/methods');
  static const EventChannel _events = EventChannel('nabbeh/events');

  Future<dynamic> _invoke(String method, [Map<String, dynamic>? args]) async {
    try {
      return await _channel.invokeMethod(
        method,
        args == null ? null : jsonEncode(args),
      );
    } on PlatformException catch (e) {
      throw Exception('خطأ من الطبقة الأصلية (${e.code}): ${e.message}');
    }
  }

  Map<String, dynamic> _decodeMap(dynamic raw) =>
      jsonDecode(raw as String) as Map<String, dynamic>;

  List<Map<String, dynamic>> _decodeList(dynamic raw) {
    final List list = jsonDecode(raw as String) as List;
    return list.cast<Map<String, dynamic>>();
  }

  // ===== لوحة اليوم =====
  Future<DashboardData> getDashboard() async =>
      DashboardData.fromJson(_decodeMap(await _invoke('getDashboard')));

  // ===== الإشعارات =====
  Future<List<NotificationItem>> getNotifications({
    String? category,
    int limit = 300,
    int offset = 0,
  }) async {
    final raw = await _invoke('getNotifications', {
      if (category != null) 'category': category,
      'limit': limit,
      'offset': offset,
    });
    return _decodeList(raw).map(NotificationItem.fromJson).toList();
  }

  Future<void> confirmNotification(
    int id, {
    String? title,
    double? amount,
    int? dueDate,
    String? merchant,
    int? spentAt,
  }) async {
    await _invoke('confirmNotification', {
      'id': id,
      if (title != null) 'title': title,
      if (amount != null) 'amount': amount,
      if (dueDate != null) 'dueDate': dueDate,
      if (merchant != null) 'merchant': merchant,
      if (spentAt != null) 'spentAt': spentAt,
    });
  }

  Future<void> dismissNotification(int id) async =>
      _invoke('dismissNotification', {'id': id});

  // ===== المهام =====
  Future<List<TaskItem>> getTasks({required bool isAppointment}) async {
    final raw = await _invoke('getTasks', {'isAppointment': isAppointment});
    return _decodeList(raw).map(TaskItem.fromJson).toList();
  }

  Future<int> addTask({
    required String title,
    String notes = '',
    int? dueDate,
    required bool isAppointment,
    String? location,
  }) async {
    final raw = await _invoke('addTask', {
      'title': title,
      'notes': notes,
      if (dueDate != null) 'dueDate': dueDate,
      'isAppointment': isAppointment,
      if (location != null) 'location': location,
    });
    return (_decodeMap(raw)['id'] as num).toInt();
  }

  Future<void> toggleTask(int id, {required bool done}) async =>
      _invoke('toggleTask', {'id': id, 'done': done});

  Future<void> deleteTask(int id) async => _invoke('deleteTask', {'id': id});

  Future<int> addTaskToCalendar(int taskId) async {
    final raw = await _invoke('addTaskToCalendar', {'id': taskId});
    return (_decodeMap(raw)['eventId'] as num).toInt();
  }

  // ===== المصاريف =====
  Future<List<TransactionItem>> getTransactions({int? from, int? to}) async {
    final raw = await _invoke(
      'getTransactions',
      {if (from != null) 'from': from, if (to != null) 'to': to},
    );
    return _decodeList(raw).map(TransactionItem.fromJson).toList();
  }

  Future<int> addTransaction({
    required double amount,
    required String merchant,
    required String description,
    required int spentAt,
    String category = 'عام',
  }) async {
    final raw = await _invoke('addTransaction', {
      'amount': amount,
      'merchant': merchant,
      'description': description,
      'spentAt': spentAt,
      'category': category,
    });
    return (_decodeMap(raw)['id'] as num).toInt();
  }

  Future<void> deleteTransaction(int id) async =>
      _invoke('deleteTransaction', {'id': id});

  // ===== القواعد =====
  Future<List<RuleItem>> getRules() async {
    final raw = await _invoke('getRules');
    return _decodeList(raw).map(RuleItem.fromJson).toList();
  }

  Future<int> addRule({
    required String appFilter,
    required String keyword,
    required String actionType,
  }) async {
    final raw = await _invoke('addRule', {
      'appFilter': appFilter,
      'keyword': keyword,
      'actionType': actionType,
    });
    return (_decodeMap(raw)['id'] as num).toInt();
  }

  Future<void> toggleRule(int id, {required bool enabled}) async =>
      _invoke('toggleRule', {'id': id, 'enabled': enabled});

  Future<void> deleteRule(int id) async => _invoke('deleteRule', {'id': id});

  // ===== الإعدادات والخصوصية =====
  Future<List<AppSettingItem>> getAppSettings() async {
    final raw = await _invoke('getAppSettings');
    return _decodeList(raw).map(AppSettingItem.fromJson).toList();
  }

  Future<void> setAppEnabled(String packageName, {required bool enabled}) async =>
      _invoke('setAppEnabled', {'packageName': packageName, 'enabled': enabled});

  Future<GlobalSettings> getGlobalSettings() async =>
      GlobalSettings.fromJson(_decodeMap(await _invoke('getGlobalSettings')));

  Future<void> setGlobalSetting(String key, Object value) async =>
      _invoke('setGlobalSetting', {'key': key, 'value': value});

  Future<bool> _getGranted(String method) async =>
      _decodeMap(await _invoke(method))['granted'] as bool;

  Future<bool> isNotificationAccessGranted() async =>
      _getGranted('isNotificationAccessGranted');

  Future<bool> isCalendarAccessGranted() async =>
      _getGranted('isCalendarAccessGranted');

  Future<void> openNotificationAccessSettings() async =>
      _invoke('openNotificationAccessSettings');

  Future<bool> requestCalendarPermissions() async =>
      _getGranted('requestCalendarPermissions');

  Future<void> deleteAllData() async => _invoke('deleteAllData');

  // ===== أحداث مباشرة من طبقة النظام =====
  Stream<Map<String, dynamic>> get eventStream =>
      _events.receiveBroadcastStream().map(
            (e) => jsonDecode(e as String) as Map<String, dynamic>,
          );
}
