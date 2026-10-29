import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/enums.dart';
import '../providers/settings_provider.dart';

/// ورقة إنشاء/تعديل قاعدة
/// القاعدة: إذا جاء إشعار من التطبيق X وعم الكلمة Y نفّذ الإجراء Z
Future<void> showRuleSheet(BuildContext context, {String? prefillApp}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RuleSheet(prefillApp: prefillApp),
  );
}

class _RuleSheet extends StatefulWidget {
  const _RuleSheet({this.prefillApp});

  final String? prefillApp;

  @override
  State<_RuleSheet> createState() => _RuleSheetState();
}

class _RuleSheetState extends State<_RuleSheet> {
  late String _app;
  final TextEditingController _keyword = TextEditingController();
  RuleAction _action = RuleAction.createTask;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _app = widget.prefillApp ?? '*';
  }

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await context.read<SettingsProvider>().addRule(
            appFilter: _app,
            keyword: _keyword.text.trim(),
            actionType: _action.apiValue,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة القاعدة')),
        );
      }
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
    final settings = context.watch<SettingsProvider>();
    final knownApps = <String, String>{'*': 'كل التطبيقات'};
    for (final a in settings.apps) {
      knownApps[a.packageName] = '${a.appName} (${a.packageName})';
    }
    if (!knownApps.containsKey(_app)) {
      knownApps[_app] = _app; // تطبيق مُمرَّر غير موجود بعد في القائمة
    }

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
          const Text(
            'قاعدة جديدة',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'إذا جاء إشعار مطابق، نفّذ الإجراء تلقائياً بدون سؤال',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _app,
            decoration: const InputDecoration(labelText: 'التطبيق'),
            items: knownApps.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _app = v ?? '*'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyword,
            decoration: const InputDecoration(
              labelText: 'الكلمة المفتاحية',
              hintText: 'مثال: تم خصم — اتركها فارغة لمطابقة كل الإشعارات',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<RuleAction>(
            value: _action,
            decoration: const InputDecoration(labelText: 'الإجراء'),
            items: RuleAction.values
                .map((a) => DropdownMenuItem(value: a, child: Text(a.label)))
                .toList(),
            onChanged: (v) => setState(() => _action = v ?? RuleAction.createTask),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            icon: saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.add, size: 20),
            label: const Text('حفظ القاعدة'),
            onPressed: saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
