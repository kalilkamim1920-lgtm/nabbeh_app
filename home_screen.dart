import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/misc_models.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/task_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/tasks_provider.dart';
import '../widgets/category_chip.dart';
import '../widgets/confirm_bottom_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_card.dart';
import '../widgets/task_tile.dart';
import '../widgets/transaction_tile.dart';

/// الشاشة الرئيسية — لوحة اليوم: ملخص + بانتظار التأكيد + مهام اليوم + مصاريف اليوم
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final settings = context.watch<SettingsProvider>();

    if (dash.loading && dash.data == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = dash.data;
    return Scaffold(
      appBar: AppBar(title: const Text('نبّه — لوحة اليوم')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== الترويسة =====
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greetingForNow(),
                      style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now()),
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== تنبيه صلاحية الإشعارات =====
          if (!settings.notificationAccess)
            _PermissionBanner(onOpen: () {
              context.read<SettingsProvider>().openNotificationAccess();
            }),
          if (!settings.notificationAccess) const SizedBox(height: 16),

          // ===== بطاقات الإحصاء =====
          if (data != null) ...[
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                StatCard(
                  icon: Icons.check_circle_outline,
                  label: 'مهام اليوم',
                  value: '${data.tasks.length}',
                  color: const Color(0xFF059669),
                ),
                StatCard(
                  icon: Icons.event,
                  label: 'مواعيد اليوم',
                  value: '${data.appointments.length}',
                  color: const Color(0xFF2563EB),
                ),
                StatCard(
                  icon: Icons.payments_outlined,
                  label: 'مصاريف اليوم',
                  value: data.todayExpenses == 0
                      ? 'لا شيء'
                      : data.todayExpenses.toStringAsFixed(0),
                  color: const Color(0xFFD97706),
                ),
                StatCard(
                  icon: Icons.pending_outlined,
                  label: 'بانتظار تأكيدك',
                  value: '${data.pending.length}',
                  color: const Color(0xFF7C3AED),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ===== بانتظار تأكيدك =====
            const Text(
              'بانتظار تأكيدك',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (data.pending.isEmpty)
              const EmptyState(
                icon: Icons.done_all,
                message: 'لا يوجد إشعارات تحتاج قرارك — كل شيء تحت السيطرة',
              )
            else
              ...data.pending.map((n) => _PendingCard(notification: n)),
            const SizedBox(height: 20),

            // ===== مهام ومواعيد اليوم =====
            const Text(
              'مهام ومواعيد اليوم',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (data.tasks.isEmpty && data.appointments.isEmpty)
              const EmptyState(
                icon: Icons.event_available,
                message: 'لا مهام ولا مواعيد اليوم',
              )
            else
              ..._sortedToday(data).map((t) => TaskTile(
                    task: t,
                    onToggle: () async {
                      await context.read<TasksProvider>().toggle(t);
                      if (context.mounted) {
                        await context.read<DashboardProvider>().refresh();
                      }
                    },
                  )),
            const SizedBox(height: 20),

            // ===== مصاريف اليوم =====
            const Text(
              'مصاريف اليوم',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (data.transactions.isEmpty)
              const EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                message: 'لا مصاريف مسجلة اليوم',
              )
            else
              ...data.transactions.map((t) => TransactionTile(transaction: t)),
          ],
        ],
      ),
    );
  }

  /// دمج المهام والمواعيد وترتيبها حسب الوقت (الفارغ في الآخر)
  List<TaskItem> _sortedToday(DashboardData data) {
    final all = [...data.appointments, ...data.tasks];
    all.sort((a, b) {
      final ad = a.dueDate ?? DateTime.now().millisecondsSinceEpoch * 2;
      final bd = b.dueDate ?? DateTime.now().millisecondsSinceEpoch * 2;
      return ad.compareTo(bd);
    });
    return all;
  }
}

/// لافتة تطلب منح صلاحية الوصول للإشعارات
class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notification_important, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'فعّل صلاحية الوصول للإشعارات لتبدأ نبّه بالعمل',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'الصلاحية تُستخدم فقط لقراءة إشعاراتك على جهازك — لا شيء يُرسل خارج الهاتف',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          FilledButton(onPressed: onOpen, child: const Text('فتح إعدادات الصلاحية')),
        ],
      ),
    );
  }
}

/// بطاقة إشعار بانتظار التأكيد
class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.notification});

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryChip(category: n.category),
              const Spacer(),
              Text(
                relativeTime(n.timestamp),
                style: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            n.title.isEmpty ? '(بدون عنوان)' : n.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
          const SizedBox(height: 4),
          Text(
            'من ${n.appName}',
            style: const TextStyle(fontSize: 11, color: Colors.black38),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.check, size: 18),
                label: const Text('تأكيد'),
                onPressed: () async {
                  await context.read<DashboardProvider>().quickConfirm(n);
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
                      context.read<DashboardProvider>().confirm(
                            n.id,
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
                onPressed: () => context.read<DashboardProvider>().dismiss(n.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
