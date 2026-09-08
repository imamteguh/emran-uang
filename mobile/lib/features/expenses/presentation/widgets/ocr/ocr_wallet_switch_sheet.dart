import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/wallet.dart';

/// Modal bottom sheet allowing the user to select the target wallet for OCR scan.
class OcrWalletSwitchSheet extends StatelessWidget {
  final WalletEntity? activeWallet;
  final List<WalletEntity> personalWallets;
  final List<WalletEntity> sharedWallets;
  final ValueChanged<WalletEntity> onWalletSelected;

  const OcrWalletSwitchSheet({
    super.key,
    required this.activeWallet,
    required this.personalWallets,
    required this.sharedWallets,
    required this.onWalletSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required WalletEntity? activeWallet,
    required List<WalletEntity> personalWallets,
    required List<WalletEntity> sharedWallets,
    required ValueChanged<WalletEntity> onWalletSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OcrWalletSwitchSheet(
        activeWallet: activeWallet,
        personalWallets: personalWallets,
        sharedWallets: sharedWallets,
        onWalletSelected: (wallet) {
          Navigator.pop(ctx);
          onWalletSelected(wallet);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppTheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Select Target Wallet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  if (personalWallets.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                      child: Text(
                        'PERSONAL WALLETS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ...personalWallets.map((w) {
                      final isSelected = activeWallet?.id == w.id;
                      return _buildWalletListTile(w, isSelected);
                    }),
                  ],
                  if (sharedWallets.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                      child: Text(
                        'GROUP WALLETS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ...sharedWallets.map((w) {
                      final isSelected = activeWallet?.id == w.id;
                      return _buildWalletListTile(w, isSelected);
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletListTile(WalletEntity wallet, bool isSelected) {
    final isGroup = wallet.type == WalletType.shared;
    return InkWell(
      onTap: () => onWalletSelected(wallet),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isGroup ? AppTheme.secondary : AppTheme.primary).withAlpha(15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (isGroup ? AppTheme.secondary : AppTheme.primary)
                : const Color(0xFFF1F5F9),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isGroup ? Icons.groups_rounded : Icons.person_rounded,
              color: isSelected
                  ? (isGroup ? AppTheme.secondary : AppTheme.primary)
                  : AppTheme.darkSlateVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  Text(
                    '${wallet.currency} • ${isGroup ? "Group Shared" : "Personal"}',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      color: AppTheme.darkSlateVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: isGroup ? AppTheme.secondary : AppTheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
