import '../../domain/entities/wallet.dart';

class WalletModel extends WalletEntity {
  WalletModel({
    required super.id,
    required super.name,
    required super.type,
    required super.currency,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Wallet',
      type: (json['type'] as String).toLowerCase() == 'shared'
          ? WalletType.shared
          : WalletType.personal,
      currency: json['currency'] as String? ?? 'IDR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type == WalletType.shared ? 'SHARED' : 'PERSONAL',
      'currency': currency,
    };
  }
}
