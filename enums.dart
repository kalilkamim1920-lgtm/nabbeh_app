import 'package:flutter/material.dart';

/// التصنيفات الأربعة التي يعمل بها "نبّه"
enum Category { mohtime, masroof, mahmma, tajahul }

extension CategoryX on Category {
  String get label => switch (this) {
        Category.mohtime => 'موعد',
        Category.masroof => 'مصروف',
        Category.mahmma => 'مهمة',
        Category.tajahul => 'متجاهل',
      };

  /// القيمة المرسلة إلى/القادمة من طبقة Kotlin
  String get apiValue => name.toUpperCase();

  Color get color => switch (this) {
        Category.mohtime => const Color(0xFF2563EB), // أزرق للمواعيد
        Category.masroof => const Color(0xFFD97706), // برتقالي للمصاريف
        Category.mahmma => const Color(0xFF059669), // أخضر للمهام
        Category.tajahul => const Color(0xFF9CA3AF), // رمادي للمتجاهل
      };

  IconData get icon => switch (this) {
        Category.mohtime => Icons.event,
        Category.masroof => Icons.payments_outlined,
        Category.mahmma => Icons.check_circle_outline,
        Category.tajahul => Icons.do_not_disturb_on_outlined,
      };
}

Category categoryFromApi(String value) =>
    Category.values.firstWhere((c) => c.apiValue == value, orElse: () => Category.tajahul);

/// حالة المهمة
enum TaskStatus { pending, done }

extension TaskStatusX on TaskStatus {
  String get apiValue => name.toUpperCase();
  String get label => this == TaskStatus.pending ? 'قيد الانتظار' : 'منجزة';
}

TaskStatus taskStatusFromApi(String v) => v == 'DONE' ? TaskStatus.done : TaskStatus.pending;

/// أنواع الإجراءات في محرك القواعد
enum RuleAction { createTask, createEvent, createTransaction, ignore }

extension RuleActionX on RuleAction {
  String get apiValue => switch (this) {
        RuleAction.createTask => 'CREATE_TASK',
        RuleAction.createEvent => 'CREATE_EVENT',
        RuleAction.createTransaction => 'CREATE_TRANSACTION',
        RuleAction.ignore => 'IGNORE',
      };

  String get label => switch (this) {
        RuleAction.createTask => 'إنشاء مهمة',
        RuleAction.createEvent => 'إضافة موعد للتقويم',
        RuleAction.createTransaction => 'تسجيل مصروف',
        RuleAction.ignore => 'تجاهل الإشعار',
      };
}

RuleAction ruleActionFromApi(String v) =>
    RuleAction.values.firstWhere((r) => r.apiValue == v, orElse: () => RuleAction.ignore);
