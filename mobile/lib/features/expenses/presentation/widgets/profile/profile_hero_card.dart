import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../auth/presentation/bloc/auth_user.dart';
import '../user_avatar.dart';

class ProfileHeroCard extends StatelessWidget {
  final ResponsiveHelper responsive;
  final AuthUser? user;
  final int totalCategories;
  final int totalWallets;
  final String activeWalletName;
  final String activeWalletCurrency;
  final VoidCallback onEditProfile;

  const ProfileHeroCard({
    super.key,
    required this.responsive,
    required this.user,
    this.totalCategories = 0,
    this.totalWallets = 1,
    this.activeWalletName = 'Dompet Utama',
    this.activeWalletCurrency = 'IDR',
    required this.onEditProfile,
  });

  String _formatJoinDate(DateTime? date) {
    if (date == null) return 'Pengguna Aktif';
    return 'Bergabung ${DateFormat('MMM yyyy').format(date)}';
  }

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName ?? 'Pengguna';
    final email = user?.email ?? '';
    final avatarUrl = user?.avatarUrl;
    final isGoogleUser = user?.authProvider == 'GOOGLE';
    final memberSince = _formatJoinDate(user?.createdAt);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Stack(
        children: [
          // Subtle top-right decorative gradient circle
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withAlpha(25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                // Avatar with Edit Button
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primary.withAlpha(40),
                            width: 2.5,
                          ),
                        ),
                        child: UserAvatar(
                          avatarUrl: avatarUrl,
                          displayName: name,
                          size: 92,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onEditProfile,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withAlpha(70),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // User Display Name
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: responsive.scaleFont(20),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkSlate,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),

                // User Email
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    color: AppTheme.darkSlateVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),

                // Status & Provider Badges
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Auth Provider Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isGoogleUser
                            ? const Color(0xFFEFF6FF)
                            : AppTheme.secondaryContainer.withAlpha(120),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isGoogleUser
                              ? const Color(0xFFBFDBFE)
                              : AppTheme.secondary.withAlpha(50),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGoogleUser
                                ? Icons.g_mobiledata_rounded
                                : Icons.verified_user_rounded,
                            color: isGoogleUser
                                ? const Color(0xFF1D4ED8)
                                : AppTheme.secondary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isGoogleUser ? 'Google OAuth' : 'Email Terverifikasi',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isGoogleUser
                                  ? const Color(0xFF1D4ED8)
                                  : AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Member since badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: Color(0xFF64748B),
                            size: 12,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            memberSince,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Quick Financial Summary Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFEDF2F7),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Active Wallet Stat
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Dompet Aktif',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                color: AppTheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeWalletName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 28,
                        width: 1,
                        color: const Color(0xFFE2E8F0),
                      ),

                      // Currency Stat
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Mata Uang',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                color: AppTheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeWalletCurrency,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.darkSlate,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 28,
                        width: 1,
                        color: const Color(0xFFE2E8F0),
                      ),

                      // Categories Count Stat
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Kategori',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                color: AppTheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$totalCategories Jenis',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
