import 'category_budget.dart';

enum WalletType { personal, shared }

class WalletEntity {
  final String id;
  final String name;
  final WalletType type;
  final String currency;
  final double? dailyBudget;
  final double? monthlyBudget;
  final List<dynamic>? groupMembers;
  final List<CategoryBudgetEntity> categoryBudgets;

  WalletEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    this.dailyBudget,
    this.monthlyBudget,
    this.groupMembers,
    this.categoryBudgets = const [],
  });

  factory WalletEntity.fromJson(Map<dynamic, dynamic> json) {
    double? parsedBudget;
    final rawBudget = json['dailyBudget'];
    if (rawBudget is num) {
      parsedBudget = rawBudget.toDouble();
    } else if (rawBudget is String) {
      parsedBudget = double.tryParse(rawBudget);
    }

    double? parsedMonthlyBudget;
    final rawMonthlyBudget = json['monthlyBudget'];
    if (rawMonthlyBudget is num) {
      parsedMonthlyBudget = rawMonthlyBudget.toDouble();
    } else if (rawMonthlyBudget is String) {
      parsedMonthlyBudget = double.tryParse(rawMonthlyBudget);
    }

    List<dynamic>? members;
    final groupData = json['group'];
    if (groupData is Map && groupData['members'] is List) {
      members = groupData['members'];
    }

    List<CategoryBudgetEntity> parsedCategoryBudgets = const [];
    final rawCategoryBudgets = json['categoryBudgets'];
    if (rawCategoryBudgets is List) {
      parsedCategoryBudgets = rawCategoryBudgets
          .whereType<Map>()
          .map((item) => CategoryBudgetEntity.fromJson(item))
          .toList();
    }

    return WalletEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] == 'SHARED' ? WalletType.shared : WalletType.personal,
      currency: json['currency'] as String? ?? 'IDR',
      dailyBudget: parsedBudget,
      monthlyBudget: parsedMonthlyBudget,
      groupMembers: members,
      categoryBudgets: parsedCategoryBudgets,
    );
  }
}
