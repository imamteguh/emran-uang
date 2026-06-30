enum WalletType { personal, shared }

class WalletEntity {
  final String id;
  final String name;
  final WalletType type;
  final String currency;
  final double? dailyBudget;
  final List<dynamic>? groupMembers;

  WalletEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    this.dailyBudget,
    this.groupMembers,
  });

  factory WalletEntity.fromJson(Map<dynamic, dynamic> json) {
    double? parsedBudget;
    final rawBudget = json['dailyBudget'];
    if (rawBudget is num) {
      parsedBudget = rawBudget.toDouble();
    } else if (rawBudget is String) {
      parsedBudget = double.tryParse(rawBudget);
    }

    List<dynamic>? members;
    final groupData = json['group'];
    if (groupData is Map && groupData['members'] is List) {
      members = groupData['members'];
    }

    return WalletEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] == 'SHARED' ? WalletType.shared : WalletType.personal,
      currency: json['currency'] as String? ?? 'IDR',
      dailyBudget: parsedBudget,
      groupMembers: members,
    );
  }
}
