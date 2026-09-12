import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../bloc/dashboard_state.dart';
import '../category_icon.dart';
import 'bills_empty_state.dart';
import 'bills_summary_data.dart';
import 'budget_form_sheets.dart';

class BudgetManagementView extends StatelessWidget {
  final DashboardState provider;
  final BillsSummaryData? summary;
  final NumberFormat currencyFormatter;
  final ResponsiveHelper responsive;

  const BudgetManagementView({
    super.key,
    required this.provider,
    this.summary,
    required this.currencyFormatter,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    final categoryStatuses = provider.categoryBudgetStatuses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── DAFTAR ANGGARAN PER KATEGORI ──────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Anggaran per Kategori',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: responsive.scaleFont(18),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkSlate,
                  ),
                ),
                if (categoryStatuses.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${categoryStatuses.length}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            TextButton.icon(
              onPressed: () => BudgetFormSheets.showSetCategoryBudgetSheet(
                context: context,
                provider: provider,
              ),
              icon: const Icon(Icons.add_rounded, size: 18, color: AppTheme.primary),
              label: Text(
                'Tambah',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (categoryStatuses.isEmpty) ...[
          BillsEmptyState(
            icon: Icons.pie_chart_outline_rounded,
            title: 'Belum Ada Anggaran Kategori',
            description:
                'Tetapkan batas pengeluaran untuk kategori tertentu (misal: Makanan, Belanja, Transportasi) agar alokasi dana lebih rapi.',
            actionLabel: 'Tambah Anggaran Kategori',
            onAction: () => BudgetFormSheets.showSetCategoryBudgetSheet(
              context: context,
              provider: provider,
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoryStatuses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) {
              final item = categoryStatuses[index];
              return _buildCategoryBudgetItem(
                context: context,
                item: item,
                currencyFormatter: currencyFormatter,
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryBudgetItem({
    required BuildContext context,
    required CategoryBudgetStatus item,
    required NumberFormat currencyFormatter,
  }) {
    final catColorStr = item.category.color;
    final catColor = Color(
      int.parse(catColorStr.replaceFirst('#', '0xFF')),
    );
    final isOver = item.isOver;
    final isNear = item.isNear;

    final Color statusColor = isOver
        ? AppTheme.error
        : (isNear ? const Color(0xFFD97706) : const Color(0xFF059669));
    final Color statusBg = isOver
        ? const Color(0xFFFEF2F2)
        : (isNear ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5));
    final String statusText = isOver
        ? 'Overbudget'
        : (isNear ? 'Mendekati' : 'Aman');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: CategoryIcon(
                  icon: item.category.icon,
                  color: catColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Batas: ${currencyFormatter.format(item.budgetLimit)}',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: AppTheme.darkSlateVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppTheme.darkSlateVariant,
                  size: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (val) {
                  if (val == 'edit') {
                    BudgetFormSheets.showSetCategoryBudgetSheet(
                      context: context,
                      provider: provider,
                      categoryId: item.category.id,
                    );
                  } else if (val == 'delete') {
                    BudgetFormSheets.showConfirmDeleteCategoryBudgetSheet(
                      context: context,
                      category: item.category,
                      provider: provider,
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                        const SizedBox(width: 10),
                        Text(
                          'Ubah Anggaran',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.error),
                        const SizedBox(width: 10),
                        Text(
                          'Hapus Anggaran',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: item.percent,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 10),

          // Detail Spend & Remaining
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terpakai: ${currencyFormatter.format(item.monthlySpend)}',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkSlate,
                ),
              ),
              Text(
                isOver
                    ? 'Lewat: ${currencyFormatter.format(item.remaining.abs())}'
                    : 'Sisa: ${currencyFormatter.format(item.remaining)}',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isOver ? AppTheme.error : const Color(0xFF15803D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
