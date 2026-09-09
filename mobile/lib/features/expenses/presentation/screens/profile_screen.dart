import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/presentation/screens/change_password_screen.dart';
import '../../../auth/presentation/screens/update_profile_screen.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/profile/profile.dart';
import 'categories_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _monthlyReports = true;
  String _currentTheme = 'Light';
  String _appVersion = 'WalletShare v2.4.1 (Build 829)';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion =
              'WalletShare v${packageInfo.version} (Build ${packageInfo.buildNumber})';
        });
      }
    } catch (_) {
      // Fallback intact
    }
  }

  void _handleLogout() {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final authState = context.watch<AuthBloc>().state;
    final user = authState.currentUser;
    final dashboardBloc = context.watch<DashboardBloc>();
    final activeWallet = dashboardBloc.state.activeWallet;

    final double cardWidth = responsive.isTablet || responsive.isDesktop
        ? 480
        : double.infinity;

    return Scaffold(
      appBar: AppBar(
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
              child: const Icon(Icons.wallet, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'WalletShare',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: responsive.scaleFont(20),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsive.screenPadding,
          child: Center(
            child: SizedBox(
              width: cardWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileHeroCard(responsive: responsive, user: user),
                  const SizedBox(height: 24),

                  // Account Settings Group
                  const ProfileGroupTitle(title: 'Account Settings'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.softShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ProfileSettingsTile(
                          icon: Icons.person_outline,
                          title: 'Update Profile',
                          subtitle: 'Update your full name and email address',
                          iconColor: AppTheme.primary,
                          bgIconColor: AppTheme.primary.withAlpha(25),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UpdateProfileScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ProfileSettingsTile(
                          icon: Icons.lock_outline,
                          title: 'Change Password',
                          subtitle: 'Change your account security password',
                          iconColor: AppTheme.secondary,
                          bgIconColor: AppTheme.secondary.withAlpha(25),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ProfileSettingsTile(
                          icon: Icons.category_outlined,
                          title: 'Manage Categories',
                          subtitle: 'Create and edit custom categories',
                          iconColor: AppTheme.tertiary,
                          bgIconColor: AppTheme.tertiary.withAlpha(25),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CategoriesScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Preferences Settings Group
                  const ProfileGroupTitle(title: 'Preferences'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.softShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ProfileSettingsTile(
                          icon: Icons.notifications_active_outlined,
                          title: 'Notifications',
                          trailingText: _pushNotifications ? 'On' : 'Off',
                          iconColor: AppTheme.tertiary,
                          bgIconColor: AppTheme.tertiary.withAlpha(25),
                          onTap: () => NotificationPickerBottomSheet.show(
                            context,
                            push: _pushNotifications,
                            email: _emailNotifications,
                            monthly: _monthlyReports,
                            onChanged: (p, e, m) {
                              setState(() {
                                _pushNotifications = p;
                                _emailNotifications = e;
                                _monthlyReports = m;
                              });
                            },
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ProfileSettingsTile(
                          icon: Icons.currency_exchange,
                          title: 'Currency',
                          trailingText: activeWallet?.currency ?? 'IDR',
                          iconColor: AppTheme.primary,
                          bgIconColor: AppTheme.primary.withAlpha(25),
                          onTap: () => CurrencyPickerBottomSheet.show(
                            context,
                            context.read<DashboardBloc>(),
                            activeWallet?.currency ?? 'IDR',
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ProfileSettingsTile(
                          icon: Icons.dark_mode_outlined,
                          title: 'Theme',
                          trailingText: _currentTheme,
                          iconColor: AppTheme.darkSlateVariant,
                          bgIconColor: AppTheme.darkSlateVariant.withAlpha(25),
                          onTap: () => ThemePickerBottomSheet.show(
                            context,
                            _currentTheme,
                            (theme) => setState(() => _currentTheme = theme),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Support Settings Group
                  const ProfileGroupTitle(title: 'Support'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.softShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: const Column(
                      children: [
                        ProfileSettingsTile(
                          icon: Icons.help_outline,
                          title: 'Help Center',
                          iconColor: AppTheme.secondary,
                          bgIconColor: AppTheme.secondaryContainer,
                        ),
                        Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ProfileSettingsTile(
                          icon: Icons.policy_outlined,
                          title: 'Privacy Policy',
                          iconColor: AppTheme.tertiary,
                          bgIconColor: AppTheme.tertiaryFixed,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Logout Button
                  ElevatedButton(
                    onPressed: _handleLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorContainer,
                      foregroundColor: AppTheme.error,
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Logout',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Version Label
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Text(
                        _appVersion,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: AppTheme.outline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
