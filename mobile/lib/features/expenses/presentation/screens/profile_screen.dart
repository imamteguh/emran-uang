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
import '../bloc/dashboard_event.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../widgets/profile/profile.dart';
import 'categories_screen.dart';
import 'notifications_screen.dart';
import 'shared_groups_screen.dart';

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
  String _currentLanguage = 'id';
  String _appVersion = 'WalletShare v2.4.1';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadVersionInfo();
  }

  Future<void> _loadPreferences() async {
    final prefs = await ProfilePreferences.loadPreferences();
    if (mounted) {
      setState(() {
        _pushNotifications = prefs['push'] as bool;
        _emailNotifications = prefs['email'] as bool;
        _monthlyReports = prefs['monthly'] as bool;
        _currentTheme = prefs['theme'] as String;
        _currentLanguage = prefs['language'] as String;
      });
    }
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
    LogoutConfirmationBottomSheet.show(context, () {
      context.read<AuthBloc>().add(const AuthLogoutRequested());
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    });
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(60),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.wallet_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'WalletShare',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _appVersion,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Aplikasi manajemen keuangan pintar, pelacak anggaran, tagihan berkala, dan dompet bersama modern.',
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: AppTheme.darkSlateVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Dibuat dengan ❤️ untuk kemudahan finansial Anda',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Tutup',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleSyncData() async {
    final dashboardBloc = context.read<DashboardBloc>();
    dashboardBloc.add(const DashboardRefreshRequested());
    dashboardBloc.add(const DashboardFetchCategoriesRequested());
    dashboardBloc.add(const DashboardFetchRemindersRequested());
    context.read<NotificationBloc>().add(const NotificationFetchUnreadCountRequested());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sinkronisasi data berhasil diperbarui dari server!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final authState = context.watch<AuthBloc>().state;
    final user = authState.currentUser;
    final dashboardBloc = context.watch<DashboardBloc>();
    final dashboardState = dashboardBloc.state;
    final activeWallet = dashboardState.activeWallet;
    final notificationState = context.watch<NotificationBloc>().state;

    final double contentWidth = responsive.isTablet || responsive.isDesktop
        ? 480
        : double.infinity;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Top Dark Navy
      appBar: AppBar(
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
                    color: AppTheme.primary.withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Profil & Pengaturan',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: responsive.scaleFont(19),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Sinkronisasi Data',
            onPressed: _handleSyncData,
          ),

          // Notification Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white70,
                ),
                tooltip: 'Notifikasi',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              if (notificationState.hasUnread)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppTheme.primary,
          backgroundColor: Colors.white,
          onRefresh: () async {
            _handleSyncData();
            await _loadPreferences();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Top Hero Section in Dark Navy
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: ProfileHeroCard(
                        responsive: responsive,
                        user: user,
                        totalCategories: dashboardState.categories.length,
                        totalWallets: dashboardState.allWallets.length,
                        activeWalletName: activeWallet?.name ?? 'Dompet Utama',
                        activeWalletCurrency: activeWallet?.currency ?? 'IDR',
                        onEditProfile: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UpdateProfileScreen(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Lower Curved Container (Soft Slate Background #F7F9FB)
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F9FB),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ─── 1. Akun & Keamanan ─────────────────────────
                            const ProfileGroupTitle(
                              title: 'Akun & Keamanan',
                              icon: Icons.shield_outlined,
                            ),
                            ProfileGroupCard(
                              children: [
                                ProfileSettingsTile(
                                  icon: Icons.person_outline_rounded,
                                  title: 'Edit Profil',
                                  subtitle: 'Nama lengkap, foto profil & email',
                                  iconColor: AppTheme.primary,
                                  bgIconColor: AppTheme.primaryFixed,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const UpdateProfileScreen(),
                                    ),
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFF1F5F9),
                                ),
                                ProfileSettingsTile(
                                  icon: Icons.lock_outline_rounded,
                                  title: 'Ubah Kata Sandi',
                                  subtitle: 'Perbarui kata sandi keamanan akun',
                                  iconColor: AppTheme.secondary,
                                  bgIconColor: AppTheme.secondaryFixed,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ChangePasswordScreen(),
                                    ),
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFF1F5F9),
                                ),
                                ProfileSettingsTile(
                                  icon: Icons.category_outlined,
                                  title: 'Kelola Kategori',
                                  subtitle:
                                      'Atur dan sesuaikan kategori pengeluaran',
                                  iconColor: AppTheme.tertiary,
                                  bgIconColor: AppTheme.tertiaryFixed,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CategoriesScreen(),
                                    ),
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFF1F5F9),
                                ),
                                ProfileSettingsTile(
                                  icon: Icons.groups_rounded,
                                  title: 'Kelola Grup (Dompet Bersama)',
                                  subtitle:
                                      'Atur anggota grup, undang rekan & dompet bersama',
                                  iconColor: const Color(0xFF6366F1),
                                  bgIconColor: const Color(0xFFE0E7FF),
                                  trailingWidget: dashboardState.pendingInvites.isNotEmpty
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${dashboardState.pendingInvites.length} Undangan',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : null,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const SharedGroupsScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // ─── 2. Preferensi Aplikasi ──────────────────────
                            const ProfileGroupTitle(
                              title: 'Preferensi Aplikasi',
                              icon: Icons.tune_rounded,
                            ),
                            ProfileGroupCard(
                              children: [
                                ProfileSettingsTile(
                                  icon: Icons.currency_exchange_rounded,
                                  title: 'Mata Uang',
                                  subtitle: 'Mata uang standar dompet aktif',
                                  trailingText: activeWallet?.currency ?? 'IDR',
                                  iconColor: AppTheme.primary,
                                  bgIconColor: AppTheme.primaryFixed,
                                  onTap: () => CurrencyPickerBottomSheet.show(
                                    context,
                                    dashboardBloc,
                                    activeWallet?.currency ?? 'IDR',
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFF1F5F9),
                                ),
                                ProfileSettingsTile(
                                  icon: Icons.notifications_active_outlined,
                                  title: 'Pengaturan Notifikasi',
                                  subtitle: 'Push alert, email & ringkasan',
                                  trailingText:
                                      _pushNotifications ? 'Aktif' : 'Mati',
                                  iconColor: const Color(0xFFEA580C),
                                  bgIconColor: const Color(0xFFFFEDD5),
                                  onTap: () =>
                                      NotificationPickerBottomSheet.show(
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
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFF1F5F9),
                                ),
                                ProfileSettingsTile(
                                  icon: Icons.palette_outlined,
                                  title: 'Tema Tampilan',
                                  subtitle: 'Sesuaikan mode gelap atau terang',
                                  trailingText: _currentTheme,
                                  iconColor: const Color(0xFF475569),
                                  bgIconColor: const Color(0xFFE2E8F0),
                                  onTap: () => ThemePickerBottomSheet.show(
                                    context,
                                    _currentTheme,
                                    (theme) =>
                                        setState(() => _currentTheme = theme),
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFF1F5F9),
                                ),
                                ProfileSettingsTile(
                                  icon: Icons.language_rounded,
                                  title: 'Bahasa',
                                  subtitle: 'Bahasa antarmuka aplikasi',
                                  trailingText: _currentLanguage == 'id'
                                      ? 'Indonesia'
                                      : 'English',
                                  iconColor: const Color(0xFF0284C7),
                                  bgIconColor: const Color(0xFFE0F2FE),
                                  onTap: () => LanguagePickerBottomSheet.show(
                                    context,
                                    _currentLanguage,
                                    (lang) =>
                                        setState(() => _currentLanguage = lang),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // ─── 3. Data & Cadangan ─────────────────────────
                            const ProfileGroupTitle(
                              title: 'Data & Cadangan',
                              icon: Icons.storage_rounded,
                            ),
                            ProfileGroupCard(
                              children: [
                                ProfileSettingsTile(
                                  icon: Icons.file_download_outlined,
                                  title: 'Ekspor Data Finansial',
                                  subtitle:
                                      'Salin laporan transaksi bulanan ke format CSV',
                                  iconColor: AppTheme.secondary,
                                  bgIconColor: AppTheme.secondaryFixed,
                                  onTap: () => ExportDataBottomSheet.show(
                                    context,
                                    dashboardBloc,
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFF1F5F9),
                                ),
                                ProfileSettingsTile(
                                  icon: Icons.sync_rounded,
                                  title: 'Sinkronisasi Server',
                                  subtitle:
                                      'Perbarui data transaksi & dompet terkini',
                                  iconColor: AppTheme.primary,
                                  bgIconColor: AppTheme.primaryFixed,
                                  onTap: _handleSyncData,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // ─── 4. Bantuan & Kebijakan ──────────────────────
                            const ProfileGroupTitle(
                              title: 'Bantuan & Kebijakan',
                              icon: Icons.help_outline_rounded,
                            ),
                            ProfileGroupCard(
                              children: [
                                ProfileSettingsTile(
                                  icon: Icons.quiz_outlined,
                                  title: 'Pusat Bantuan & FAQ',
                                  subtitle:
                                      'Panduan pemakaian aplikasi & kontak bantuan',
                                  iconColor: const Color(0xFFD97706),
                                  bgIconColor: const Color(0xFFFEF3C7),
                                  onTap: () =>
                                      HelpCenterBottomSheet.show(context),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFF1F5F9),
                                ),
                                ProfileSettingsTile(
                                  icon: Icons.verified_user_outlined,
                                  title: 'Kebijakan Privasi',
                                  subtitle:
                                      'Keamanan enkripsi & perlindungan data',
                                  iconColor: AppTheme.secondary,
                                  bgIconColor: AppTheme.secondaryFixed,
                                  onTap: () =>
                                      PrivacyPolicyBottomSheet.show(context),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFF1F5F9),
                                ),
                                ProfileSettingsTile(
                                  icon: Icons.info_outline_rounded,
                                  title: 'Tentang Aplikasi',
                                  subtitle: 'Informasi versi & lisensi pengembang',
                                  iconColor: const Color(0xFF64748B),
                                  bgIconColor: const Color(0xFFF1F5F9),
                                  onTap: () => _showAboutDialog(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // ─── 5. Logout Button ────────────────────────────
                            OutlinedButton.icon(
                              onPressed: _handleLogout,
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: AppTheme.error,
                                size: 20,
                              ),
                              label: Text(
                                'Keluar dari Akun',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppTheme.error,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppTheme.error.withAlpha(60),
                                  width: 1.5,
                                ),
                                backgroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ─── Version & Copyright Label ───────────────────
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    _appVersion,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 12,
                                      color: AppTheme.outline,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'WalletShare • Hak Cipta © 2026',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 11,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
