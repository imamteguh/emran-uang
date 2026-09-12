import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../bloc/dashboard_bloc.dart';
import '../../bloc/dashboard_event.dart';
import '../../screens/notifications_screen.dart';

/// Helper to load and save profile-related preferences
class ProfilePreferences {
  static const _keyPush = 'pref_push_notifications';
  static const _keyEmail = 'pref_email_notifications';
  static const _keyMonthly = 'pref_monthly_reports';
  static const _keyTheme = 'pref_app_theme';
  static const _keyLanguage = 'pref_app_language';

  static Future<Map<String, dynamic>> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'push': prefs.getBool(_keyPush) ?? true,
      'email': prefs.getBool(_keyEmail) ?? false,
      'monthly': prefs.getBool(_keyMonthly) ?? true,
      'theme': prefs.getString(_keyTheme) ?? 'Light',
      'language': prefs.getString(_keyLanguage) ?? 'id',
    };
  }

  static Future<void> saveNotifications({
    required bool push,
    required bool email,
    required bool monthly,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPush, push);
    await prefs.setBool(_keyEmail, email);
    await prefs.setBool(_keyMonthly, monthly);
  }

  static Future<void> saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, theme);
  }

  static Future<void> saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, language);
  }
}

// ─── Modal Sheet Handle Bar Helper ──────────────────────────────────────────
Widget _buildSheetHandle() {
  return Center(
    child: Container(
      width: 44,
      height: 5,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(2.5),
      ),
    ),
  );
}

// ─── 1. Currency Picker Sheet ───────────────────────────────────────────────
class CurrencyPickerBottomSheet extends StatelessWidget {
  final DashboardBloc dashboardBloc;
  final String currentCurrency;

  const CurrencyPickerBottomSheet({
    super.key,
    required this.dashboardBloc,
    required this.currentCurrency,
  });

