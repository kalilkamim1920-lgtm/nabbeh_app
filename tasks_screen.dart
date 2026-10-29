import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_utils.dart';
import '../../data/models/task_model.dart';
import '../providers/tasks_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_tile.dart';

/// شاشة المهام والمواعيد بتبويبين
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المهام والمواعيد'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'المهام'),
              Tab(text: 'المواعيد'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text('إضافة يدوية'),
          onPressed: () => _showAddSheet(context),
        ),
        body: const TabBarView(
          children: [
            _TaskList(isAppointment: false),
            _TaskList(isAppointment: true),
          ],
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final controller = DefaultTabController.of(context);
    final isAppointment = controller?.index == 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddTaskSheet(isAppointment: isAppointment),
    );
  }
}

/// قائمة المهام أو المواعيد
class _TaskList extends StatelessWidget {
  const _TaskList({required this.isAppointment});

  final bool isAppointment;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TasksProvider>();
    final list = isAppointment ? prov.appointments : prov.tasks;

    if (prov.loading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (list.isEmpty) {
      return EmptyState(
        icon: isAppointment ? Icons.event_busy : Icons.task_outlined,
        message: isAppointment
            ? 'لا مواعيد بعد — عند وصول إشعار موعد سيظهر هنا تلقائياً'
            : 'لا مهام بعد — عند وصول إشعار مهمة سيظهر هنا تلقائياً',
      );
    }
    return RefreshIndicator(
      onRefresh: prov.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final t = list[i];
          return TaskTile(
            task: t,
            onToggle: () => prov.toggle(t),
            onDelete: () async {
              final ok = await _confirmDelete(context);
              if (ok == true) await prov.remove(t.id);
            },
            onCalendar: isAppointment
                ? () async {
                    try {
                      final eventId = await prov.addToCalendar(t);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              eventId > 0
                                  ? 'أُضيف الحدث إلى تقويم جهازك'
                                  : 'تعذّرت الإضافة — تحقق من الوقت والصلاحيات',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e')),
                        );
                      }
                    }
                  }
                : null,
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف العنصر؟'),
        content: const Text('سيُحذف نهائياً من قاعدة البيانات المشفرة'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );
  }
}

/// ورقة إضافة مهمة/موعد يدوياً
class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet({required this.isAppointment});

  final bool isAppointment;

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  bool _hasTime = false;
  DateTime _dateTime = DateTime.now().add(const Duration(hours: 1));
  bool saving = false;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || saving) return;
    setState(() => saving = true);
    try {
      await context.read<TasksProvider>().add(
            title: _title.text.trim(),
            notes: _notes.text.trim(),
            dueDate: _hasTime ? _dateTime.millisecondsSinceEpoch : null,
            isAppointment: widget.isAppointment,
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
          Text(
            widget.isAppointment ? 'إضافة موعد جديد' : 'إضافة مهمة جديدة',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _title,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'العنوان'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(widget.isAppointment ? 'تحديد وقت الموعد' : 'تحديد وقت الاستحقاق'),
            value: _hasTime,
            onChanged: (v) => setState(() => _hasTime = v),
          ),
          if (_hasTime)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    child: Text(DateFormat('d/M/yyyy').format(_dateTime)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dateTime,
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (picked != null) {
                        setState(() {
                          _dateTime = DateTime(picked.year, picked.month, picked.day,
                              _dateTime.hour, _dateTime.minute);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    child: Text(formatTime(_dateTime.millisecondsSinceEpoch)),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_dateTime),
                      );
                      if (picked != null) {
                        setState(() {
                          _dateTime = DateTime(_dateTime.year, _dateTime.month,
                              _dateTime.day, picked.hour, picked.minute);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          const SizedBox(height: 18),
          FilledButton.icon(
            icon: saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.add),
            label: const Text('حفظ'),
            onPressed: saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
