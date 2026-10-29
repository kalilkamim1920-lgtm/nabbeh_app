import 'enums.dart';

/// نموذج المهمة / الموعد (الموعد مهمة بتاريخ وقت وتضاف للتقويم)
class TaskItem {
  final int id;
  final String title;
  final String notes;
  final int? dueDate; // وقت الاستحقاق / الموعد
  final bool isAppointment; // true = موعد، false = مهمة
  final String? location;
  final TaskStatus status;
  final int? sourceNotificationId;
  final int? calendarEventId; // معرف الحدث في تقويم الجهاز بعد الإضافة
  final int createdAt;
  final int updatedAt;

  const TaskItem({
    required this.id,
    required this.title,
    required this.notes,
    this.dueDate,
    required this.isAppointment,
    this.location,
    required this.status,
    this.sourceNotificationId,
    this.calendarEventId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDone => status == TaskStatus.done;

  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
        id: (j['id'] as num).toInt(),
        title: j['title'] as String? ?? '',
        notes: j['notes'] as String? ?? '',
        dueDate: (j['dueDate'] as num?)?.toInt(),
        isAppointment: j['isAppointment'] as bool? ?? false,
        location: j['location'] as String?,
        status: taskStatusFromApi(j['status'] as String? ?? 'PENDING'),
        sourceNotificationId: (j['sourceNotificationId'] as num?)?.toInt(),
        calendarEventId: (j['calendarEventId'] as num?)?.toInt(),
        createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
        updatedAt: (j['updatedAt'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'dueDate': dueDate,
        'isAppointment': isAppointment,
        'location': location,
        'status': status.apiValue,
        'sourceNotificationId': sourceNotificationId,
        'calendarEventId': calendarEventId,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
