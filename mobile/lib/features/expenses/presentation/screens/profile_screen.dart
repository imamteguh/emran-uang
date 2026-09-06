import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_user.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/presentation/screens/change_password_screen.dart';
import '../../../auth/presentation/screens/update_profile_screen.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../widgets/user_avatar.dart';
import 'categories_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Notification states
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _monthlyReports = true;
  
  // Theme state
  String _currentTheme = 'Light';

  // Version state
  String _appVersion = 'WalletShare v2.4.1 (Build 829)';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = 'WalletShare v${packageInfo.version} (Build ${packageInfo.buildNumber})';
      });
    } catch (e) {
      // Keep default fallback
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
                  // Hero Profile Card
                  _buildHeroProfileCard(responsive, user),
                  const SizedBox(height: 24),


                  // Account Settings Group
                  _buildGroupTitle('Account Settings'),
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
                        _buildSettingsItem(
                          icon: Icons.person_outline,
                          title: 'Update Profile',
                          subtitle: 'Update your full name and email address',
                          iconColor: AppTheme.primary,
                          bgIconColor: AppTheme.primary.withAlpha(25),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UpdateProfileScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildSettingsItem(
                          icon: Icons.lock_outline,
                          title: 'Change Password',
                          subtitle: 'Change your account security password',
                          iconColor: AppTheme.secondary,
                          bgIconColor: AppTheme.secondary.withAlpha(25),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChangePasswordScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildSettingsItem(
                          icon: Icons.category_outlined,
                          title: 'Manage Categories',
                          subtitle: 'Create and edit custom categories',
                          iconColor: AppTheme.tertiary,
                          bgIconColor: AppTheme.tertiary.withAlpha(25),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CategoriesScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Preferences Settings Groups
                  _buildGroupTitle('Preferences'),
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
                        // Notification Settings Item
                        _buildSettingsItem(
                          icon: Icons.notifications_active_outlined,
                          title: 'Notifications',
                          trailingText: _pushNotifications ? 'On' : 'Off',
                          iconColor: AppTheme.tertiary,
                          bgIconColor: AppTheme.tertiary.withAlpha(25),
                          onTap: () => _showNotificationPicker(context),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        // Currency Selector Item
                        _buildSettingsItem(
                          icon: Icons.currency_exchange,
                          title: 'Currency',
                          trailingText:
                              context.watch<DashboardBloc>().state.activeWallet?.currency ??
                              'IDR',
                          iconColor: AppTheme.primary,
                          bgIconColor: AppTheme.primary.withAlpha(25),
                          onTap: () => _showCurrencyPicker(context),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        // Theme Selector Item
                        _buildSettingsItem(
                          icon: Icons.dark_mode_outlined,
                          title: 'Theme',
                          trailingText: _currentTheme,
                          iconColor: AppTheme.darkSlateVariant,
                          bgIconColor: AppTheme.darkSlateVariant.withAlpha(25),
                          onTap: () => _showThemePicker(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Support Settings Groups
                  _buildGroupTitle('Support'),
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
                        _buildSettingsItem(
                          icon: Icons.help_outline,
                          title: 'Help Center',
                          iconColor: AppTheme.secondary,
                          bgIconColor: AppTheme.secondary.withAlpha(25),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildSettingsItem(
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

  // ─── Hero Profile Card Widget ──────────────────────────────────────────────

  Widget _buildHeroProfileCard(ResponsiveHelper responsive, AuthUser? user) {
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
          // Background soft blurs
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
              // Avatar with floating edit button
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
              // User Name
              Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: responsive.scaleFont(22),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 4),
              // User Email
              Text(
                email,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: AppTheme.darkSlateVariant,
                ),
              ),
              const SizedBox(height: 20),
              // Badges
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


  // ─── Settings Item Builder Helper ──────────────────────────────────────────

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailingText,
    required Color iconColor,
    required Color bgIconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgIconColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: AppTheme.darkSlateVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlateVariant,
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(
              Icons.chevron_right,
              color: AppTheme.outlineVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.beVietnamPro(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.outline,
          letterSpacing: 1.5,
        ),
      ),
    );
  }


  void _showCurrencyPicker(BuildContext context) {
    final dashboardBloc = context.read<DashboardBloc>();
    final currentCurrency = dashboardBloc.state.activeWallet?.currency ?? 'IDR';

    final List<Map<String, String>> currencies = [
      {'code': 'IDR', 'name': 'Rupiah (IDR)', 'symbol': 'Rp'},
      {'code': 'USD', 'name': 'US Dollar (USD)', 'symbol': '\$'},
      {'code': 'EUR', 'name': 'Euro (EUR)', 'symbol': '€'},
      {'code': 'SGD', 'name': 'Singapore Dollar (SGD)', 'symbol': 'S\$'},
      {'code': 'JPY', 'name': 'Japanese Yen (JPY)', 'symbol': '¥'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose Currency',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Change the currency of your active wallet.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: AppTheme.darkSlateVariant,
                ),
              ),
              const SizedBox(height: 20),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currencies.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final curr = currencies[index];
                  final isSelected = curr['code'] == currentCurrency;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      curr['name']!,
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.darkSlate,
                      ),
                    ),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withAlpha(25)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        curr['symbol']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.darkSlateVariant,
                        ),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppTheme.primary,
                          )
                        : null,
                    onTap: () async {
                      Navigator.of(context).pop();
                      final completer = Completer<bool>();
                      dashboardBloc.add(DashboardUpdateWalletCurrencyRequested(curr['code']!, completer));
                      final success = await completer.future;
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Currency successfully changed to ${curr['code']}!'
                                  : 'Failed to change currency.',
                            ),
                            backgroundColor: success
                                ? Colors.green
                                : AppTheme.error,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showThemePicker(BuildContext context) {
    final List<Map<String, dynamic>> themes = [
      {'id': 'Light', 'name': 'Light', 'icon': Icons.light_mode},
      {'id': 'Dark', 'name': 'Dark', 'icon': Icons.dark_mode},
      {'id': 'System', 'name': 'System Default', 'icon': Icons.brightness_auto},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose Theme',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select your preferred app theme.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: AppTheme.darkSlateVariant,
                ),
              ),
              const SizedBox(height: 20),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: themes.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final theme = themes[index];
                  final isSelected = theme['id'] == _currentTheme;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      theme['name'],
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.darkSlate,
                      ),
                    ),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withAlpha(25)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        theme['icon'],
                        size: 18,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.darkSlateVariant,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppTheme.primary,
                          )
                        : null,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _currentTheme = theme['id'];
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Theme changed to ${theme['name']}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Notifications',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage your notification preferences.',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      color: AppTheme.darkSlateVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildNotificationSwitch(
                    title: 'Push Notifications',
                    subtitle: 'Receive alerts on your device',
                    value: _pushNotifications,
                    onChanged: (val) {
                      setModalState(() => _pushNotifications = val);
                      setState(() => _pushNotifications = val);
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildNotificationSwitch(
                    title: 'Email Notifications',
                    subtitle: 'Receive updates via email',
                    value: _emailNotifications,
                    onChanged: (val) {
                      setModalState(() => _emailNotifications = val);
                      setState(() => _emailNotifications = val);
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildNotificationSwitch(
                    title: 'Monthly Reports',
                    subtitle: 'Receive monthly financial summaries',
                    value: _monthlyReports,
                    onChanged: (val) {
                      setModalState(() => _monthlyReports = val);
                      setState(() => _monthlyReports = val);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppTheme.darkSlateVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}
