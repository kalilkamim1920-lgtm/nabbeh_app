import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/enums.dart';
import '../../data/models/notification_model.dart';
import '../providers/notifications_provider.dart';
import '../widgets/category_chip.dart';
import '../widgets/confirm_bottom_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/rule_sheet.dart';

/// شاشة الإشعارات المصنفة — كل الإشعارات مع فلترة وقرار لكل إشعار
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotificationsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات المصنفة')),
      body: Column(
        children: [
          // ===== شريط الفلاتر =====
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                _FilterChip(
                  label: 'الكل',
                  selected: prov.filter == null,
                  onSelected: () => prov.setFilter(null),
                ),
                const SizedBox(width: 8),
                ...Category.values.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FilterChip(
                        label: c.label,
                        color: c.color,
                        selected: prov.filter == c,
                        onSelected: () => prov.setFilter(c),
                      ),
                    )),
              ],
            ),
          ),

          // ===== القائمة =====
          Expanded(
            child: prov.loading && prov.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : prov.items.isEmpty
                    ? const EmptyState(
                        icon: Icons.inbox_outlined,
                        message:
                            'لا توجد إشعارات بعد\nثبّت التطبيق على جهازك وامنحه صلاحية الوصول ثم انتظر إشعاراً جديداً',
                      )
                    : RefreshIndicator(
                        onRefresh: prov.refresh,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: prov.items.length,
                          itemBuilder: (context, i) =>
                              _NotificationCard(notification: prov.items[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

/// فلتر تصنيف
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF0E7C66);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: c.withOpacity(0.18),
      labelStyle: TextStyle(
        color: selected ? c : Colors.black54,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: selected ? c : Colors.black12),
      showCheckmark: false,
    );
  }
}

/// بطاقة إشعار مصنف كاملة مع أزرار القرار
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final prov = context.read<NotificationsProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صف علوي: التصنيف + الوقت + قائمة الخيارات
          Row(
            children: [
              CategoryChip(category: n.category, compact: true),
              const SizedBox(width: 6),
              if (n.category != Category.tajahul)
                Text(
                  'ثقة ${(n.confidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 10, color: Colors.black38),
                ),
              const Spacer(),
              Text(
                relativeTime(n.timestamp),
                style: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.black38),
                onSelected: (v) {
                  if (v == 'rule') {
                    showRuleSheet(context, prefillApp: n.packageName);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'rule',
                    child: Text('إنشاء قاعدة من هذا التطبيق'),
                  ),
                ],
              ),
            ],
          ),

          // العنوان والنص
          Text(
            n.title.isEmpty ? '(بدون عنوان)' : n.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: n.category == Category.tajahul ? Colors.black45 : Colors.black87,
            ),
          ),
          if (n.body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                n.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            '${n.appName} • ${n.statusLabel}',
            style: TextStyle(
              fontSize: 11,
              color: n.isPending ? const Color(0xFF7C3AED) : Colors.black38,
              fontWeight: n.isPending ? FontWeight.bold : FontWeight.normal,
            ),
          ),

          // أزرار القرار للإشعارات المنتظرة فقط
          if (n.isPending && n.category != Category.tajahul) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('تأكيد'),
                  onPressed: () async {
                    await prov.confirm(n);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم: ${n.category.label} أُضيف بنجاح')),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  child: const Text('تعديل'),
                  onPressed: () => showConfirmSheet(
                    context,
                    n,
                    ({
                      String? title,
                      double? amount,
                      int? dueDate,
                      String? merchant,
                    }) =>
                        prov.confirm(
                          n,
                          title: title,
                          amount: amount,
                          dueDate: dueDate,
                          merchant: merchant,
                        ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  child: const Text('تجاهل'),
                  onPressed: () => prov.dismiss(n.id),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
