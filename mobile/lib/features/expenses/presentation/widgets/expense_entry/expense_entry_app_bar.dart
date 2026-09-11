import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/wallet.dart';
import '../../screens/ai_chat_screen.dart';

class ExpenseEntryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final WalletEntity? activeWallet;
  final List<WalletEntity> personalWallets;
  final List<WalletEntity> sharedWallets;
  final bool isSharedMode;
  final ValueChanged<WalletEntity> onWalletSelected;

  const ExpenseEntryAppBar({
    super.key,
    required this.activeWallet,
    required this.personalWallets,
    required this.sharedWallets,
    required this.isSharedMode,
    required this.onWalletSelected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final allWallets = [...personalWallets, ...sharedWallets];

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.darkSlateVariant),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Catat Pengeluaran',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: AppTheme.darkSlate,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        // AI Chat shortcut button
        Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withAlpha(25),
                    AppTheme.secondary.withAlpha(15),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primary.withAlpha(40),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
            ),
            tooltip: 'Catat Cepat via Chat AI',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AiChatScreen()),
              );
            },
          ),
        ),
        if (allWallets.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: PopupMenuButton<WalletEntity>(
                onSelected: onWalletSelected,
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.1),
                itemBuilder: (context) {
                  return [
                    if (personalWallets.isNotEmpty) ...[
                      const PopupMenuItem<WalletEntity>(
                        enabled: false,
                        height: 24,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'DOMPET PRIBADI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      ...personalWallets.map(
                        (wallet) => PopupMenuItem<WalletEntity>(
                          value: wallet,
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                color: activeWallet?.id == wallet.id
                                    ? AppTheme.primary
                                    : AppTheme.darkSlateVariant,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  wallet.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: activeWallet?.id == wallet.id
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                              ),
                              if (activeWallet?.id == wallet.id)
                                const Icon(
                                  Icons.check_rounded,
                                  color: AppTheme.primary,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (sharedWallets.isNotEmpty) ...[
                      const PopupMenuDivider(),
                      const PopupMenuItem<WalletEntity>(
                        enabled: false,
                        height: 24,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'DOMPET BERSAMA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      ...sharedWallets.map(
                        (wallet) => PopupMenuItem<WalletEntity>(
                          value: wallet,
                          child: Row(
                            children: [
                              Icon(
                                Icons.groups_outlined,
                                color: activeWallet?.id == wallet.id
                                    ? AppTheme.primary
                                    : AppTheme.darkSlateVariant,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  wallet.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: activeWallet?.id == wallet.id
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                              ),
                              if (activeWallet?.id == wallet.id)
                                const Icon(
                                  Icons.check_rounded,
                                  color: AppTheme.primary,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ];
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSharedMode
                            ? Icons.groups_rounded
                            : Icons.person_rounded,
                        color: AppTheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          activeWallet?.name ?? 'Pilih Dompet',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.primary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
