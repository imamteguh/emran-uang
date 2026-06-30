enum ExpenseType { routine, nonRoutine }

class ExpenseCategory {
  final String id;
  final String name;
  final String icon;
  final String color;
  final bool isDefault;
  final String? userId;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = true,
    this.userId,
  });

  factory ExpenseCategory.fromJson(Map<dynamic, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '💰',
      color: json['color'] as String? ?? '#4F46E5',
      isDefault: json['isDefault'] as bool? ?? (json['userId'] == null),
      userId: json['userId'] as String?,
    );
  }
}

class ExpenseEntity {
  final String id;
  final double amount;
  final String? description;
  final DateTime date;
  final ExpenseType type;
  final String userId;
  final String walletId;
  final ExpenseCategory category;
  final String creatorName;

  ExpenseEntity({
    required this.id,
    required this.amount,
    this.description,
    required this.date,
    required this.type,
    required this.userId,
    required this.walletId,
    required this.category,
    required this.creatorName,
  });

  factory ExpenseEntity.fromJson(Map<dynamic, dynamic> json) {
    double parsedAmount = 0.0;
    final rawAmount = json['amount'];
    if (rawAmount is num) {
      parsedAmount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      parsedAmount = double.tryParse(rawAmount) ?? 0.0;
    }

    return ExpenseEntity(
      id: json['id'] as String,
      amount: parsedAmount,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String).toLocal(),
      type: json['type'] == 'ROUTINE' ? ExpenseType.routine : ExpenseType.nonRoutine,
      userId: json['userId'] as String,
      walletId: json['walletId'] as String,
      category: ExpenseCategory.fromJson(json['category'] as Map),
      creatorName: json['user'] != null ? (json['user']['displayName'] as String) : 'Me',
    );
  }
}
