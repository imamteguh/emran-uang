import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../domain/entities/wallet.dart';
import '../../bloc/dashboard_state.dart';

class BillsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final DashboardState dashboardState;
  final ResponsiveHelper responsive;
  final ValueChanged<WalletEntity> onWalletSelected;

  const BillsAppBar({
    super.key,
    required this.dashboardState,
    required this.responsive,
    required this.onWalletSelected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(51),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              dashboardState.activeWallet == null
                  ? Icons.account_balance_wallet_rounded
                  : (dashboardState.isSharedMode
                      ? Icons.groups_rounded
                      : Icons.person_rounded),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          if (dashboardState.allWallets.isEmpty)
            Text(
              'Emran Uang',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: responsive.scaleFont(18),
              ),
            )
          else
            PopupMenuButton<WalletEntity>(
              onSelected: onWalletSelected,
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              itemBuilder: (context) {
                return [
                  if (dashboardState.personalWallets.isNotEmpty) ...[
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
                    ...dashboardState.personalWallets.map(
                      (wallet) => PopupMenuItem<WalletEntity>(
                        value: wallet,
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              color: dashboardState.activeWallet?.id == wallet.id
                                  ? AppTheme.primary
                                  : AppTheme.darkSlateVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                wallet.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight:
                                      dashboardState.activeWallet?.id == wallet.id
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color: AppTheme.darkSlate,
                                ),
                              ),
                            ),
                            if (dashboardState.activeWallet?.id == wallet.id)
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
                  if (dashboardState.sharedWallets.isNotEmpty) ...[
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
                    ...dashboardState.sharedWallets.map(
                      (wallet) => PopupMenuItem<WalletEntity>(
                        value: wallet,
                        child: Row(
                          children: [
                            Icon(
                              Icons.groups_outlined,
                              color: dashboardState.activeWallet?.id == wallet.id
                                  ? AppTheme.primary
                                  : AppTheme.darkSlateVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                wallet.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight:
                                      dashboardState.activeWallet?.id == wallet.id
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color: AppTheme.darkSlate,
                                ),
                              ),
                            ),
                            if (dashboardState.activeWallet?.id == wallet.id)
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: responsive.scale(150),
                    ),
                    child: Text(
                      dashboardState.activeWallet?.name ?? 'Pilih Dompet',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: responsive.scaleFont(17),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  ),
                ],
              ),
            ),
        ],
      ),
    );

  }
}
