import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../domain/entities/wallet.dart';
import '../../bloc/dashboard_state.dart';
import '../../bloc/notification_bloc.dart';
import '../../bloc/notification_state.dart';
import '../../screens/notifications_screen.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final DashboardState provider;
  final ResponsiveHelper responsive;
  final ValueChanged<WalletEntity> onWalletSelected;

  const DashboardAppBar({
    super.key,
    required this.provider,
    required this.responsive,
    required this.onWalletSelected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF0F172A), // Top dark background
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          // App Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset(
              'assets/icons/logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // App Name & Subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Emran Uang',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: responsive.scaleFont(16),
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'WalletShare',
                style: GoogleFonts.beVietnamPro(
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                  fontSize: responsive.scaleFont(10),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Wallet Selector Pill
        PopupMenuButton<WalletEntity>(
          onSelected: onWalletSelected,
          offset: const Offset(0, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          itemBuilder: (context) {
            return [
              if (provider.personalWallets.isNotEmpty) ...[
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
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
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
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            wallet.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: provider.activeWallet?.id == wallet.id
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: AppTheme.darkSlate,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (provider.activeWallet?.id == wallet.id)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (provider.sharedWallets.isNotEmpty) ...[
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
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
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
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            wallet.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: provider.activeWallet?.id == wallet.id
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: AppTheme.darkSlate,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (provider.activeWallet?.id == wallet.id)
                          const Icon(
                            Icons.check_circle_rounded,
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  provider.isSharedMode
                      ? Icons.groups_rounded
                      : Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF38BDF8),
                  size: 16,
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: responsive.scale(95),
                  ),
                  child: Text(
                    provider.activeWallet?.name ?? 'Dompet',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: responsive.scaleFont(12),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF94A3B8),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),

        // Notification Icon with Badge
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          icon: BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, notifState) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                  if (notifState.hasUnread)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notifState.unreadCount > 99
                              ? '99+'
                              : '${notifState.unreadCount}',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          splashRadius: 22,
          tooltip: 'Notifikasi',
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
