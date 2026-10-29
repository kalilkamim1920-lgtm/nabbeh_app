import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/rule_model.dart';
import '../providers/settings_provider.dart';
import '../widgets/rule_sheet.dart';

/// شاشة الإعدادات: الصلاحيات + الخصوصية + التطبيقات المراقبة + القواعد + منطقة الخطر
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات والخصوصية')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== الصلاحيات =====
          _Section(
            title: 'الصلاحيات',
            children: [
              Row(
                children: [
                  Icon(
                    s.notificationAccess ? Icons.verified : Icons.warning_amber_rounded,
                    color: s.notificationAccess ? Colors.green : const Color(0xFFD97706),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.notificationAccess
                          ? 'صلاحية الوصول للإشعارات: مفعلة'
                          : 'صلاحية الوصول للإشعارات: غير مفعلة',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              if (!s.notificationAccess) ...[
                const SizedBox(height: 8),
                const Text(
                  'بدون هذه الصلاحية لا يستطيع نبّه قراءة الإشعارات. الصلاحية تعمل على الجهاز فقط.',
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('فتح إعدادات الوصول للإشعارات'),
                onPressed: () => context.read<SettingsProvider>().openNotificationAccess(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    s.calendarAccess ? Icons.verified : Icons.event_busy,
                    color: s.calendarAccess ? Colors.green : Colors.black26,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.calendarAccess
                          ? 'صلاحية التقويم: مفعلة (لإضافة المواعيد تلقائياً)'
                          : 'صلاحية التقويم: غير مفعلة (اختيارية)',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              if (!s.calendarAccess) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: const Text('منح صلاحية التقويم'),
                  onPressed: () =>
                      context.read<SettingsProvider>().requestCalendarPermissions(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // ===== الخصوصية العامة =====
          _Section(
            title: 'الخصوصية',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تفعيل نبّه'),
                subtitle: const Text('إيقافه يمنع قراءة أي إشعار جديد نهائياً'),
                value: s.global?.masterEnabled ?? true,
                onChanged: (v) => context.read<SettingsProvider>().setMasterEnabled(v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تنفيذ القواعد تلقائياً'),
                subtitle: const Text('القواعد التي تنشئها تعمل بدون سؤال — الإشعارات الأخرى تبقى بانتظار تأكيدك'),
                value: s.global?.autoApplyRules ?? false,
                onChanged: (v) => context.read<SettingsProvider>().setAutoApplyRules(v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('العملة'),
                trailing: DropdownButton<String>(
                  value: s.global?.currency ?? 'SAR',
                  items: kCurrencies.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text('${e.value} (${e.key})'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) context.read<SettingsProvider>().setCurrency(v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== التطبيقات المراقبة =====
          _Section(
            title: 'التطبيقات المراقبة (${s.apps.length})',
            children: [
              const Text(
                'فعّل أو عطّل التقاط الإشعارات من كل تطبيق على حدة. يظهر التطبيق هنا تلقائياً بعد أول إشعار منه.',
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
              const SizedBox(height: 8),
              if (s.apps.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('لم تُرصد أي تطبيقات بعد', style: TextStyle(fontSize: 12, color: Colors.black38)),
                )
              else
                ...s.apps.map((a) => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(a.appName, style: const TextStyle(fontSize: 14)),
                      subtitle: Text(a.packageName, style: const TextStyle(fontSize: 10)),
                      value: a.enabled,
                      onChanged: (v) =>
                          context.read<SettingsProvider>().setAppEnabled(a.packageName, v),
                    )),
            ],
          ),
          const SizedBox(height: 16),

          // ===== القواعد =====
          _Section(
            title: 'القواعد (${s.rules.length})',
            children: [
              const Text(
                'القاعدة = تطبيق معيّن + كلمة مفتاحية + إجراء تلقائي',
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
              const SizedBox(height: 8),
              if (s.rules.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('لا قواعد بعد', style: TextStyle(fontSize: 12, color: Colors.black38)),
                )
              else
                ...s.rules.map((r) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.rule, size: 20),
                      title: Text(
                        '${r.appFilter == '*' ? 'كل التطبيقات' : r.appFilter} + "${r.keyword.isEmpty ? 'أي نص' : r.keyword}"',
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        _actionLabel(r.actionType),
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: r.enabled,
                            onChanged: (v) =>
                                context.read<SettingsProvider>().toggleRule(r.id, v),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.black38),
                            onPressed: () =>
                                context.read<SettingsProvider>().deleteRule(r.id),
                          ),
                        ],
                      ),
                    )),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة قاعدة جديدة'),
                onPressed: () => showRuleSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== منطقة الخطر =====
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.delete_forever, color: Color(0xFFDC2626)),
                    SizedBox(width: 8),
                    Text(
                      'منطقة الخطر',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'حذف كل بياناتك فوراً: الإشعارات، المهام، المواعيد، المصاريف والقواعد. لا يمكن التراجع.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                  ),
                  child: const Text('احذف كل بياناتي'),
                  onPressed: () => _confirmDeleteAll(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'نبّه — كل بياناتك تبقى على جهازك مشفرة، ولا يغادر الهاتف أي شيء أبداً',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.black38),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _actionLabel(String actionType) => switch (actionType) {
        'CREATE_TASK' => 'الإجراء: إنشاء مهمة',
        'CREATE_EVENT' => 'الإجراء: موعد + تقويم',
        'CREATE_TRANSACTION' => 'الإجراء: تسجيل مصروف',
        'IGNORE' => 'الإجراء: تجاهل',
        _ => actionType,
      };

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف كل بياناتي؟'),
        content: const Text(
          'سيُمسح كل شيء فوراً ونهائياً من قاعدة البيانات المشفرة. هل أنت متأكد؟',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، احذف الكل'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<SettingsProvider>().deleteAllData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف كل بياناتك نهائياً')),
        );
      }
    }
  }
}

/// قسم عنوان + بطاقة محتوى
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}