  static Future<void> show(
    BuildContext context,
    DashboardBloc bloc,
    String current,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CurrencyPickerBottomSheet(
        dashboardBloc: bloc,
        currentCurrency: current,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> currencies = [
      {'code': 'IDR', 'name': 'Rupiah Indonesia', 'symbol': 'Rp', 'country': 'ID'},
      {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'country': 'US'},
      {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'country': 'EU'},
      {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'S\$', 'country': 'SG'},
      {'code': 'MYR', 'name': 'Malaysian Ringgit', 'symbol': 'RM', 'country': 'MY'},
      {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥', 'country': 'JP'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSheetHandle(),
          Text(
            'Pilih Mata Uang',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ubah mata uang utama pada dompet aktif Anda.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppTheme.darkSlateVariant,
            ),
          ),
          const SizedBox(height: 18),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: currencies.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final curr = currencies[index];
              final isSelected = curr['code'] == currentCurrency;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  Navigator.of(context).pop();
                  final completer = Completer<bool>();
                  dashboardBloc.add(
                    DashboardUpdateWalletCurrencyRequested(
                      curr['code']!,
                      completer,
                    ),
                  );
                  final success = await completer.future;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Mata uang berhasil diubah ke ${curr['code']}!'
                              : 'Gagal memperbarui mata uang.',
                        ),
                        backgroundColor:
                            success ? Colors.green : AppTheme.error,
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryFixed
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          curr['symbol']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.darkSlate,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              curr['name']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 14,
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.darkSlate,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              curr['code']!,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: AppTheme.darkSlateVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── 2. Theme Picker Sheet ──────────────────────────────────────────────────
class ThemePickerBottomSheet extends StatelessWidget {
  final String currentTheme;
  final ValueChanged<String> onThemeSelected;

  const ThemePickerBottomSheet({
    super.key,
    required this.currentTheme,
    required this.onThemeSelected,
  });

  static Future<void> show(
    BuildContext context,
    String current,
    ValueChanged<String> onSelected,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ThemePickerBottomSheet(
        currentTheme: current,
        onThemeSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> themes = [
      {
        'id': 'Light',
        'name': 'Mode Terang (Light)',
        'desc': 'Tampilan bersih dan nyaman untuk siang hari',
        'icon': Icons.light_mode_rounded,
      },
      {
        'id': 'Dark',
        'name': 'Mode Gelap (Dark)',
        'desc': 'Tampilan hemat baterai dan ramah di mata malam hari',
        'icon': Icons.dark_mode_rounded,
      },
      {
        'id': 'System',
        'name': 'Sesuai Sistem',
        'desc': 'Mengikuti pengaturan tema perangkat Anda secara otomatis',
        'icon': Icons.brightness_auto_rounded,
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSheetHandle(),
          Text(
            'Tema Tampilan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih preferensi visual tampilan aplikasi.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppTheme.darkSlateVariant,
            ),
          ),
          const SizedBox(height: 18),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: themes.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final theme = themes[index];
              final isSelected = theme['id'] == currentTheme;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ProfilePreferences.saveTheme(theme['id']);
                  onThemeSelected(theme['id']);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tema diatur ke ${theme['name']}'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryFixed
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          theme['icon'],
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.darkSlate,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              theme['name'],
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 14,
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.darkSlate,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              theme['desc'],
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: AppTheme.darkSlateVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── 3. Language Picker Sheet ───────────────────────────────────────────────
class LanguagePickerBottomSheet extends StatelessWidget {
  final String currentLanguage;
  final ValueChanged<String> onLanguageSelected;

  const LanguagePickerBottomSheet({
    super.key,
    required this.currentLanguage,
    required this.onLanguageSelected,
  });

  static Future<void> show(
    BuildContext context,
    String current,
    ValueChanged<String> onSelected,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => LanguagePickerBottomSheet(
        currentLanguage: current,
        onLanguageSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> languages = [
      {'code': 'id', 'name': 'Bahasa Indonesia', 'desc': 'Bahasa default aplikasi', 'flag': '🇮🇩'},
      {'code': 'en', 'name': 'English', 'desc': 'English language interface', 'flag': '🇬🇧'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSheetHandle(),
          Text(
            'Pilih Bahasa',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih bahasa yang ingin digunakan dalam aplikasi.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppTheme.darkSlateVariant,
            ),
          ),
          const SizedBox(height: 18),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: languages.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final lang = languages[index];
              final isSelected = lang['code'] == currentLanguage;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ProfilePreferences.saveLanguage(lang['code']!);
                  onLanguageSelected(lang['code']!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Bahasa diubah ke ${lang['name']}'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryFixed
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          lang['flag']!,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang['name']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 14,
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.darkSlate,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lang['desc']!,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: AppTheme.darkSlateVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── 4. Notification Settings Sheet ─────────────────────────────────────────
class NotificationPickerBottomSheet extends StatefulWidget {
  final bool initialPush;
  final bool initialEmail;
  final bool initialMonthly;
  final void Function(bool push, bool email, bool monthly) onChanged;

  const NotificationPickerBottomSheet({
    super.key,
    required this.initialPush,
    required this.initialEmail,
    required this.initialMonthly,
    required this.onChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required bool push,
    required bool email,
    required bool monthly,
    required void Function(bool push, bool email, bool monthly) onChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationPickerBottomSheet(
        initialPush: push,
        initialEmail: email,
        initialMonthly: monthly,
        onChanged: onChanged,
      ),
    );
  }

  @override
  State<NotificationPickerBottomSheet> createState() =>
      _NotificationPickerBottomSheetState();
}

class _NotificationPickerBottomSheetState
    extends State<NotificationPickerBottomSheet> {
  late bool _push;
  late bool _email;
  late bool _monthly;

  @override
  void initState() {
    super.initState();
    _push = widget.initialPush;
    _email = widget.initialEmail;
    _monthly = widget.initialMonthly;
  }

  void _updatePreference(bool p, bool e, bool m) {
    setState(() {
      _push = p;
      _email = e;
      _monthly = m;
    });
    ProfilePreferences.saveNotifications(push: _push, email: _email, monthly: _monthly);
    widget.onChanged(_push, _email, _monthly);
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
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
            onChanged: onToggle,
            activeTrackColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSheetHandle(),
          Text(
            'Pengaturan Notifikasi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kelola cara WalletShare mengirimkan pemberitahuan kepada Anda.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppTheme.darkSlateVariant,
            ),
          ),
          const SizedBox(height: 16),
          _buildSwitchItem(
            icon: Icons.notifications_active_outlined,
            title: 'Notifikasi Push Aplikasi',
            subtitle: 'Pengingat jatuh tempo tagihan & info dompet bersama',
            value: _push,
            onToggle: (val) => _updatePreference(val, _email, _monthly),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildSwitchItem(
            icon: Icons.mail_outline_rounded,
            title: 'Notifikasi Email',
            subtitle: 'Kirim salinan konfirmasi tagihan penting ke email',
            value: _email,
            onToggle: (val) => _updatePreference(_push, val, _monthly),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildSwitchItem(
            icon: Icons.pie_chart_outline_rounded,
            title: 'Laporan Finansial Bulanan',
            subtitle: 'Ringkasan analisis arus kas di awal setiap bulan',
            value: _monthly,
            onToggle: (val) => _updatePreference(_push, _email, val),
          ),
          const SizedBox(height: 20),

          // Shortcut to View Notification History
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.history_rounded, size: 18),
            label: const Text('Buka Riwayat Notifikasi Masuk'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 5. Help Center & FAQ Sheet ─────────────────────────────────────────────
class HelpCenterBottomSheet extends StatelessWidget {
  const HelpCenterBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HelpCenterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> faqs = [
      {
        'q': 'Bagaimana cara menambahkan transaksi baru?',
        'a':
            'Tekan tombol lingkaran (+) di bilah navigasi bawah. Anda dapat memilih "Transaksi Manual" untuk memasukkan nominal sendiri, atau "Scan Struk (OCR)" untuk mendeteksi struk otomatis menggunakan kamera.',
      },
      {
        'q': 'Bagaimana cara menggunakan Dompet Bersama (Shared Wallet)?',
        'a':
            'Anda dapat membuat dompet bersama dari layar Beranda atau Dompet, lalu bagikan kode undangan unik kepada keluarga atau rekan. Seluruh transaksi di dompet bersama dapat dipantau oleh seluruh anggota.',
      },
      {
        'q': 'Bagaimana cara mengatur Pengingat Tagihan (Bills Reminder)?',
        'a':
            'Buka menu Tagihan di navigasi bawah, lalu tekan tombol "+ Tambah Tagihan". Tentukan nominal, kategori, tanggal jatuh tempo, serta periode pengulangan (bulanan/tahunan).',
      },
      {
        'q': 'Apakah data finansial saya aman di WalletShare?',
        'a':
            'Sangat aman. Seluruh data transaksi dienkripsi saat transit menggunakan protokol SSL/TLS modern. Kata sandi akun Anda di-hash dengan standar keamanan tinggi dan tidak pernah disimpan secara terbuka.',
      },
      {
        'q': 'Bagaimana cara mengubah kategori transaksi kustom?',
        'a':
            'Masuk ke tab Profil -> pilih "Kelola Kategori". Anda dapat membuat kategori pengeluaran baru dengan warna dan ikon sesuai preferensi finansial Anda.',
      },
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHandle(),
              Text(
                'Pusat Bantuan & FAQ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pertanyaan umum seputar penggunaan aplikasi WalletShare.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: AppTheme.darkSlateVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: faqs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = faqs[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          iconColor: AppTheme.primary,
                          collapsedIconColor: AppTheme.outline,
                          title: Text(
                            item['q']!,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.darkSlate,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                16,
                              ),
                              child: Text(
                                item['a']!,
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 13,
                                  color: AppTheme.darkSlateVariant,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    const ClipboardData(text: 'support@walletshare.app'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Email dukungan (support@walletshare.app) disalin ke clipboard!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.email_outlined, size: 18),
                label: const Text('Hubungi Email Dukungan'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── 6. Privacy Policy Sheet ────────────────────────────────────────────────
class PrivacyPolicyBottomSheet extends StatelessWidget {
  const PrivacyPolicyBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PrivacyPolicyBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> sections = [
      {
        'title': '1. Informasi yang Kami Kumpulkan',
        'body':
            'WalletShare mengumpulkan informasi akun dasar seperti nama tampilan, alamat email, dan foto profil yang Anda berikan. Untuk akun Google OAuth, kami hanya mengakses profil dasar dan email tanpa akses ke kontak atau layanan Google lainnya.',
      },
      {
        'title': '2. Data Transaksi Finansial',
        'body':
            'Semua data pencatatan pengeluaran, anggaran, dan tagihan disimpan untuk keperluan personal Anda. Kami tidak membagikan, menjual, atau menyewakan informasi keuangan pribadi Anda kepada pihak ketiga mana pun.',
      },
      {
        'title': '3. Keamanan & Enkripsi Data',
        'body':
            'Kami menerapkan enkripsi standar industri tingkat tinggi (TLS/SSL) untuk transmisi data antara perangkat Anda dan server kami. Kata sandi akun dienkripsi menggunakan hashing kriptografis yang aman.',
      },
      {
        'title': '4. Penggunaan Gambar Struk (OCR)',
        'body':
            'Gambar struk belanja yang dipindai melalui fitur OCR dianalisis secara aman semata-mata untuk mengekstrak informasi harga dan nama merchant, dan tidak disimpan sebagai materi analitik pihak ketiga.',
      },
      {
        'title': '5. Kontrol & Penghapusan Akun',
        'body':
            'Anda memiliki hak penuh untuk memperbarui, mengekspor, atau meminta penghapusan permanen akun beserta seluruh data transaksi yang terkait kapan saja melalui tim dukungan kami.',
      },
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHandle(),
              Text(
                'Kebijakan Privasi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Terakhir diperbarui: September 2026 • WalletShare v2.4',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  color: AppTheme.darkSlateVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: sections.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final sec = sections[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sec['title']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          sec['body']!,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            color: AppTheme.darkSlateVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Saya Memahami'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── 7. Export Data Bottom Sheet ────────────────────────────────────────────
class ExportDataBottomSheet extends StatelessWidget {
  final DashboardBloc dashboardBloc;

  const ExportDataBottomSheet({
    super.key,
    required this.dashboardBloc,
  });

  static Future<void> show(BuildContext context, DashboardBloc bloc) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExportDataBottomSheet(dashboardBloc: bloc),
    );
  }

  String _generateCsv(List<dynamic> expenses, String currency) {
    final buffer = StringBuffer();
    buffer.writeln('Tanggal,Kategori,Deskripsi,Nominal,Mata Uang,Tipe');
    for (final exp in expenses) {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(exp.date);
      final categoryName = exp.category?.name ?? 'Umum';
      final desc = exp.description.replaceAll(',', ' ');
      final amount = exp.amount;
      final type = exp.type.name;
      buffer.writeln('$dateStr,$categoryName,$desc,$amount,$currency,$type');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final state = dashboardBloc.state;
    final expenses = state.expenses;
    final currency = state.activeWallet?.currency ?? 'IDR';
    final totalExpense = expenses.fold<double>(0, (sum, item) => sum + item.amount);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSheetHandle(),
          Text(
            'Ekspor Ringkasan Transaksi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ekspor catatan pengeluaran dompet aktif dalam format CSV/Teks.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppTheme.darkSlateVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Total Baris',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: AppTheme.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${expenses.length} Transaksi',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                  ],
                ),
                Container(height: 30, width: 1, color: const Color(0xFFCBD5E1)),
                Column(
                  children: [
                    Text(
                      'Total Nominal',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: AppTheme.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currency ${NumberFormat('#,###').format(totalExpense)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () {
              final csvData = _generateCsv(expenses, currency);
              Clipboard.setData(ClipboardData(text: csvData));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Berhasil mengekspor ${expenses.length} baris transaksi ke Clipboard (format CSV)!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.copy_all_rounded, size: 20),
            label: const Text('Salin Data CSV ke Clipboard'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }
}

// ─── 8. Logout Confirmation Sheet ───────────────────────────────────────────
class LogoutConfirmationBottomSheet extends StatelessWidget {
  final VoidCallback onConfirmLogout;

  const LogoutConfirmationBottomSheet({
    super.key,
    required this.onConfirmLogout,
  });

  static Future<void> show(BuildContext context, VoidCallback onConfirm) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => LogoutConfirmationBottomSheet(onConfirmLogout: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSheetHandle(),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.errorContainer.withAlpha(120),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.logout_rounded,
              color: AppTheme.error,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Keluar dari Akun?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Anda harus memasukkan kembali email dan kata sandi atau akun Google untuk mengakses kembali data finansial Anda.',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppTheme.darkSlateVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirmLogout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Ya, Keluar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
