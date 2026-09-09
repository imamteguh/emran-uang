import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../auth/presentation/bloc/auth_user.dart';
import '../../../../auth/presentation/screens/update_profile_screen.dart';
import '../user_avatar.dart';

class ProfileHeroCard extends StatelessWidget {
  final ResponsiveHelper responsive;
  final AuthUser? user;

  const ProfileHeroCard({
    super.key,
    required this.responsive,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName ?? 'User';
    final email = user?.email ?? '';
    final avatarUrl = user?.avatarUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.roundedBorder,
        boxShadow: AppTheme.softShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withAlpha(20),
              ),
            ),
          ),
          Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    UserAvatar(
                      avatarUrl: avatarUrl,
                      displayName: name,
                      size: 96,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UpdateProfileScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: responsive.scaleFont(22),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: AppTheme.darkSlateVariant,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          color: AppTheme.secondary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Verified',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.tertiaryFixed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          color: AppTheme.tertiary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Premium Plan',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
