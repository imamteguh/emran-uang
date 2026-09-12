import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../expenses/presentation/widgets/user_avatar.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../widgets/auth_action_button.dart';
import '../widgets/auth_card_container.dart';
import '../widgets/auth_oauth_notice.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/avatar_picker_modal.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  String? _selectedAvatarUrl;

  @override
  void initState() {
    super.initState();
    final authBloc = context.read<AuthBloc>();
    final user = authBloc.state.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _selectedAvatarUrl = user?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _openAvatarPicker() {
    AvatarPickerModal.show(
      context: context,
      initialAvatar: _selectedAvatarUrl,
      onAvatarSelected: (newAvatar) {
        setState(() {
          _selectedAvatarUrl = newAvatar;
        });
      },
    );
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final authBloc = context.read<AuthBloc>();
    final user = authBloc.state.currentUser;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    final completer = Completer<bool>();
    authBloc.add(AuthProfileUpdated(
      displayName: name,
      email: user?.authProvider == 'GOOGLE' ? null : email,
      avatarUrl: _selectedAvatarUrl,
      completer: completer,
    ));

    final success = await completer.future;

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authBloc.state.errorMessage ?? 'Gagal memperbarui profil.',
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

    final registrationDate = user?.createdAt != null
        ? DateFormat('dd MMMM yyyy').format(user!.createdAt!)
        : 'Pengguna Aktif';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Edit Profil',
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
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Avatar Section with Edit Badge
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primary.withAlpha(45),
                              width: 3,
                            ),
                          ),
                          child: UserAvatar(
                            avatarUrl: _selectedAvatarUrl,
                            displayName: _nameController.text.isNotEmpty
                                ? _nameController.text
                                : 'U',
                            size: 104,
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _openAvatarPicker,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withAlpha(60),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _openAvatarPicker,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: Text(
                      'Ubah Foto Profil',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Basic Information Card
                  AuthCardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Informasi Dasar',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Name Field
                        AuthTextField(
                          controller: _nameController,
                          labelText: 'Nama Lengkap',
                          hintText: 'Masukkan nama lengkap Anda',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Nama lengkap tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        AuthTextField(
                          controller: _emailController,
                          labelText: 'Alamat Email',
                          hintText: 'nama@domain.com',
                          prefixIcon: Icons.mail_outline_rounded,
                          enabled: !isGoogleUser,
                          validator: (val) {
                            if (isGoogleUser) return null;
                            if (val == null || val.trim().isEmpty) {
                              return 'Email tidak boleh kosong';
                            }
                            if (!val.contains('@') || !val.contains('.')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),

                        if (isGoogleUser) ...[
                          const SizedBox(height: 14),
                          const AuthOAuthNotice(
                            isCompact: true,
                            description:
                                'Akun terhubung via Google OAuth. Alamat email Anda diverifikasi secara otomatis oleh Google dan tidak dapat diubah.',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Account Metadata Card
                  AuthCardContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        _buildMetadataRow(
                          icon: Icons.badge_outlined,
                          label: 'Tipe Autentikasi',
                          value: isGoogleUser ? 'Google OAuth' : 'Email & Password',
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _buildMetadataRow(
                          icon: Icons.calendar_month_outlined,
                          label: 'Terdaftar Sejak',
                          value: registrationDate,
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _buildMetadataRow(
                          icon: Icons.fingerprint_rounded,
                          label: 'ID Akun',
                          value: user?.id ?? '-',
                          isMonospace: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AuthActionButton(
                          text: 'Simpan Perubahan',
                          onPressed: _handleSave,
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
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
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
      ),
    );
  }

  Widget _buildMetadataRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMonospace = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.outline),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: AppTheme.darkSlateVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: isMonospace
                ? GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkSlate,
                  )
                : GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkSlate,
                  ),
          ),
        ),
      ],
    );
  }
}
