import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../widgets/auth_action_button.dart';
import '../widgets/auth_card_container.dart';
import '../widgets/auth_oauth_notice.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/password_strength_indicator.dart';

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
    final isGoogleUser = user?.authProvider == 'GOOGLE';

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
          child: isGoogleUser
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: AuthOAuthNotice(
                      title: 'Akun Google Terhubung',
                      description:
                          'Akun Anda terdaftar dan masuk melalui Google OAuth. Keamanan dan kata sandi akun dikelola langsung oleh akun Google Anda, sehingga tidak diperlukan kata sandi lokal di WalletShare.',
                      buttonText: 'Kembali ke Profil',
                      onButtonPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Security Recommendation Banner
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Container(
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
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Gunakan minimal 8 karakter dengan kombinasi huruf, angka, atau simbol agar akun bersama tetap aman.',
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
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password Card Form
                      AuthCardContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Informasi Kata Sandi',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppTheme.darkSlate,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Current Password
                            AuthTextField(
                              controller: _currentPasswordController,
                              labelText: 'Kata Sandi Saat Ini',
                              hintText: 'Masukkan kata sandi lama',
                              prefixIcon: Icons.lock_outline_rounded,
                              isPassword: true,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Kata sandi saat ini wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // New Password
                            AuthTextField(
                              controller: _newPasswordController,
                              labelText: 'Kata Sandi Baru',
                              hintText: 'Minimal 8 karakter',
                              prefixIcon: Icons.lock_rounded,
                              isPassword: true,
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Kata sandi baru wajib diisi';
                                }
                                if (val.length < 8) {
                                  return 'Kata sandi baru minimal 8 karakter';
                                }
                                if (val == _currentPasswordController.text) {
                                  return 'Kata sandi baru tidak boleh sama dengan kata sandi lama';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Live Strength Indicator
                            PasswordStrengthIndicator(
                              password: _newPasswordController.text,
                              confirmPassword: _confirmPasswordController.text,
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password
                            AuthTextField(
                              controller: _confirmPasswordController,
                              labelText: 'Konfirmasi Kata Sandi Baru',
                              hintText: 'Ulangi kata sandi baru',
                              prefixIcon: Icons.lock_reset_rounded,
                              isPassword: true,
                              textInputAction: TextInputAction.done,
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Konfirmasi kata sandi wajib diisi';
                                }
                                if (val != _newPasswordController.text) {
                                  return 'Kata sandi tidak cocok';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Action Buttons
                            AuthActionButton(
                              text: 'Perbarui Kata Sandi',
                              onPressed: _handleSubmit,
                              isLoading: authState.isLoading,
                              icon: Icons.check_circle_outline_rounded,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  shape: const StadiumBorder(),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                child: Text(
                                  'Batal',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppTheme.darkSlateVariant,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
