import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/presentation/screens/change_password_screen.dart';
import '../../../auth/presentation/screens/update_profile_screen.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/user_avatar.dart';
import 'categories_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  void _handleLogout() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();
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
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

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

                  // Data Bersama Section
                  _buildPartnerProfileCard(responsive),
                  const SizedBox(height: 28),

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
                          subtitle: 'Ubah nama lengkap dan email Anda',
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
                          subtitle: 'Ubah kata sandi keamanan akun Anda',
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
                        // Notification Toggle Item
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.tertiaryFixed,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.notifications_active_outlined,
                                  color: AppTheme.tertiary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Notifications',
                                  style: GoogleFonts.beVietnamPro(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _notificationsEnabled,
                                onChanged: (val) {
                                  setState(() {
                                    _notificationsEnabled = val;
                                  });
                                },
                                activeThumbColor: AppTheme.primary,
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        // Currency Selector Item
                        _buildSettingsItem(
                          icon: Icons.currency_exchange,
                          title: 'Currency',
                          trailingText:
                              Provider.of<DashboardProvider>(
                                context,
                              ).activeWallet?.currency ??
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
                          trailingText: 'Light',
                          iconColor: AppTheme.darkSlateVariant,
                          bgIconColor: AppTheme.darkSlateVariant.withAlpha(25),
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
                        'WalletShare v2.4.1 (Build 829)',
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

  // ─── Data Bersama (Shared Group) View ───────────────────────────────────────

  Widget _buildPartnerProfileCard(ResponsiveHelper responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroupTitle('Data Bersama'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              // Group icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withAlpha(25),
                  border: Border.all(
                    color: AppTheme.primary.withAlpha(50),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.group,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Undang anggota baru',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    Text(
                      'Bagikan data pengeluaran & tagihan',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: AppTheme.darkSlateVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _showInviteDialog(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(80, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Undang',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
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

  void _showInviteDialog(BuildContext context) {
    final emailController = TextEditingController();
    final groupNameController = TextEditingController(text: 'Keluarga');

    showDialog(
      context: context,
      builder: (context) {
        final dashboardProvider = Provider.of<DashboardProvider>(
          context,
          listen: false,
        );
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Icon
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.group_add_outlined,
                      color: AppTheme.primary,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Undang Anggota Baru',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Hubungkan catatan pengeluaran bersama pasangan atau keluarga Anda.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: AppTheme.darkSlateVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Form Fields
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Anggota',
                    hintText: 'email@walletshare.com',
                    prefixIcon: Icon(Icons.alternate_email, size: 20),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: groupNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Grup Bersama',
                    hintText: 'Keluarga / Patungan',
                    prefixIcon: Icon(Icons.label_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final email = emailController.text.trim();
                          final groupName = groupNameController.text.trim();
                          if (email.isNotEmpty) {
                            final success = await dashboardProvider.sendInvite(
                              email,
                              groupName: groupName,
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Undangan berhasil dikirim!'
                                        : 'Gagal mengirim undangan.',
                                  ),
                                  backgroundColor: success
                                      ? Colors.green
                                      : AppTheme.error,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Kirim'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );
    final currentCurrency = dashboardProvider.activeWallet?.currency ?? 'IDR';

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
                'Pilih Mata Uang',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ubah mata uang pada dompet aktif Anda.',
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
                      final success = await dashboardProvider
                          .updateWalletCurrency(curr['code']!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Mata uang berhasil diubah ke ${curr['code']}!'
                                  : 'Gagal mengubah mata uang.',
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
}
