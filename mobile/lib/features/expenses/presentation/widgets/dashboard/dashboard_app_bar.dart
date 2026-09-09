import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../domain/entities/wallet.dart';
import '../../bloc/dashboard_state.dart';
import '../../bloc/notification_bloc.dart';
import '../../bloc/notification_state.dart';
import '../../screens/ai_chat_screen.dart';
import '../../screens/notifications_screen.dart';
import '../../screens/shared_groups_screen.dart';

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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
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
              provider.activeWallet == null
                  ? Icons.account_balance_wallet
                  : (provider.isSharedMode
                        ? Icons.groups_rounded
                        : Icons.person_rounded),
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          if (provider.allWallets.isEmpty)
            Text(
              'WalletShare',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary,
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
                                  fontWeight:
                                      provider.activeWallet?.id == wallet.id
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
                    const PopupMenuDivider(),
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
                                  fontWeight:
                                      provider.activeWallet?.id == wallet.id
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
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: responsive.scale(150),
                    ),
                    child: Text(
                      provider.activeWallet?.name ?? 'Select Wallet',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: responsive.scaleFont(18),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AiChatScreen()),
            );
          },
          icon: const Icon(
            Icons.smart_toy_outlined,
            size: 24,
            color: AppTheme.primary,
          ),
          tooltip: 'AI Chat Transaction',
          splashRadius: 24,
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SharedGroupsScreen()),
            );
          },
          icon: const Icon(
            Icons.group_outlined,
            size: 28,
            color: AppTheme.primary,
          ),
          splashRadius: 24,
        ),
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
                    Icons.notifications_none_outlined,
                    size: 28,
                    color: AppTheme.primary,
                  ),
                  if (notifState.hasUnread)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          notifState.unreadCount > 99
                              ? '99+'
                              : '${notifState.unreadCount}',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 10,
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
          splashRadius: 24,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
