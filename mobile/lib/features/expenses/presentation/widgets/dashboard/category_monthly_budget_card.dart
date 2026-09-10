import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../bloc/dashboard_state.dart';
import '../category_icon.dart';
import 'set_category_budget_dialog.dart';

class CategoryMonthlyBudgetCard extends StatelessWidget {
  final DashboardState provider;
  final ResponsiveHelper responsive;
  final NumberFormat formatter;

  const CategoryMonthlyBudgetCard({
    super.key,
    required this.provider,
    required this.responsive,
    required this.formatter,
  });

  void _showSetCategoryBudgetDialog(BuildContext context, [String? categoryId]) {
    showDialog(
      context: context,
      builder: (context) => SetCategoryBudgetDialog(
        provider: provider,
        initialCategoryId: categoryId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statuses = provider.categoryBudgetStatuses;
    final bool hasBudgets = statuses.isNotEmpty;

    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(now);

    final double totalLimit = provider.totalCategoryBudgetLimit;
    final double totalSpend = provider.totalCategoryBudgetSpend;
    final double totalPercent = provider.totalCategoryBudgetPercent;
    final double totalRawPercent = provider.rawTotalCategoryBudgetPercent;
    final double totalRemaining = provider.totalCategoryBudgetRemaining;
    final bool isTotalOver = provider.isOverTotalCategoryBudget;
    final bool isTotalNear = provider.isNearTotalCategoryBudget;

    final Color totalStatusColor = isTotalOver
        ? AppTheme.error
        : (isTotalNear ? AppTheme.tertiary : AppTheme.secondary);
    final Color totalStatusBg = isTotalOver
        ? AppTheme.errorContainer
        : (isTotalNear ? AppTheme.tertiaryFixed : AppTheme.secondaryContainer);
    final String totalStatusLabel = isTotalOver
        ? 'Overbudget'
        : (isTotalNear ? 'Mendekati Batas' : 'Aman');

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
              // Ambient background decoration
              Positioned(
                bottom: -40,
                right: -40,
                width: 160,
                height: 160,
                child: Container(
                  decoration: BoxDecoration(
                    color: (hasBudgets ? totalStatusColor : AppTheme.primary)
                        .withAlpha(10),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Title, Month, & Edit / Add button
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
                                Icons.pie_chart_rounded,
                                size: 18,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ANGGARAN PER KATEGORI',
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

                        // Status badge & Add/Manage button
                        Row(
                          children: [
                            if (hasBudgets) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: totalStatusBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  totalStatusLabel,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: totalStatusColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            InkWell(
                              onTap: () => _showSetCategoryBudgetDialog(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.add_rounded,
                                      size: 15,
                                      color: AppTheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Atur',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (!hasBudgets) ...[
                      // Empty state: No category budget set yet
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.outlineVariant.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.category_outlined,
                                color: AppTheme.primary,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Atur Anggaran per Kategori',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.darkSlate,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Tentukan batas pengeluaran untuk Makanan, Transportasi, Belanja, dan lainnya.',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 12,
                                      color: AppTheme.darkSlateVariant,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  _showSetCategoryBudgetDialog(context),
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
                      // Overall Category Spending Summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: formatter.format(totalSpend),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: responsive.scaleFont(20),
                                    fontWeight: FontWeight.w800,
                                    color: isTotalOver
                                        ? AppTheme.error
                                        : AppTheme.darkSlate,
                                  ),
                                ),
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: '/ ${formatter.format(totalLimit)}',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: responsive.scaleFont(12),
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.darkSlateVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${(totalRawPercent * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: responsive.scaleFont(15),
                              fontWeight: FontWeight.bold,
                              color: totalStatusColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Overall Progress Bar
                      Container(
                        height: 7,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: totalPercent,
                          child: Container(
                            decoration: BoxDecoration(
                              color: totalStatusColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Micro remaining text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isTotalOver
                                ? 'Kelebihan ${formatter.format(totalSpend - totalLimit)}'
                                : 'Sisa Total: ${formatter.format(totalRemaining)}',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isTotalOver
                                  ? AppTheme.error
                                  : AppTheme.secondary,
                            ),
                          ),
                          Text(
                            '${statuses.length} Kategori Diatur',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              color: AppTheme.darkSlateVariant,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // List of Category Budgets
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: statuses.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = statuses[index];
                          return _buildCategoryBudgetItem(context, item);
                        },
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

  Widget _buildCategoryBudgetItem(
    BuildContext context,
    CategoryBudgetStatus item,
  ) {
    final catColor = AppTheme.parseHexColor(item.category.color);
    final Color itemStatusColor = item.isOver
        ? AppTheme.error
        : (item.isNear ? AppTheme.tertiary : AppTheme.secondary);
    final Color itemStatusBg = item.isOver
        ? AppTheme.errorContainer
        : (item.isNear ? AppTheme.tertiaryFixed : AppTheme.secondaryContainer);

    return InkWell(
      onTap: () => _showSetCategoryBudgetDialog(context, item.category.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.outlineVariant.withAlpha(50),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Category Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: catColor.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CategoryIcon(
                      icon: item.category.icon,
                      color: catColor,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Amounts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.category.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkSlate,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: formatter.format(item.monthlySpend),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: item.isOver
                                    ? AppTheme.error
                                    : AppTheme.darkSlate,
                              ),
                            ),
                            TextSpan(
                              text: ' / ${formatter.format(item.budgetLimit)}',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                color: AppTheme.darkSlateVariant,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Percentage Badge & Edit
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: itemStatusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.isOver
                            ? 'Over ${(item.rawPercent * 100).toStringAsFixed(0)}%'
                            : '${(item.rawPercent * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: itemStatusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: AppTheme.darkSlateVariant.withAlpha(150),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Progress Bar & Remaining Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: item.percent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: itemStatusColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  item.isOver
                      ? '-${formatter.format(item.monthlySpend - item.budgetLimit)}'
                      : 'Sisa ${formatter.format(item.remaining)}',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: item.isOver ? AppTheme.error : AppTheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
