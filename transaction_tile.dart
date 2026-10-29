import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/transaction_model.dart';

/// عنصر عرض معاملة مالية
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, this.onDelete});

  final TransactionItem transaction;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFD97706).withOpacity(0.12),
          child: const Icon(Icons.payments_outlined, color: Color(0xFFD97706)),
        ),
        title: Text(
          t.merchant.isNotEmpty ? t.merchant : 'مصروف',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (t.description.isNotEmpty)
              Text(
                t.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            Text(
              formatTime(t.spentAt),
              style: const TextStyle(fontSize: 11, color: Colors.black38),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '-${formatAmount(t.amount, t.currency)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD97706),
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.black38),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
