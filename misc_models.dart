import 'enums.dart';
import 'notification_model.dart';
import 'task_model.dart';
import 'transaction_model.dart';

/// إعدادات مراقبة تطبيق معيّن (الخصوصية: تفعيل/تعطيل لكل تطبيق)
class AppSettingItem {
  final String packageName;
  final String appName;
  final bool enabled;

  const AppSettingItem({
    required this.packageName,
    required this.appName,
    required this.enabled,
  });

  factory AppSettingItem.fromJson(Map<String, dynamic> j) => AppSettingItem(
        packageName: j['packageName'] as String? ?? '',
        appName: j['appName'] as String? ?? '',
        enabled: j['enabled'] as bool? ?? true,
      );
}

/// الإعدادات العامة المخزنة مشفرة في Kotlin
class GlobalSettings {
  final bool masterEnabled; // المفتاح الرئيسي: تفعيل/إيقاف نبّه كلياً
  final bool autoApplyRules; // تنفيذ القواعد تلقائياً بدون سؤال
  final String currency;

  const GlobalSettings({
    required this.masterEnabled,
    required this.autoApplyRules,
    required this.currency,
  });

  factory GlobalSettings.fromJson(Map<String, dynamic> j) => GlobalSettings(
        masterEnabled: j['masterEnabled'] as bool? ?? true,
        autoApplyRules: j['autoApplyRules'] as bool? ?? false,
        currency: j['currency'] as String? ?? 'SAR',
      );
}

/// بيانات لوحة اليوم الجاهزة من الطبقة الأصلية
class DashboardData {
  final int date;
  final String currency;
  final double monthTotal; // إجمالي مصاريف الشهر الحالي
  final List<TaskItem> tasks; // مهام اليوم
  final List<TaskItem> appointments; // مواعيد اليوم
  final List<TransactionItem> transactions; // مصاريف اليوم
  final List<NotificationItem> pending; // إشعارات بانتظار التأكيد

  const DashboardData({
    required this.date,
    required this.currency,
    required this.monthTotal,
    required this.tasks,
    required this.appointments,
    required this.transactions,
    required this.pending,
  });

  double get todayExpenses =>
      transactions.fold(0.0, (sum, t) => sum + t.amount);

  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
        date: (j['date'] as num?)?.toInt() ?? 0,
        currency: j['currency'] as String? ?? 'SAR',
        monthTotal: (j['monthTotal'] as num?)?.toDouble() ?? 0,
        tasks: (j['tasks'] as List<dynamic>? ?? [])
            .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        appointments: (j['appointments'] as List<dynamic>? ?? [])
            .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        transactions: (j['transactions'] as List<dynamic>? ?? [])
            .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        pending: (j['pending'] as List<dynamic>? ?? [])
            .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
