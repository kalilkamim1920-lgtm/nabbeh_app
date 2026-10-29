import 'package:flutter/material.dart';

import '../../core/utils/date_utils.dart';
import '../../data/models/enums.dart';
import '../../data/models/notification_model.dart';

/// ورقة التأكيد السفلي — تعرض اقتراح نبّه وتتيح تعديله قبل الحفظ بضغطة واحدة
Future<void> showConfirmSheet(
  BuildContext context,
  NotificationItem n,
  Future<void> Function({
    String? title,
    double? amount,
    int? dueDate,
    String? merchant,
  }) onConfirm,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ConfirmSheet(notification: n, onConfirm: onConfirm),
  );
}

class _ConfirmSheet extends StatefulWidget {
  const _ConfirmSheet({required this.notification, required this.onConfirm});

  final NotificationItem notification;
  final Future<void> Function({
    String? title,
    double? amount,
    int? dueDate,
    String? merchant,
  }) onConfirm;

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  late final TextEditingController _title;
  TextEditingController? _amount;
  TextEditingController? _merchant;
  late DateTime _dateTime;
  bool _hasDate = false;
  bool saving = false;

  bool get isMohtime => widget.notification.category == Category.mohtime;
  bool get isMasroof => widget.notification.category == Category.masroof;
  bool get isMahmma => widget.notification.category == Category.mahmma;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.notification.title);
    _dateTime = widget.notification.dueDate != null
        ? DateTime.fromMillisecondsSinceEpoch(widget.notification.dueDate!)
        : DateTime.now().add(const Duration(hours: 1));
    _hasDate = isMohtime || widget.notification.dueDate != null;
    if (isMasroof) {
      _amount = TextEditingController(
        text: widget.notification.amount?.toString() ?? '',
      );
      _merchant = TextEditingController(text: widget.notification.merchant ?? '');
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _amount?.dispose();
    _merchant?.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _dateTime = DateTime(
          picked.year, picked.month, picked.day,
          _dateTime.hour, _dateTime.minute,
        );
        _hasDate = true;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (picked != null) {
      setState(() {
        _dateTime = DateTime(
          _dateTime.year, _dateTime.month, _dateTime.day,
          picked.hour, picked.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await widget.onConfirm(
        title: _title.text.trim(),
        amount: isMasroof ? double.tryParse(_amount?.text.replaceAll(',', '.') ?? '') : null,
        merchant: isMasroof ? _merchant?.text.trim() : null,
        dueDate: isMohtime
            ? _dateTime.millisecondsSinceEpoch
            : (isMahmma && _hasDate ? _dateTime.millisecondsSinceEpoch : null),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الحفظ: $e')),
        );
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'اقتراح نبّه: ${n.category.label}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'من ${n.appName} — تحقق ثم أكد بضغطة واحدة',
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'العنوان'),
          ),
          if (isMasroof) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'المبلغ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _merchant,
                    decoration: const InputDecoration(labelText: 'الجهة / المتجر'),
                  ),
                ),
              ],
            ),
          ],
          if (isMohtime || isMahmma) ...[
            const SizedBox(height: 12),
            if (isMahmma)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('له تاريخ استحقاق'),
                value: _hasDate,
                onChanged: (v) => setState(() => _hasDate = v),
              ),
            if (_hasDate)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: Text(DateFormat('d/M/yyyy').format(_dateTime)),
                      onPressed: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.schedule, size: 18),
                      label: Text(formatTime(_dateTime.millisecondsSinceEpoch)),
                      onPressed: _pickTime,
                    ),
                  ),
                ],
              ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            icon: saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check, size: 20),
            label: const Text('تأكيد الإضافة'),
            onPressed: saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
