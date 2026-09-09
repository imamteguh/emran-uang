import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';

class AnalyticsOverviewCard extends StatelessWidget {
  final double totalSpend;
  final bool hasComparison;
  final String direction;
  final double changePercent;
  final String prevMonthLabel;
  final NumberFormat currencyFormatter;
  final ResponsiveHelper responsive;

  const AnalyticsOverviewCard({
    super.key,
    required this.totalSpend,
    required this.hasComparison,
    required this.direction,
    required this.changePercent,
    required this.prevMonthLabel,
    required this.currencyFormatter,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: AppTheme.roundedBorder,
        boxShadow: AppTheme.softShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              Icons.analytics,
              size: 130,
              color: Colors.white.withAlpha(25),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Spending',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormatter.format(totalSpend),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: responsive.scaleFont(30),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                if (hasComparison)
                  Row(
                    children: [
                      Icon(
                        direction == 'decreased'
                            ? Icons.trending_down
                            : Icons.trending_up,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${changePercent.abs().toStringAsFixed(1)}% ${direction == 'decreased' ? 'less' : 'more'} than $prevMonthLabel',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                else
                  const Row(
                    children: [
                      Icon(
                        Icons.trending_flat,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'No comparison data available',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
