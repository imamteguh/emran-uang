import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';

class AnalyticsSpendingComparisonChart extends StatelessWidget {
  final List<dynamic> chartMonths;
  final List<dynamic> monthsList;
  final int filterIndex;
  final double maxMonthTotal;
  final NumberFormat currencyFormatter;
  final String Function(String) monthYearFormatter;
  final double Function(dynamic) parseDouble;

  const AnalyticsSpendingComparisonChart({
    super.key,
    required this.chartMonths,
    required this.monthsList,
    required this.filterIndex,
    required this.maxMonthTotal,
    required this.currencyFormatter,
    required this.monthYearFormatter,
    required this.parseDouble,
  });

  Widget _buildChartBar(
    String label,
    double value,
    double maxValue,
    bool isCurrent,
  ) {
    const double barHeightMax = 100.0;
    final double percentage = maxValue > 0 ? (value / maxValue) : 0.0;
    final double barHeight = barHeightMax * percentage;

    return Column(
      children: [
        Container(
          width: 32,
          height: barHeight < 8 ? 8 : barHeight,
          decoration: BoxDecoration(
            color: isCurrent ? AppTheme.primary : AppTheme.primaryFixedDim,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(30),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? AppTheme.primary : AppTheme.darkSlateVariant,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.roundedBorder,
        boxShadow: AppTheme.softShadow,
        border: const Border(
          top: BorderSide(
            color: AppTheme.primary,
            width: 3.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Comparison',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: chartMonths.map((m) {
              final label = monthYearFormatter(m['month'] as String);
              final val = parseDouble(m['total']);
              final isActive = monthsList.indexOf(m) == filterIndex;
              return _buildChartBar(
                label,
                val,
                maxMonthTotal,
                isActive,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
