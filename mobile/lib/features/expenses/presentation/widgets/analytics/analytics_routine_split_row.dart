import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/currency_helper.dart';

class AnalyticsRoutineSplitRow extends StatelessWidget {
  final double routineSpend;
  final double nonRoutineSpend;
  final double routinePercent;
  final double nonRoutinePercent;
  final String currencyCode;

  const AnalyticsRoutineSplitRow({
    super.key,
    required this.routineSpend,
    required this.nonRoutineSpend,
    required this.routinePercent,
    required this.nonRoutinePercent,
    required this.currencyCode,
  });

  Widget _buildSplitCard(
    String label,
    double amount,
    String desc,
    IconData icon,
    Color accentColor,
    double percentage,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accentColor, width: 4.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyHelper.format(amount, currencyCode),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSplitCard(
            'Routine',
            routineSpend,
            'Fixed subscriptions & bills',
            Icons.repeat,
            AppTheme.primary,
            routinePercent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSplitCard(
            'Non-Routine',
            nonRoutineSpend,
            'Daily dining out & travel',
            Icons.rocket_launch,
            AppTheme.tertiary,
            nonRoutinePercent,
          ),
        ),
      ],
    );
  }
}
