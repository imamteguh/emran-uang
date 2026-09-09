import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/currency_helper.dart';
import '../../../domain/entities/expense.dart';
import '../category_icon.dart';

class CategoryMonthlyHeaderCard extends StatelessWidget {
  final ExpenseCategory category;
  final String monthStr;
  final double totalAmount;
  final String currencyCode;

  const CategoryMonthlyHeaderCard({
    super.key,
    required this.category,
    required this.monthStr,
    required this.totalAmount,
    required this.currencyCode,
  });

  String _formatMonthYear(String monthStr) {
    try {
      final parts = monthStr.split('-');
      final year = parts[0];
      final month = int.parse(parts[1]);
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      return '${months[month - 1]} $year';
    } catch (_) {
      return monthStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = CurrencyHelper.getFormatter(currencyCode);
    final catColor = Color(
      int.parse(category.color.replaceFirst('#', '0xFF')),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.roundedBorder,
        boxShadow: AppTheme.softShadow,
        border: Border(
          left: BorderSide(color: catColor, width: 6.0),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: catColor.withAlpha(30),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: CategoryIcon(
              icon: category.icon,
              color: catColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatMonthYear(monthStr),
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    color: AppTheme.darkSlateVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TOTAL SPEND',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlateVariant,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currencyFormatter.format(totalAmount),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkSlate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
