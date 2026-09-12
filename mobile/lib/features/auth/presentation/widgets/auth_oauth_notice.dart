import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class AuthOAuthNotice extends StatelessWidget {
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final bool isCompact;

  const AuthOAuthNotice({
    super.key,
    this.title = 'Akun Google Terhubung',
    required this.description,
    this.buttonText,
    this.onButtonPressed,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF1D4ED8),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                description,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  color: const Color(0xFF1E40AF),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/icons/google.png',
              width: 32,
              height: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: AppTheme.darkSlate,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              color: AppTheme.darkSlateVariant,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: onButtonPressed,
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                ),
                child: Text(
                  buttonText!,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.darkSlate,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
