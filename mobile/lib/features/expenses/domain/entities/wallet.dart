enum WalletType { personal, shared }

class WalletEntity {
  final String id;
  final String name;
  final WalletType type;
  final String currency;
  final double? dailyBudget;

  WalletEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    this.dailyBudget,
  });

  factory WalletEntity.fromJson(Map<dynamic, dynamic> json) {
    double? parsedBudget;
    final rawBudget = json['dailyBudget'];
    if (rawBudget is num) {
      parsedBudget = rawBudget.toDouble();
    } else if (rawBudget is String) {
      parsedBudget = double.tryParse(rawBudget);
    }

    return WalletEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] == 'SHARED' ? WalletType.shared : WalletType.personal,
      currency: json['currency'] as String? ?? 'IDR',
      dailyBudget: parsedBudget,
    );
  }
}
