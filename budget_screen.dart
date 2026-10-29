import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/budget_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/transaction_tile.dart';

/// شاشة الميزانية — مصاريف الشهر الحالي مجمعة حسب اليوم
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BudgetProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('الميزانية')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('مصروف يدوي'),
        onPressed: () => _showAddExpenseSheet(context),
      ),
      body: prov.loading && prov.transactions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ===== ملخص الشهر =====
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0E7C66), Color(0xFF14957C)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مصاريف هذا الشهر',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatAmount(prov.monthTotal, prov.currency),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${prov.transactions.length} عملية مسجلة — كلها محفوظة مشفرة على جهازك',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ===== القائمة مجمعة حسب اليوم =====
                if (prov.transactions.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message:
                        'لا مصاريف هذا الشهر\nعند وصول إشعار خصم أو فاتورة سيسجله نبّه هنا تلقائياً',
                  )
                else
                  ...prov.groupedByDay.expand((group) => [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Text(
                            group.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        ...group.value.map(
                          (t) => TransactionTile(
                            transaction: t,
                            onDelete: () => prov.remove(t.id),
                          ),
                        ),
                      ]),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  void _showAddExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddExpenseSheet(),
    );
  }
}

/// ورقة إضافة مصروف يدوياً
class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet();

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _amount = TextEditingController();
  final _merchant = TextEditingController();
  final _description = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0 || saving) return;
    setState(() => saving = true);
    try {
      await context.read<BudgetProvider>().add(
            amount: amount,
            merchant: _merchant.text.trim(),
            description: _description.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e')));
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'إضافة مصروف يدوي',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'المبلغ'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _merchant,
            decoration: const InputDecoration(labelText: 'الجهة / المتجر'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'الوصف (اختياري)'),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            icon: saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.add),
            label: const Text('حفظ المصروف'),
            onPressed: saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
