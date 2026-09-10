import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../bloc/dashboard_state.dart';
import 'set_monthly_budget_dialog.dart';

class MonthlyBudgetCard extends StatelessWidget {
  final DashboardState provider;
  final ResponsiveHelper responsive;
  final NumberFormat formatter;

  const MonthlyBudgetCard({
    super.key,
    required this.provider,
    required this.responsive,
    required this.formatter,
  });

  void _showSetMonthlyBudgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SetMonthlyBudgetDialog(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double budgetLimit = provider.monthlyBudgetLimit;
    final double monthlySpend = provider.monthlySpend;
    final double budgetPercent = provider.monthlyBudgetPercent;
    final double remaining = provider.monthlyBudgetRemaining;
    final bool isOver = provider.isOverMonthlyBudget;
    final bool isNear = provider.isNearMonthlyBudget;

    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(now);

    // Dynamic status colors
    final Color statusColor = isOver
        ? AppTheme.error
        : (isNear ? AppTheme.tertiary : AppTheme.secondary);
    final Color statusBg = isOver
        ? AppTheme.errorContainer
        : (isNear ? AppTheme.tertiaryFixed : AppTheme.secondaryContainer);
    final String statusLabel = isOver
        ? 'Overbudget'
        : (isNear ? 'Mendekati Batas' : 'Aman');

    return Container(
      decoration: BoxDecoration(boxShadow: AppTheme.cardShadow),
      child: ClipRRect(
        borderRadius: AppTheme.radiusDefault,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppTheme.primary, width: 3.5),
            ),
          ),
          child: Stack(
            children: [
              // Subtle background ambient circle
              Positioned(
                bottom: -40,
                right: -40,
                width: 160,
                height: 160,
                child: Container(
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(10),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Title, Month, & Edit button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                size: 18,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ANGGARAN BULANAN',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: responsive.scaleFont(11),
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkSlateVariant,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                Text(
                                  monthName,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: responsive.scaleFont(12),
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Edit / Set button & Status chip
                        Row(
                          children: [
                            if (budgetLimit > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            InkWell(
                              onTap: () => _showSetMonthlyBudgetDialog(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (budgetLimit <= 0) ...[
                      // Empty state: No budget set yet
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.savings_outlined,
                              color: AppTheme.primary,
                              size: 32,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Atur Anggaran Bulanan',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.darkSlate,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Kendalikan pengeluaran bulanan Anda secara terukur.',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 12,
                                      color: AppTheme.darkSlateVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  _showSetMonthlyBudgetDialog(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size(60, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Atur',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Main metrics: Spending vs Limit
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: formatter.format(monthlySpend),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: responsive.scaleFont(22),
                                    fontWeight: FontWeight.w800,
                                    color: isOver
                                        ? AppTheme.error
                                        : AppTheme.darkSlate,
                                  ),
                                ),
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: '/ ${formatter.format(budgetLimit)}',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: responsive.scaleFont(13),
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.darkSlateVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${(provider.rawMonthlyBudgetPercent * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: responsive.scaleFont(15),
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Progress Bar
                      Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: budgetPercent,
                          child: Container(
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Micro-metrics summary row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // Sisa Anggaran
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isOver ? 'Kelebihan' : 'Sisa Anggaran',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 10,
                                      color: AppTheme.darkSlateVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatter.format(remaining.abs()),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: responsive.scaleFont(12),
                                      fontWeight: FontWeight.bold,
                                      color: isOver
                                          ? AppTheme.error
                                          : AppTheme.secondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              height: 24,
                              width: 1,
                              color: AppTheme.outlineVariant.withAlpha(100),
                            ),

                            // Sisa Hari
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sisa Waktu',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 10,
                                        color: AppTheme.darkSlateVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${provider.daysRemainingInMonth} hari lagi',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: responsive.scaleFont(12),
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.darkSlate,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Container(
                              height: 24,
                              width: 1,
                              color: AppTheme.outlineVariant.withAlpha(100),
                            ),

                            // Rekomendasi Harian
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Batas Harian',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 10,
                                        color: AppTheme.darkSlateVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      provider.dailyRecommendedSpending > 0
                                          ? formatter.format(
                                              provider
                                                  .dailyRecommendedSpending,
                                            )
                                          : 'Rp 0',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: responsive.scaleFont(12),
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
