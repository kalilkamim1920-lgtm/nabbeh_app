import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/task_model.dart';
import '../../domain/repositories/nabbeh_repository.dart';

/// يدير المهام والمواعيد (قائمتان منفصلتان)
class TasksProvider extends ChangeNotifier {
  TasksProvider(this._repo);
  final NabbehRepository _repo;

  StreamSubscription<Map<String, dynamic>>? _sub;
  List<TaskItem> tasks = [];
  List<TaskItem> appointments = [];
  bool loading = true;
  String? error;

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
      final results = await Future.wait([
        _repo.getTasks(isAppointment: false),
        _repo.getTasks(isAppointment: true),
      ]);
      tasks = results[0];
      appointments = results[1];
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> toggle(TaskItem t) async {
    await _repo.toggleTask(t.id, done: !t.isDone);
    await refresh();
  }

  Future<void> remove(int id) async {
    await _repo.deleteTask(id);
    await refresh();
  }

  Future<void> add({
    required String title,
    String notes = '',
    int? dueDate,
    required bool isAppointment,
  }) async {
    await _repo.addTask(
      title: title,
      notes: notes,
      dueDate: dueDate,
      isAppointment: isAppointment,
    );
    await refresh();
  }

  /// إضافة الموعد لتقويم الجهاز — تُرجع معرف الحدث أو -1 عند الفشل
  Future<int> addToCalendar(TaskItem t) async {
    final eventId = await _repo.addTaskToCalendar(t.id);
    await refresh();
    return eventId;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
