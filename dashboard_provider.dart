import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/misc_models.dart';
import '../../data/models/notification_model.dart';
import '../../domain/repositories/nabbeh_repository.dart';

/// يدير بيانات لوحة اليوم: مهام اليوم + مواعيده + مصاريفه + بانتظار التأكيد
class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._repo);
  final NabbehRepository _repo;

  StreamSubscription<Map<String, dynamic>>? _sub;
  bool loading = true;
  String? error;
  DashboardData? data;

  void init() {
    // ننصت لأحداث النظام: إشعار جديد أو حذف شامل يستدعي تحديثاً فورياً
    _sub = _repo.eventStream.listen((event) {
      final type = event['type'];
      if (type == 'new_notification' || type == 'deleted') refresh();
    });
    refresh();
  }

  Future<void> refresh() async {
    try {
      data = await _repo.getDashboard();
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// تأكيد سريع بضغطة واحدة بقيم المصنّف المستخرجة
  Future<void> quickConfirm(NotificationItem n) => confirm(n.id);

  /// تأكيد مع تعديلات اختيارية من المستخدم
  Future<void> confirm(
    int id, {
    String? title,
    double? amount,
    int? dueDate,
    String? merchant,
    int? spentAt,
  }) async {
    await _repo.confirmNotification(
      id,
      title: title,
      amount: amount,
      dueDate: dueDate,
      merchant: merchant,
      spentAt: spentAt,
    );
    await refresh();
  }

  Future<void> dismiss(int id) async {
    await _repo.dismissNotification(id);
    await refresh();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
