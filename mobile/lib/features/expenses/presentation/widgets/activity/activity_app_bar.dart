import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/wallet.dart';
import '../../bloc/dashboard_state.dart';

class ActivityAppBar extends StatelessWidget implements PreferredSizeWidget {
  final DashboardState provider;
  final VoidCallback onPickDate;
  final ValueChanged<WalletEntity> onWalletSelected;

  const ActivityAppBar({
    super.key,
    required this.provider,
    required this.onPickDate,
    required this.onWalletSelected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  List<PopupMenuEntry<WalletEntity>> _buildWalletMenuItems() {
    return [
      if (provider.personalWallets.isNotEmpty) ...[
        const PopupMenuItem<WalletEntity>(
          enabled: false,
          height: 24,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'PERSONAL WALLETS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        ...provider.personalWallets.map(
          (wallet) => PopupMenuItem<WalletEntity>(
            value: wallet,
            child: Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  color: provider.activeWallet?.id == wallet.id
                      ? AppTheme.primary
                      : AppTheme.darkSlateVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    wallet.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: provider.activeWallet?.id == wallet.id
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                ),
                if (provider.activeWallet?.id == wallet.id)
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
      if (provider.sharedWallets.isNotEmpty) ...[
        if (provider.personalWallets.isNotEmpty) const PopupMenuDivider(),
        const PopupMenuItem<WalletEntity>(
          enabled: false,
          height: 24,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'GROUP WALLETS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        ...provider.sharedWallets.map(
          (wallet) => PopupMenuItem<WalletEntity>(
            value: wallet,
            child: Row(
              children: [
                Icon(
                  Icons.groups_outlined,
                  color: provider.activeWallet?.id == wallet.id
                      ? AppTheme.primary
                      : AppTheme.darkSlateVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    wallet.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: provider.activeWallet?.id == wallet.id
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                ),
                if (provider.activeWallet?.id == wallet.id)
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
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      backgroundColor: AppTheme.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: canPop
          ? IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.onBackground,
              ),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Aktivitas',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.onBackground,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          if (provider.activeWallet != null)
            PopupMenuButton<WalletEntity>(
              onSelected: onWalletSelected,
              offset: const Offset(0, 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              elevation: 4,
              shadowColor: Colors.black.withAlpha(25),
              itemBuilder: (context) => _buildWalletMenuItems(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    provider.isSharedMode
                        ? Icons.groups_outlined
                        : Icons.person_outline_rounded,
                    size: 13,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      provider.activeWallet!.name,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppTheme.primary,
                    size: 16,
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: onPickDate,
          icon: const Icon(
            Icons.calendar_month_rounded,
            color: AppTheme.primary,
          ),
          tooltip: 'Choose date',
        ),
      ],
    );
  }
}
