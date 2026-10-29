/// نموذج المعاملة المالية (مصروف)
class TransactionItem {
  final int id;
  final double amount;
  final String currency;
  final String merchant;
  final String description;
  final String category;
  final int spentAt;
  final int? sourceNotificationId;
  final int createdAt;

  const TransactionItem({
    required this.id,
    required this.amount,
    required this.currency,
    required this.merchant,
    required this.description,
    required this.category,
    required this.spentAt,
    this.sourceNotificationId,
    required this.createdAt,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> j) => TransactionItem(
        id: (j['id'] as num).toInt(),
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        currency: j['currency'] as String? ?? 'SAR',
        merchant: j['merchant'] as String? ?? '',
        description: j['description'] as String? ?? '',
        category: j['category'] as String? ?? 'عام',
        spentAt: (j['spentAt'] as num?)?.toInt() ?? 0,
        sourceNotificationId: (j['sourceNotificationId'] as num?)?.toInt(),
        createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'currency': currency,
        'merchant': merchant,
        'description': description,
        'category': category,
        'spentAt': spentAt,
        'sourceNotificationId': sourceNotificationId,
        'createdAt': createdAt,
      };
}

/// نموذج قاعدة المستخدم في محرك القواعد
class RuleItem {
  final int id;
  final String appFilter; // اسم حزمة التطبيق أو "*" لكل التطبيقات
  final String keyword; // كلمة مفتاحية في العنوان أو النص
  final String actionType; // CREATE_TASK / CREATE_EVENT / CREATE_TRANSACTION / IGNORE
  final bool enabled;
  final int createdAt;

  const RuleItem({
    required this.id,
    required this.appFilter,
    required this.keyword,
    required this.actionType,
    required this.enabled,
    required this.createdAt,
  });

  factory RuleItem.fromJson(Map<String, dynamic> j) => RuleItem(
        id: (j['id'] as num).toInt(),
        appFilter: j['appFilter'] as String? ?? '*',
        keyword: j['keyword'] as String? ?? '',
        actionType: j['actionType'] as String? ?? 'IGNORE',
        enabled: j['enabled'] as bool? ?? true,
        createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'appFilter': appFilter,
        'keyword': keyword,
        'actionType': actionType,
        'enabled': enabled,
        'createdAt': createdAt,
      };
}
