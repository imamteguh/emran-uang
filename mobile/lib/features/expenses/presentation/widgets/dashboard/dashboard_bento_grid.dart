import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../bloc/dashboard_state.dart';
import '../category_icon.dart';

class DashboardBentoGrid extends StatelessWidget {
  final DashboardState provider;
  final ResponsiveHelper responsive;
  final NumberFormat formatter;

  const DashboardBentoGrid({
    super.key,
    required this.provider,
    required this.responsive,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final double monthlyBudgetLimit = provider.monthlyBudgetLimit;
    final double monthlySavings = monthlyBudgetLimit > 0
        ? (monthlyBudgetLimit - provider.monthlySpend).clamp(
            0.0,
            double.infinity,
          )
        : 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.35,
      children: [
        // Monthly Savings Block
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.savings_outlined, color: AppTheme.secondary),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Savings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondary.withAlpha(200),
                    ),
                  ),
                  Text(
                    formatter.format(monthlySavings),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: responsive.scaleFont(16),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Top Category Block
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.tertiaryFixed,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CategoryIcon(
                icon: provider.topCategoryIcon,
                color: AppTheme.tertiary,
                size: 28,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Category',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.tertiary.withAlpha(200),
                    ),
                  ),
                  Text(
                    provider.topCategory,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: responsive.scaleFont(16),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.tertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
