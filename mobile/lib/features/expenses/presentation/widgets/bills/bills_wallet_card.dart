import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../bloc/dashboard_bloc.dart';
import '../../bloc/dashboard_event.dart';
import '../../bloc/dashboard_state.dart';

class BillsWalletCard extends StatelessWidget {
  final DashboardState provider;
  final DashboardBloc bloc;

  const BillsWalletCard({
    super.key,
    required this.provider,
    required this.bloc,
  });

  void _showWalletPicker(BuildContext context) {
    final personalWallets = provider.personalWallets;
    final sharedWallets = provider.sharedWallets;
    final activeWallet = provider.activeWallet;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pilih Dompet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const SizedBox(height: 16),
                if (personalWallets.isNotEmpty) ...[
                  Text(
                    'DOMPET PRIBADI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...personalWallets.map((wallet) {
                    final isSelected = activeWallet?.id == wallet.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withAlpha(25)
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.darkSlate,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        wallet.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.darkSlate,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.primary,
                            )
                          : null,
                      onTap: () {
                        bloc.add(DashboardSelectWalletRequested(wallet));
                        Navigator.of(ctx).pop();
                      },
                    );
                  }),
                ],
                if (sharedWallets.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'DOMPET BERSAMA',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...sharedWallets.map((wallet) {
                    final isSelected = activeWallet?.id == wallet.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withAlpha(25)
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.groups_outlined,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.darkSlate,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        wallet.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.darkSlate,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.primary,
                            )
                          : null,
                      onTap: () {
                        bloc.add(DashboardSelectWalletRequested(wallet));
                        Navigator.of(ctx).pop();
                      },
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeWallet = provider.activeWallet;

    return InkWell(
      onTap: () => _showWalletPicker(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 54.0,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    provider.isSharedMode
                        ? Icons.groups_rounded
                        : Icons.account_balance_wallet_rounded,
                    color: const Color(0xFF60A5FA),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Nama Dompet',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeWallet?.name ?? 'Dompet Utama',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white70,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
