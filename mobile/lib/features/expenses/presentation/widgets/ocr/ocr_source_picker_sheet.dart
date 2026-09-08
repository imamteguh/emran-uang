import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_theme.dart';

/// Modal bottom sheet for choosing between Camera, Gallery, or Manual Input.
class OcrSourcePickerSheet extends StatelessWidget {
  final void Function(ImageSource source) onSourceSelected;
  final VoidCallback? onManualInput;

  const OcrSourcePickerSheet({
    super.key,
    required this.onSourceSelected,
    this.onManualInput,
  });

  static Future<void> show({
    required BuildContext context,
    required void Function(ImageSource source) onSourceSelected,
    VoidCallback? onManualInput,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OcrSourcePickerSheet(
        onSourceSelected: (source) {
          Navigator.of(ctx).pop();
          Future.delayed(const Duration(milliseconds: 150), () {
            onSourceSelected(source);
          });
        },
        onManualInput: onManualInput != null
            ? () {
                Navigator.of(ctx).pop();
                Future.delayed(const Duration(milliseconds: 150), () {
                  onManualInput();
                });
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Scan Receipt',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a source for your receipt image or input manually',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: AppTheme.darkSlateVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _SourceOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      subtitle: 'Take a photo',
                      color: AppTheme.primary,
                      onTap: () => onSourceSelected(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SourceOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      subtitle: 'Choose photo',
                      color: AppTheme.secondary,
                      onTap: () => onSourceSelected(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              if (onManualInput != null) ...[
                const SizedBox(height: 16),
                InkWell(
                  onTap: onManualInput,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: AppTheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manual Input',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.darkSlate,
                                ),
                              ),
                              Text(
                                'Type transaction details without receipt',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 11,
                                  color: AppTheme.darkSlateVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.darkSlateVariant,
                          size: 20,
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
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(40), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                color: AppTheme.darkSlateVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
