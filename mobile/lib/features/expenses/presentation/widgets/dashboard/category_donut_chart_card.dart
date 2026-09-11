import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../domain/entities/expense.dart';
import '../../bloc/dashboard_state.dart';
import '../category_icon.dart';
import '../../screens/category_monthly_expenses_screen.dart';

class CategoryDonutChartCard extends StatefulWidget {
  final DashboardState provider;
  final ResponsiveHelper responsive;
  final NumberFormat formatter;

  const CategoryDonutChartCard({
    super.key,
    required this.provider,
    required this.responsive,
    required this.formatter,
  });

  @override
  State<CategoryDonutChartCard> createState() => _CategoryDonutChartCardState();
}

class _CategoryDonutChartCardState extends State<CategoryDonutChartCard> {
  String? _selectedCategoryId;

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonthExpenses = widget.provider.expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();

    final double totalMonthSpend = currentMonthExpenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );

    // Group expenses by category
    final Map<String, _CategorySpendItem> categoryMap = {};
    for (final exp in currentMonthExpenses) {
      final cat = exp.category;
      if (categoryMap.containsKey(cat.id)) {
        categoryMap[cat.id]!.amount += exp.amount;
        categoryMap[cat.id]!.count += 1;
      } else {
        categoryMap[cat.id] = _CategorySpendItem(
          category: cat,
          amount: exp.amount,
          count: 1,
        );
      }
    }

    // Sort categories descending by amount
    final sortedCategories = categoryMap.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // Take top 5 categories as requested
    final List<_CategorySpendItem> top6Categories = sortedCategories
        .take(5)
        .toList();

    // Default selected category to top 1 if not set or invalid
    if (_selectedCategoryId == null ||
        !top6Categories.any((c) => c.category.id == _selectedCategoryId)) {
      if (top6Categories.isNotEmpty) {
        _selectedCategoryId = top6Categories.first.category.id;
      } else {
        _selectedCategoryId = null;
      }
    }

    _CategorySpendItem? selectedItem;
    if (_selectedCategoryId != null) {
      for (final item in top6Categories) {
        if (item.category.id == _selectedCategoryId) {
          selectedItem = item;
          break;
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Top 5 Kategori',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: widget.responsive.scaleFont(15),
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (top6Categories.isEmpty || totalMonthSpend <= 0)
            _buildEmptyState()
          else
            // Row: Donut Chart on Left, Legend on Right
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Donut Chart + Center Info
                SizedBox(
                  width: 116,
                  height: 116,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 116,
                        height: 116,
                        child: CustomPaint(
                          painter: _ModernDonutChartPainter(
                            categories: top6Categories,
                            totalSpend: totalMonthSpend,
                            selectedCategoryId: _selectedCategoryId,
                            parseHexColor: _parseHexColor,
                          ),
                        ),
                      ),
                      if (selectedItem != null)
                        _buildCenterInfo(selectedItem, totalMonthSpend)
                      else
                        Text(
                          'Top 5',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Right: Compact Legend List (Name & Percentage)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: top6Categories.map((item) {
                      final category = item.category;
                      final isSelected = category.id == _selectedCategoryId;
                      final color = _parseHexColor(category.color);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: InkWell(
                          onTap: () {
                            if (isSelected) {
                              final monthStr = DateFormat(
                                'yyyy-MM',
                              ).format(now);
                              final currencyCode =
                                  widget.provider.activeWallet?.currency ??
                                  'IDR';
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CategoryMonthlyExpensesScreen(
                                    category: category,
                                    monthStr: monthStr,
                                    walletId:
                                        widget.provider.activeWallet?.id ?? '',
                                    walletName:
                                        widget.provider.activeWallet?.name ??
                                        'Dompet',
                                    currencyCode: currencyCode,
                                  ),
                                ),
                              );
                            } else {
                              setState(() {
                                _selectedCategoryId = category.id;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? color.withValues(alpha: 0.35)
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Category Color Dot
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Category Name
                                Expanded(
                                  child: Text(
                                    category.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: widget.responsive.scaleFont(12),
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppTheme.darkSlate
                                          : AppTheme.darkSlate.withValues(
                                              alpha: 0.85,
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Total Nominal in Rupiah
                                Text(
                                  widget.formatter.format(item.amount),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: widget.responsive.scaleFont(11),
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? color
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCenterInfo(_CategorySpendItem item, double totalMonthSpend) {
    final color = _parseHexColor(item.category.color);
    final pct = totalMonthSpend > 0
        ? (item.amount / totalMonthSpend) * 100
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CategoryIcon(icon: item.category.icon, color: color, size: 22),
        const SizedBox(height: 2),
        Container(
          constraints: const BoxConstraints(maxWidth: 90),
          child: Text(
            item.category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        Text(
          '${pct.toStringAsFixed(0)}%',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkSlate,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.pie_chart_outline_rounded,
            size: 40,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 10),
          Text(
            'Belum ada pengeluaran bulan ini',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Transaksi yang dicatat akan muncul dalam grafik kategori',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySpendItem {
  final ExpenseCategory category;
  double amount;
  int count;

  _CategorySpendItem({
    required this.category,
    required this.amount,
    required this.count,
  });
}

class _ModernDonutChartPainter extends CustomPainter {
  final List<_CategorySpendItem> categories;
  final double totalSpend;
  final String? selectedCategoryId;
  final Color Function(String) parseHexColor;

  _ModernDonutChartPainter({
    required this.categories,
    required this.totalSpend,
    required this.selectedCategoryId,
    required this.parseHexColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalSpend <= 0 || categories.isEmpty) {
      final paint = Paint()
        ..color = const Color(0xFFF1F5F9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14;
      canvas.drawCircle(size.center(Offset.zero), size.width / 2 - 10, paint);
      return;
    }

    final double radius = size.width / 2;
    final Rect rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius - 10,
    );

    double startAngle = -math.pi / 2;
    const double gapAngle = 0.04; // Small gap between slices

    final int sliceCount = categories.where((c) => c.amount > 0).length;
    final double totalGap = sliceCount > 1 ? gapAngle * sliceCount : 0.0;
    final double availableAngle = (2 * math.pi) - totalGap;

    for (final item in categories) {
      if (item.amount <= 0) continue;
      final double fraction = item.amount / totalSpend;
      final double sweepAngle = fraction * availableAngle;

      final color = parseHexColor(item.category.color);
      final isSelected = selectedCategoryId == item.category.id;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 18.0 : 13.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle + (sliceCount > 1 ? gapAngle : 0.0);
    }
  }

  @override
  bool shouldRepaint(covariant _ModernDonutChartPainter oldDelegate) {
    return oldDelegate.categories != categories ||
        oldDelegate.totalSpend != totalSpend ||
        oldDelegate.selectedCategoryId != selectedCategoryId;
  }
}
