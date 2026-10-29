import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/enums.dart';
import '../../data/models/notification_model.dart';
import '../../domain/repositories/nabbeh_repository.dart';

/// يدير قائمة الإشعارات المصنفة مع فلترة حسب التصنيف
class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider(this._repo);
  final NabbehRepository _repo;

  StreamSubscription<Map<String, dynamic>>? _sub;
  List<NotificationItem> _all = [];
  Category? filter;
  bool loading = true;
  String? error;

  /// القائمة بعد تطبيق الفلتر الحالي
  List<NotificationItem> get items =>
      filter == null ? _all : _all.where((n) => n.category == filter).toList();

  int get pendingCount => _all.where((n) => n.isPending).length;

  void init() {
    _sub = _repo.eventStream.listen((event) {
      if (event['type'] == 'new_notification' || event['type'] == 'deleted') {
        refresh();
      }
    });
    refresh();
  }

  Future<void> refresh() async {
    try {
      _all = await _repo.getNotifications(limit: 300);
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setFilter(Category? c) {
    filter = c;
    notifyListeners();
  }

  Future<void> confirm(
    NotificationItem n, {
    String? title,
    double? amount,
    int? dueDate,
    String? merchant,
  }) async {
    await _repo.confirmNotification(
      n.id,
      title: title,
      amount: amount,
      dueDate: dueDate,
      merchant: merchant,
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
