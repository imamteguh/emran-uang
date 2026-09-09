import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';

class BillsSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAdd;
  final ResponsiveHelper responsive;

  const BillsSectionHeader({
    super.key,
    required this.title,
    this.onAdd,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    if (onAdd != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: responsive.scaleFont(18),
              fontWeight: FontWeight.bold,
              color: AppTheme.darkSlate,
            ),
          ),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(
              Icons.add,
              size: 16,
              color: AppTheme.primary,
            ),
            label: Text(
              'Tambah',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: responsive.scaleFont(18),
        fontWeight: FontWeight.bold,
        color: AppTheme.darkSlate,
      ),
    );
  }
}
