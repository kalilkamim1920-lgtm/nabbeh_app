import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/task_model.dart';

/// عنصر عرض مهمة/موعد — يُستخدم في الشاشة الرئيسية وشاشة المهام
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    this.onDelete,
    this.onCalendar,
  });

  final TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onCalendar;

  @override
  Widget build(BuildContext context) {
    final kindLabel = task.isAppointment ? 'موعد' : 'استحقاق';
    final timeText = task.dueDate != null
        ? '${formatDay(task.dueDate!)} — الساعة ${formatTime(task.dueDate)}'
        : 'بدون وقت محدد';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: AppTheme.cardDecoration,
      child: ListTile(
        leading: Checkbox(
          value: task.isDone,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            color: task.isDone ? Colors.black38 : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  task.isAppointment ? Icons.event : Icons.flag_outlined,
                  size: 13,
                  color: Colors.black38,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '$kindLabel: $timeText',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (task.notes.isNotEmpty)
              Text(
                task.notes,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onCalendar != null)
              IconButton(
                icon: Icon(
                  task.calendarEventId != null ? Icons.event_available : Icons.calendar_month,
                  size: 20,
                  color: task.calendarEventId != null ? Colors.green : Colors.black45,
                ),
                tooltip: task.calendarEventId != null
                    ? 'مضاف للتقويم'
                    : 'أضف إلى التقويم',
                onPressed: onCalendar,
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
