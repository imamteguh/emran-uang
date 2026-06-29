import '../../domain/entities/expense.dart';

class ExpenseModel extends ExpenseEntity {
  ExpenseModel({
    required super.id,
    required super.amount,
    super.description,
    required super.date,
    required super.type,
    required super.userId,
    required super.walletId,
    required super.category,
    required super.creatorName,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    // Map category
    final categoryJson = json['category'] as Map<String, dynamic>? ?? {};
    final category = ExpenseCategory(
      id: categoryJson['id'] as String? ?? '',
      name: categoryJson['name'] as String? ?? 'Other',
      icon: categoryJson['icon'] as String? ?? '❓',
      color: categoryJson['color'] as String? ?? '#BDC3C7',
    );

    // Map user
    final userJson = json['user'] as Map<String, dynamic>? ?? {};
    final creatorName = userJson['displayName'] as String? ?? 'Someone';

    return ExpenseModel(
      id: json['id'] as String,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      description: json['description'] as String?,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      type: (json['type'] as String? ?? '').toLowerCase() == 'routine'
          ? ExpenseType.routine
          : ExpenseType.nonRoutine,
      userId: json['userId'] as String? ?? '',
      walletId: json['walletId'] as String? ?? '',
      category: category,
      creatorName: creatorName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'type': type == ExpenseType.routine ? 'ROUTINE' : 'NON_ROUTINE',
      'userId': userId,
      'walletId': walletId,
      'categoryId': category.id,
    };
  }
}
