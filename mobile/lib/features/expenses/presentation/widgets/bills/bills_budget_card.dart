import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../bloc/dashboard_state.dart';
import 'budget_form_sheets.dart';
import 'bills_summary_data.dart';

class BillsBudgetCard extends StatelessWidget {
  final DashboardState dashboardState;
  final BillsSummaryData summary;
  final NumberFormat currencyFormatter;
  final ResponsiveHelper responsive;

  const BillsBudgetCard({
    super.key,
    required this.dashboardState,
    required this.summary,
    required this.currencyFormatter,
    required this.responsive,
  });

  void _openSetBudgetDialog(BuildContext context) {
    BudgetFormSheets.showSetMonthlyBudgetSheet(
      context: context,
      provider: dashboardState,
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetLimit = dashboardState.monthlyBudgetLimit;
    final hasBudget = budgetLimit > 0;
    final totalBills = summary.totalMonthlyOutflow;
    final double billsRatio = hasBudget ? (totalBills / budgetLimit) : 0.0;
    final double progress = billsRatio.clamp(0.0, 1.0);
    final double remainingAfterBills = budgetLimit - totalBills;

    final isOver = hasBudget && totalBills > budgetLimit;
    final isNear = hasBudget && !isOver && billsRatio >= 0.70;

    final Color statusColor = isOver
        ? AppTheme.error
        : (isNear ? const Color(0xFFD97706) : const Color(0xFF059669));
    final Color statusBg = isOver
        ? const Color(0xFFFEF2F2)
        : (isNear ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5));
    final String statusLabel = isOver
        ? 'Melebihi Anggaran'
        : (isNear ? 'Perlu Perhatian' : 'Aman');
    final IconData statusIcon = isOver
        ? Icons.warning_amber_rounded
        : (isNear ? Icons.info_outline_rounded : Icons.verified_rounded);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title and Edit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pie_chart_outline_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alokasi Anggaran Tagihan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      Text(
                        'Porsi tagihan rutin dari anggaran bulanan',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          color: AppTheme.darkSlateVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () => _openSetBudgetDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasBudget ? Icons.tune_rounded : Icons.add_rounded,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasBudget ? 'Ubah' : 'Atur',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (!hasBudget) ...[
            // Empty Budget State Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFFD97706),
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batas Anggaran Belum Ditetapkan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tetapkan anggaran bulanan dompet untuk mengontrol porsi tagihan rutin Anda.',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            color: AppTheme.darkSlateVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _openSetBudgetDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Pasang',
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
            // Progress Bar & Percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(billsRatio * 100).toStringAsFixed(1)}% teralokasi',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkSlateVariant,
                      ),
                    ),
                  ],
                ),
                Text(
                  currencyFormatter.format(budgetLimit),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkSlate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Visual Progress Track
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 14),

            // Bento Sub-metrics (Tagihan Bulanan & Sisa Anggaran)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL KOMITMEN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: AppTheme.darkSlateVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormatter.format(totalBills),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkSlate,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isOver
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOver ? 'DEFISIT ANGGARAN' : 'SISA ANGGARAN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: isOver
                                ? AppTheme.error
                                : const Color(0xFF15803D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormatter.format(remainingAfterBills.abs()),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isOver
                                ? AppTheme.error
                                : const Color(0xFF15803D),
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
          ],
        ],
      ),
    );
  }
}
