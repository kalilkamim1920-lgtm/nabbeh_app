import 'enums.dart';

/// نموذج الإشعار المُلتقط والمصنَّف
/// يقابل NotificationEntity في طبقة Kotlin
class NotificationItem {
  final int id;
  final String packageName;
  final String appName;
  final String title;
  final String body;
  final int timestamp;
  final Category category;
  final double confidence;
  final int? dueDate; // الوقت المستخرج من النص (إن وُجد)
  final double? amount; // المبلغ المستخرج (إن وُجد)
  final String? merchant; // الجهة المستخرجة (إن وُجدت)
  final String actionTaken;
  final int createdAt;

  const NotificationItem({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.category,
    required this.confidence,
    this.dueDate,
    this.amount,
    this.merchant,
    required this.actionTaken,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        id: (j['id'] as num).toInt(),
        packageName: j['packageName'] as String? ?? '',
        appName: j['appName'] as String? ?? '',
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        timestamp: (j['timestamp'] as num?)?.toInt() ?? 0,
        category: categoryFromApi(j['category'] as String? ?? 'TAJAHUL'),
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0,
        dueDate: (j['dueDate'] as num?)?.toInt(),
        amount: (j['amount'] as num?)?.toDouble(),
        merchant: j['merchant'] as String?,
        actionTaken: j['actionTaken'] as String? ?? 'PENDING',
        createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'packageName': packageName,
        'appName': appName,
        'title': title,
        'body': body,
        'timestamp': timestamp,
        'category': category.apiValue,
        'confidence': confidence,
        'dueDate': dueDate,
        'amount': amount,
        'merchant': merchant,
        'actionTaken': actionTaken,
        'createdAt': createdAt,
      };

  /// هل الإشعار ما زال بانتظار قرار المستخدم؟
  bool get isPending => actionTaken == 'PENDING';

  /// هل تم تحويله فعلاً إلى عنصر (مهمة/موعد/مصروف)؟
  bool get isConfirmed =>
      actionTaken == 'CONFIRMED_TASK' ||
      actionTaken == 'CONFIRMED_EVENT' ||
      actionTaken == 'CONFIRMED_TRANSACTION' ||
      actionTaken == 'AUTO_RULE';

  /// وصف حالة الإجراء بصيغة عربية
  String get statusLabel => switch (actionTaken) {
        'PENDING' => 'بانتظار تأكيدك',
        'CONFIRMED_TASK' => 'أُضيفت مهمة',
        'CONFIRMED_EVENT' => 'أُضيف موعد',
        'CONFIRMED_TRANSACTION' => 'سُجّل مصروف',
        'AUTO_RULE' => 'نُفِّذت بقاعدة تلقائية',
        'DISMISSED' => 'متجاهل',
        _ => actionTaken,
      };
}
