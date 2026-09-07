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
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Uncategorized',
      icon: json['icon']?.toString() ?? 'category',
      color: json['color']?.toString() ?? '#4F46E5',
      isDefault: json['isDefault'] as bool? ?? (json['userId'] == null),
      userId: json['userId']?.toString(),
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

    DateTime parsedDate;
    try {
      parsedDate = json['date'] != null
          ? DateTime.parse(json['date'].toString()).toLocal()
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    String creator = 'Me';
    if (json['user'] is Map && json['user']['displayName'] != null) {
      creator = json['user']['displayName'].toString();
    }

    return ExpenseEntity(
      id: json['id']?.toString() ?? '',
      amount: parsedAmount,
      description: json['description']?.toString(),
      date: parsedDate,
      type: json['type'] == 'ROUTINE' ? ExpenseType.routine : ExpenseType.nonRoutine,
      userId: json['userId']?.toString() ?? '',
      walletId: json['walletId']?.toString() ?? '',
      category: json['category'] is Map
          ? ExpenseCategory.fromJson(json['category'] as Map)
          : ExpenseCategory(id: '', name: 'Uncategorized', icon: 'category', color: '#4F46E5'),
      creatorName: creator,
    );
  }
}
