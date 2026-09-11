import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';

class ExpenseRoutineToggle extends StatelessWidget {
  final bool isRoutine;
  final ValueChanged<bool> onChanged;

  const ExpenseRoutineToggle({
    super.key,
    required this.isRoutine,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.roundedBorder,
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isRoutine
                  ? AppTheme.primary.withAlpha(20)
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.autorenew_rounded,
              color: isRoutine ? AppTheme.primary : AppTheme.darkSlateVariant,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengeluaran Rutin',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tandai sebagai pengeluaran berulang bulanan',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: AppTheme.darkSlateVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isRoutine,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}
