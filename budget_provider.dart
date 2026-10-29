import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../data/models/transaction_model.dart';
import '../../domain/repositories/nabbeh_repository.dart';

/// يدير المصاريف وإجماليات الشهر الحالي
class BudgetProvider extends ChangeNotifier {
  BudgetProvider(this._repo);
  final NabbehRepository _repo;

  StreamSubscription<Map<String, dynamic>>? _sub;
  List<TransactionItem> transactions = [];
  String currency = 'SAR';
  bool loading = true;
  String? error;

  double get monthTotal =>
      transactions.fold(0.0, (sum, t) => sum + t.amount);

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
      // نحمّل مصاريف الشهر الحالي فقط
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 1)
          .subtract(const Duration(milliseconds: 1));
      final results = await Future.wait([
        _repo.getTransactions(
          from: start.millisecondsSinceEpoch,
          to: end.millisecondsSinceEpoch,
        ),
        _repo.getGlobalSettings(),
      ]);
      transactions = results[0] as List<TransactionItem>;
      currency = (results[1] as dynamic).currency as String;
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// المصاريف مجمعة حسب اليوم (مرتبة من الأحدث للأقدم) لعرضها بقوائم مؤرخة
  List<MapEntry<String, List<TransactionItem>>> get groupedByDay {
    final map = <String, List<TransactionItem>>{};
    for (final t in transactions) {
      final d = DateTime.fromMillisecondsSinceEpoch(t.spentAt);
      final key =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(t);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return entries.map((e) {
      final d = DateTime.fromMillisecondsSinceEpoch(e.value.first.spentAt);
      return MapEntry(DateFormat('EEEE d MMMM', 'ar').format(d), e.value);
    }).toList();
  }

  Future<void> add({
    required double amount,
    required String merchant,
    required String description,
  }) async {
    await _repo.addTransaction(
      amount: amount,
      merchant: merchant,
      description: description,
      spentAt: DateTime.now().millisecondsSinceEpoch,
    );
    await refresh();
  }

  Future<void> remove(int id) async {
    await _repo.deleteTransaction(id);
    await refresh();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
