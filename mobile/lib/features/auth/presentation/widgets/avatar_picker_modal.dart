import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../expenses/presentation/widgets/user_avatar.dart';

class AvatarPickerModal extends StatefulWidget {
  final String? initialAvatar;
  final ValueChanged<String?> onAvatarSelected;

  const AvatarPickerModal({
    super.key,
    this.initialAvatar,
    required this.onAvatarSelected,
  });

  static Future<void> show({
    required BuildContext context,
    String? initialAvatar,
    required ValueChanged<String?> onAvatarSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AvatarPickerModal(
        initialAvatar: initialAvatar,
        onAvatarSelected: onAvatarSelected,
      ),
    );
  }

  @override
  State<AvatarPickerModal> createState() => _AvatarPickerModalState();
}

class _AvatarPickerModalState extends State<AvatarPickerModal> {
  late String? _currentAvatar;
  late final TextEditingController _urlController;
  final ImagePicker _picker = ImagePicker();

  static const List<String> _avatarPresets = [
    '🦊', '🐱', '🦁', '🐯', '🐨', '🐼',
    '🐰', '🐶', '🦄', '🐸', '🐙', '🐵',
    '💼', '💡', '🔥', '✨', '🍀', '🎯',
    '🚗', '✈️', '🎮', '🏀', '🍕', '☕',
  ];

  @override
  void initState() {
    super.initState();
    _currentAvatar = widget.initialAvatar;
    final isHttp = _currentAvatar != null && _currentAvatar!.startsWith('http');
    _urlController = TextEditingController(text: isHttp ? _currentAvatar : '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _currentAvatar = base64Image;
        });
        widget.onAvatarSelected(base64Image);
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Foto Profil',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pilih metode untuk mengubah avatar Anda',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: AppTheme.darkSlateVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                UserAvatar(
                  avatarUrl: _currentAvatar,
                  displayName: 'U',
                  size: 48,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Camera and Gallery Action Buttons
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickImage(ImageSource.gallery),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryFixed.withAlpha(120),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.photo_library_rounded,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Galeri Foto',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
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
                    onTap: () => _pickImage(ImageSource.camera),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryContainer.withAlpha(140),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: AppTheme.secondary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ambil Foto',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
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
            const SizedBox(height: 24),

            // Emoji Character Presets
            Text(
              'Preset Karakter Avatar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: GridView.builder(
                itemCount: _avatarPresets.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final emoji = _avatarPresets[index];
                  final isSelected = _currentAvatar == emoji;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentAvatar = emoji;
                      });
                      widget.onAvatarSelected(emoji);
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
                          width: isSelected ? 2.5 : 1,
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

            // Direct URL Field
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Atau Masukkan URL Gambar Web',
                hintText: 'https://example.com/avatar.jpg',
                prefixIcon: const Icon(Icons.link_rounded),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onChanged: (val) {
                final trimmed = val.trim();
                setState(() {
                  _currentAvatar = trimmed.isEmpty ? null : trimmed;
                });
                widget.onAvatarSelected(_currentAvatar);
              },
            ),
            const SizedBox(height: 24),

            // Bottom Confirm Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  backgroundColor: AppTheme.primary,
                ),
                child: Text(
                  'Selesai',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
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
