import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../expenses/presentation/screens/main_shell.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../widgets/auth_action_button.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_card_container.dart';
import '../widgets/auth_social_button.dart';
import '../widgets/auth_text_field.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = true;
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authBloc = context.read<AuthBloc>();
      final completer = Completer<bool>();
      authBloc.add(AuthLoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
        completer: completer,
      ));

      final success = await completer.future;

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShellScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authBloc.state.errorMessage ?? 'Login gagal. Periksa kembali email & password Anda.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _handleGoogleLogin() async {
    final authBloc = context.read<AuthBloc>();
    final completer = Completer<bool>();
    authBloc.add(AuthGoogleLoginRequested(completer: completer));

    final success = await completer.future;

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
      );
    } else if (mounted && authBloc.state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authBloc.state.errorMessage!),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showForgotPasswordSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryFixed.withAlpha(120),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lupa Kata Sandi?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Untuk keamanan akun bersama Anda, reset kata sandi dapat dilakukan melalui konfirmasi email terdaftar atau meminta bantuan admin kelompok dompet Anda.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: AppTheme.darkSlateVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      color: AppTheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bantuan Support: support@walletshare.id',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    backgroundColor: AppTheme.primary,
                  ),
                  child: Text(
                    'Mengerti',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final responsive = ResponsiveHelper(context);

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

            // Scrollable Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Brand Header with Floating Icon
                      AnimatedBuilder(
                        animation: _floatAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatAnimation.value),
                            child: child,
                          );
                        },
                        child: const AuthBrandHeader(
                          title: 'Selamat Datang Kembali',
                          subtitle:
                              'Kelola, lacak, dan rencanakan keuangan bersama pasangan dengan tenang.',
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Auth Elevated Card
                      AuthCardContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Google Sign-In
                            AuthSocialButton(
                              onPressed: _handleGoogleLogin,
                              isLoading: authState.isLoading,
                              text: 'Lanjutkan dengan Google',
                            ),
                            const SizedBox(height: 20),

                            // Divider Row
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(color: Color(0xFFE2E8F0)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'ATAU MASUK DENGAN EMAIL',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.darkSlateVariant,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(color: Color(0xFFE2E8F0)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Email Field
                            AuthTextField(
                              controller: _emailController,
                              labelText: 'Alamat Email',
                              hintText: 'nama@walletshare.com',
                              prefixIcon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                if (!val.contains('@') || !val.contains('.')) {
                                  return 'Masukkan alamat email yang valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            AuthTextField(
                              controller: _passwordController,
                              labelText: 'Kata Sandi',
                              hintText: '••••••••',
                              prefixIcon: Icons.lock_outline_rounded,
                              isPassword: true,
                              textInputAction: TextInputAction.done,
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Kata sandi tidak boleh kosong';
                                }
                                if (val.length < 6) {
                                  return 'Kata sandi minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Remember me & Forgot Password
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (val) {
                                          setState(() {
                                            _rememberMe = val ?? false;
                                          });
                                        },
                                        activeColor: AppTheme.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _rememberMe = !_rememberMe;
                                        });
                                      },
                                      child: Text(
                                        'Ingat saya',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.darkSlateVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: _showForgotPasswordSheet,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Lupa Sandi?',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            AuthActionButton(
                              text: 'Masuk Sekarang',
                              onPressed: _handleLogin,
                              isLoading: authState.isLoading,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign Up Prompt
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun? ',
                            style: GoogleFonts.beVietnamPro(
                              color: AppTheme.darkSlateVariant,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Buat akun bersama',
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

                      // Trust Badges
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 28,
                        runSpacing: 12,
                        children: [
                          _buildTrustBadge(
                            Icons.shield_outlined,
                            'Privasi & Enkripsi Aman',
                            responsive,
                          ),
                          _buildTrustBadge(
                            Icons.favorite_outline_rounded,
                            'Didesain untuk Pasangan',
                            responsive,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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

  Widget _buildTrustBadge(
    IconData icon,
    String label,
    ResponsiveHelper responsive,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: AppTheme.secondary, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: responsive.scaleFont(11),
            fontWeight: FontWeight.w600,
            color: AppTheme.darkSlateVariant,
          ),
        ),
      ],
    );
  }
}
