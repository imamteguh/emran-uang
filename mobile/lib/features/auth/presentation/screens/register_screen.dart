import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../expenses/presentation/screens/main_shell.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../widgets/auth_action_button.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_card_container.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/password_strength_indicator.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreeTerms = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap setujui Syarat & Ketentuan untuk melanjutkan'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final authBloc = context.read<AuthBloc>();
      final completer = Completer<bool>();
      authBloc.add(AuthRegisterRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
        completer: completer,
      ));

      final success = await completer.future;

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pendaftaran berhasil! Selamat datang di WalletShare.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShellScreen()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authBloc.state.errorMessage ?? 'Pendaftaran gagal. Silakan coba lagi.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient Decorative Blurred Circles
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.secondaryContainer.withAlpha(120),
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryFixed.withAlpha(110),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 65, sigmaY: 65),
                child: Container(color: Colors.transparent),
              ),
            ),

            // Back Button at Top Left
            Positioned(
              top: 16,
              left: 16,
              child: ClipOval(
                child: Material(
                  color: Colors.white.withAlpha(190),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppTheme.darkSlate,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Main Scrollable Form
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 36),

                      // Brand Header
                      const AuthBrandHeader(
                        title: 'Buat Akun Baru',
                        subtitle:
                            'Bergabung dengan WalletShare untuk mengelola dan mencapai target finansial bersama.',
                      ),
                      const SizedBox(height: 28),

                      // Card Container
                      AuthCardContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Display Name Field
                            AuthTextField(
                              controller: _nameController,
                              labelText: 'Nama Lengkap',
                              hintText: 'Sarah Connor',
                              prefixIcon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.name,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Nama lengkap wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email Field
                            AuthTextField(
                              controller: _emailController,
                              labelText: 'Alamat Email',
                              hintText: 'sarah@walletshare.com',
                              prefixIcon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                if (!val.contains('@') || !val.contains('.')) {
                                  return 'Masukkan format email yang valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            AuthTextField(
                              controller: _passwordController,
                              labelText: 'Kata Sandi',
                              hintText: 'Minimal 8 karakter',
                              prefixIcon: Icons.lock_outline_rounded,
                              isPassword: true,
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Kata sandi wajib diisi';
                                }
                                if (val.length < 8) {
                                  return 'Kata sandi minimal 8 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Live Password Strength Indicator
                            PasswordStrengthIndicator(
                              password: _passwordController.text,
                              confirmPassword: _confirmPasswordController.text,
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password Field
                            AuthTextField(
                              controller: _confirmPasswordController,
                              labelText: 'Konfirmasi Kata Sandi',
                              hintText: 'Ketik ulang kata sandi',
                              prefixIcon: Icons.lock_reset_rounded,
                              isPassword: true,
                              textInputAction: TextInputAction.done,
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Konfirmasi kata sandi wajib diisi';
                                }
                                if (val != _passwordController.text) {
                                  return 'Kata sandi tidak cocok';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Terms and Conditions Checkbox
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: _agreeTerms,
                                    onChanged: (val) {
                                      setState(() {
                                        _agreeTerms = val ?? false;
                                      });
                                    },
                                    activeColor: AppTheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _agreeTerms = !_agreeTerms;
                                      });
                                    },
                                    child: Text(
                                      'Saya menyetujui Syarat Layanan & Kebijakan Privasi WalletShare',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 12,
                                        color: AppTheme.darkSlateVariant,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            AuthActionButton(
                              text: 'Daftar Sekarang',
                              onPressed: _handleRegister,
                              isLoading: authState.isLoading,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Switch Prompt
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Sudah memiliki akun? ',
                            style: GoogleFonts.beVietnamPro(
                              color: AppTheme.darkSlateVariant,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Text(
                              'Masuk di sini',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
