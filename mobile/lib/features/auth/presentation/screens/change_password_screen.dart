import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Calculate password strength (0.0 to 1.0)
  double _calculateStrength(String password) {
    if (password.isEmpty) return 0.0;
    double strength = 0.0;
    if (password.length >= 8) strength += 0.35;
    if (password.length >= 12) strength += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) {
      strength += 0.25;
    }
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.10;
    return strength.clamp(0.0, 1.0);
  }

  Color _getStrengthColor(double strength) {
    if (strength < 0.4) return AppTheme.error;
    if (strength < 0.75) return const Color(0xFFEAB308); // Amber
    return const Color(0xFF16A34A); // Green
  }

  String _getStrengthLabel(double strength) {
    if (strength == 0.0) return 'Belum Diisi';
    if (strength < 0.4) return 'Kata Sandi Lemah';
    if (strength < 0.75) return 'Kata Sandi Sedang';
    return 'Kata Sandi Sangat Kuat';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authBloc = context.read<AuthBloc>();
    final completer = Completer<bool>();

    authBloc.add(AuthPasswordChanged(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      completer: completer,
    ));

    final success = await completer.future;

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kata sandi berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authBloc.state.errorMessage ?? 'Gagal mengubah kata sandi.',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final authState = context.watch<AuthBloc>().state;
    final user = authState.currentUser;

    final double formWidth = responsive.isTablet || responsive.isDesktop
        ? 480
        : double.infinity;
    final isGoogleUser = user?.authProvider == 'GOOGLE';

    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;
    final strength = _calculateStrength(newPass);
    final strengthColor = _getStrengthColor(strength);
    final strengthLabel = _getStrengthLabel(strength);

    final bool hasMinLength = newPass.length >= 8;
    final bool hasNumberOrSymbol =
        RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]').hasMatch(newPass);
    final bool passwordsMatch =
        newPass.isNotEmpty && confirmPass.isNotEmpty && newPass == confirmPass;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Ubah Kata Sandi',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: responsive.scaleFont(18),
            color: AppTheme.darkSlate,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.darkSlate),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: SizedBox(
              width: formWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isGoogleUser) ...[
                    // Google OAuth notice card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFBFDBFE),
                          width: 1,
                        ),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.g_mobiledata_rounded,
                              color: Color(0xFF1D4ED8),
                              size: 42,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Akun Google Terhubung',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkSlate,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Akun Anda terdaftar dan masuk melalui Google OAuth. Keamanan dan kata sandi akun dikelola langsung oleh akun Google Anda, sehingga tidak diperlukan kata sandi lokal di WalletShare.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.beVietnamPro(
                              color: AppTheme.darkSlateVariant,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text('Kembali ke Profil'),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Security Card Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFBBF7D0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: Color(0xFF16A34A),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Gunakan minimal 8 karakter dengan kombinasi huruf, angka, atau simbol agar akun Anda tetap terlindungi.',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: const Color(0xFF166534),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password Form Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informasi Kata Sandi',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppTheme.darkSlate,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Current Password Field
                            TextFormField(
                              controller: _currentPasswordController,
                              obscureText: _obscureCurrent,
                              decoration: InputDecoration(
                                labelText: 'Kata Sandi Saat Ini',
                                hintText: 'Masukkan kata sandi lama',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureCurrent
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppTheme.outline,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () => _obscureCurrent = !_obscureCurrent,
                                    );
                                  },
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Kata sandi saat ini wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // New Password Field
                            TextFormField(
                              controller: _newPasswordController,
                              obscureText: _obscureNew,
                              decoration: InputDecoration(
                                labelText: 'Kata Sandi Baru',
                                hintText: 'Minimal 8 karakter',
                                prefixIcon: const Icon(Icons.key_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureNew
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppTheme.outline,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscureNew = !_obscureNew);
                                  },
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Kata sandi baru wajib diisi';
                                }
                                if (val.length < 8) {
                                  return 'Kata sandi baru minimal 8 karakter';
                                }
                                return null;
                              },
                            ),

                            // Password Strength Bar
                            if (newPass.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Kekuatan Sandi:',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 12,
                                      color: AppTheme.outline,
                                    ),
                                  ),
                                  Text(
                                    strengthLabel,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: strengthColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: strength,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  valueColor:
                                      AlwaysStoppedAnimation(strengthColor),
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),

                            // Confirm New Password Field
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirm,
                              decoration: InputDecoration(
                                labelText: 'Konfirmasi Kata Sandi Baru',
                                hintText: 'Ulangi kata sandi baru',
                                prefixIcon:
                                    const Icon(Icons.lock_reset_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppTheme.outline,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    );
                                  },
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Konfirmasi kata sandi wajib diisi';
                                }
                                if (val != _newPasswordController.text) {
                                  return 'Konfirmasi kata sandi tidak cocok';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Requirement Checklist
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFEDF2F7),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildCheckItem(
                                    label: 'Minimal 8 karakter',
                                    isMet: hasMinLength,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildCheckItem(
                                    label: 'Mengandung angka atau simbol',
                                    isMet: hasNumberOrSymbol,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildCheckItem(
                                    label: 'Konfirmasi kata sandi cocok',
                                    isMet: passwordsMatch,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            authState.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppTheme.primary,
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: _handleSubmit,
                                    child: const Text('Simpan Kata Sandi'),
                                  ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Batal'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem({required String label, required bool isMet}) {
    return Row(
      children: [
        Icon(
          isMet
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: isMet ? const Color(0xFF16A34A) : AppTheme.outlineVariant,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 12,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
            color: isMet ? AppTheme.darkSlate : AppTheme.darkSlateVariant,
          ),
        ),
      ],
    );
  }
}
