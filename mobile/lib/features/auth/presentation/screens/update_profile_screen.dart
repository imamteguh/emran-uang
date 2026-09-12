import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../expenses/presentation/widgets/user_avatar.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

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
  final ImagePicker _picker = ImagePicker();

  final List<String> _avatarPresets = [
    '🦊', '🐱', '🦁', '🐯', '🐨', '🐼',
    '🐰', '🐶', '🦄', '🐸', '🐙', '🐵',
    '💼', '💡', '🔥', '✨', '🍀', '🎯',
    '🚗', '✈️', '🎮', '🏀', '🍕', '☕',
  ];

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

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _selectedAvatarUrl = base64Image;
        });
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _selectedAvatarUrl = base64Image;
        });
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showAvatarPicker() {
    final urlController = TextEditingController(
      text: (_selectedAvatarUrl != null &&
              _selectedAvatarUrl!.startsWith('http'))
          ? _selectedAvatarUrl
          : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
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
                  Text(
                    'Pilih Foto Profil',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ambil foto baru, pilih dari galeri, atau gunakan avatar karakter.',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      color: AppTheme.darkSlateVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action choices: Camera & Gallery
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickImageFromGallery,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.photo_library_outlined,
                                  color: AppTheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Galeri Foto',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _pickImageFromCamera,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.camera_alt_outlined,
                                  color: AppTheme.secondary,
                                  size: 24,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Ambil Foto',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Preset Avatar Karakter',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Emoji presets grid
                  SizedBox(
                    height: 150,
                    child: GridView.builder(
                      itemCount: _avatarPresets.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        final emoji = _avatarPresets[index];
                        final isSelected = _selectedAvatarUrl == emoji;

                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              _selectedAvatarUrl = emoji;
                            });
                            setState(() {
                              _selectedAvatarUrl = emoji;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppTheme.primaryFixed
                                  : const Color(0xFFF8FAFC),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // URL input
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'Atau Masukkan URL Gambar',
                      hintText: 'https://example.com/avatar.jpg',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        _selectedAvatarUrl =
                            val.trim().isEmpty ? null : val.trim();
                      });
                      setState(() {
                        _selectedAvatarUrl =
                            val.trim().isEmpty ? null : val.trim();
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (urlController.text.trim().isNotEmpty) {
                              setState(() {
                                _selectedAvatarUrl = urlController.text.trim();
                              });
                            }
                            Navigator.of(context).pop();
                          },
                          child: const Text('Pilih Avatar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
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

    final double formWidth = responsive.isTablet || responsive.isDesktop
        ? 480
        : double.infinity;
    final isGoogleUser = user?.authProvider == 'GOOGLE';
    final registrationDate = user?.createdAt != null
        ? DateFormat('dd MMMM yyyy').format(user!.createdAt!)
        : 'Tidak diketahui';

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
            child: SizedBox(
              width: formWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primary.withAlpha(40),
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
                              onTap: _showAvatarPicker,
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
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _showAvatarPicker,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: Text(
                      'Ubah Foto Profil',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Fields Card Container
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
                            'Informasi Dasar',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppTheme.darkSlate,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Lengkap',
                              hintText: 'Masukkan nama lengkap Anda',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Nama lengkap tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            enabled: !isGoogleUser,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Alamat Email',
                              hintText: 'email@domain.com',
                              prefixIcon: const Icon(Icons.mail_outline_rounded),
                              fillColor: isGoogleUser
                                  ? const Color(0xFFF1F5F9)
                                  : null,
                            ),
                            validator: (val) {
                              if (isGoogleUser) return null;
                              if (val == null || val.trim().isEmpty) {
                                return 'Email tidak boleh kosong';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(val.trim())) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          if (isGoogleUser) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFBFDBFE),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: Color(0xFF1D4ED8),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Akun terhubung via Google OAuth. Alamat email Anda diverifikasi secara otomatis oleh Google dan tidak dapat diubah.',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 12,
                                        color: const Color(0xFF1E40AF),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Account Metadata Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Tipe Autentikasi',
                          value: isGoogleUser ? 'Google OAuth' : 'Email & Password',
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: Icons.calendar_month_outlined,
                          label: 'Terdaftar Sejak',
                          value: registrationDate,
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _buildInfoRow(
                          icon: Icons.fingerprint_rounded,
                          label: 'ID Pengguna',
                          value: user?.id ?? '-',
                          isId: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit Button
                  authState.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _handleSave,
                          child: const Text('Simpan Perubahan'),
                        ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isId = false,
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
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isId ? 11 : 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkSlate,
          ),
        ),
      ],
    );
  }
}
