import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';

class BillsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const BillsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 32,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: AppTheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: AppTheme.darkSlateVariant,
            ),
          ),
        ],
      ),
    );
  }
}
