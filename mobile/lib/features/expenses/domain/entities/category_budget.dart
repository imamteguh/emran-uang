import 'expense.dart';

class CategoryBudgetEntity {
  final String id;
  final String categoryId;
  final String walletId;
  final double amount;
  final ExpenseCategory? category;

  const CategoryBudgetEntity({
    required this.id,
    required this.categoryId,
    required this.walletId,
    required this.amount,
    this.category,
  });

  factory CategoryBudgetEntity.fromJson(Map<dynamic, dynamic> json) {
    double parsedAmount = 0.0;
    final rawAmount = json['amount'];
    if (rawAmount is num) {
      parsedAmount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      parsedAmount = double.tryParse(rawAmount) ?? 0.0;
    }

    ExpenseCategory? cat;
    if (json['category'] is Map) {
      cat = ExpenseCategory.fromJson(json['category'] as Map);
    }

    return CategoryBudgetEntity(
      id: json['id']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      walletId: json['walletId']?.toString() ?? '',
      amount: parsedAmount,
      category: cat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'walletId': walletId,
      'amount': amount,
    };
  }
}
