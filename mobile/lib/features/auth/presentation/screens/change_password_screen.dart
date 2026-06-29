import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../providers/auth_provider.dart';

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
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Call provider to change password
    final success = await authProvider.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kata sandi berhasil diubah!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Gagal mengubah kata sandi.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    final double formWidth = responsive.isTablet || responsive.isDesktop ? 480 : double.infinity;

    // Check if user is logged in via Google OAuth
    final isGoogleUser = user?.authProvider == 'GOOGLE';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ubah Kata Sandi',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: responsive.scaleFont(18),
            color: AppTheme.darkSlate,
          ),
        ),
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.darkSlate),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsive.screenPadding,
          child: Center(
            child: SizedBox(
              width: formWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isGoogleUser) ...[
                    // Info card showing Google user warning
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiaryFixed,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.tertiary.withAlpha(50), width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.tertiary,
                            size: 24,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Google Sign-In Aktif',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.tertiary,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Akun Anda terhubung melalui Google OAuth. Anda tidak memiliki kata sandi lokal untuk diubah.',
                                  style: GoogleFonts.beVietnamPro(
                                    color: AppTheme.darkSlateVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Kembali'),
                    ),
                  ] else ...[
                    // Description
                    Text(
                      'Pastikan kata sandi baru Anda aman dan terdiri dari minimal 8 karakter.',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        color: AppTheme.darkSlateVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Password Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Current Password Field
                          TextFormField(
                            controller: _currentPasswordController,
                            obscureText: _obscureCurrent,
                            decoration: InputDecoration(
                              labelText: 'Kata Sandi Sekarang',
                              hintText: 'Masukkan kata sandi lama',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppTheme.outline,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscureCurrent = !_obscureCurrent);
                                },
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Kata sandi saat ini harus diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // New Password Field
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: _obscureNew,
                            decoration: InputDecoration(
                              labelText: 'Kata Sandi Baru',
                              hintText: 'Minimal 8 karakter',
                              prefixIcon: const Icon(Icons.lock_open_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
                                return 'Kata sandi baru harus diisi';
                              }
                              if (val.length < 8) {
                                return 'Kata sandi baru harus minimal 8 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirm New Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              labelText: 'Konfirmasi Kata Sandi Baru',
                              hintText: 'Ulangi kata sandi baru',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppTheme.outline,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscureConfirm = !_obscureConfirm);
                                },
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Konfirmasi kata sandi baru harus diisi';
                              }
                              if (val != _newPasswordController.text) {
                                return 'Konfirmasi kata sandi tidak cocok';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Submit Button
                          authProvider.isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(color: AppTheme.primary),
                                )
                              : ElevatedButton(
                                  onPressed: _handleSubmit,
                                  child: const Text('Simpan Kata Sandi'),
                                ),
                        ],
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
}
