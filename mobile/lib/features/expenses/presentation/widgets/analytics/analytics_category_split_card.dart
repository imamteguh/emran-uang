import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/expense.dart';
import '../category_icon.dart';

class AnalyticsCategorySplitCard extends StatelessWidget {
  final Map<String, dynamic> activeMonthData;
  final double activeMonthTotal;
  final List<dynamic> activeCategories;
  final List<Map<String, dynamic>> displayedCategories;
  final String? selectedCategoryId;
  final ExpenseCategory? selectedCategory;
  final double selectedCategoryTotal;
  final double selectedCategoryPercentage;
  final String currencyCode;
  final NumberFormat currencyFormatter;
  final ValueChanged<String?> onSelectCategory;
  final void Function(ExpenseCategory, String, String)
  onNavigateToCategoryDetails;
  final Color Function(String) parseHexColor;

  const AnalyticsCategorySplitCard({
    super.key,
    required this.activeMonthData,
    required this.activeMonthTotal,
    required this.activeCategories,
    required this.displayedCategories,
    required this.selectedCategoryId,
    required this.selectedCategory,
    required this.selectedCategoryTotal,
    required this.selectedCategoryPercentage,
    required this.currencyCode,
    required this.currencyFormatter,
    required this.onSelectCategory,
    required this.onNavigateToCategoryDetails,
    required this.parseHexColor,
  });

  @override
  Widget build(BuildContext context) {
    final String selectedCatName = selectedCategory?.name ?? 'None';
    final String selectedCatIcon = selectedCategory?.icon ?? 'category';
    final String selectedCatColor = selectedCategory?.color ?? '#BDC3C7';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.roundedBorder,
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Split',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlate,
                ),
              ),
              const Icon(
                Icons.pie_chart_outline,
                color: AppTheme.darkSlateVariant,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Donut Chart
              GestureDetector(
                onTap: () {
                  if (selectedCategoryTotal > 0 && selectedCategory != null) {
                    final monthStr = activeMonthData['month'] as String;
                    onNavigateToCategoryDetails(
                      selectedCategory!,
                      monthStr,
                      currencyCode,
                    );
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: CustomPaint(
                        painter: DonutChartPainter(
                          categories: activeCategories,
                          totalSpend: activeMonthTotal,
                          selectedCategoryId: selectedCategoryId,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CategoryIcon(
                          icon: selectedCatIcon,
                          color: parseHexColor(selectedCatColor),
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 75),
                          child: Text(
                            selectedCatName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: parseHexColor(selectedCatColor),
                            ),
                          ),
                        ),
                        Text(
                          '${(selectedCategoryPercentage * 100).round()}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Legend List (Displaying All Categories)
              Expanded(
                child: displayedCategories.isEmpty
                    ? Center(
                        child: Text(
                          'No categories',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: AppTheme.darkSlateVariant,
                          ),
                        ),
                      )
                    : Column(
                        children: displayedCategories.map((item) {
                          final categoryMap = item['category'] as Map;
                          final category = ExpenseCategory.fromJson(
                            categoryMap,
                          );
                          final name = category.name;
                          final total = item['total'] as double;
                          final colorStr = category.color;
                          final color = parseHexColor(colorStr);
                          final isSelected = selectedCategoryId == category.id;
                          final monthStr = activeMonthData['month'] as String;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: InkWell(
                              onTap: () {
                                if (isSelected) {
                                  if (total > 0) {
                                    onNavigateToCategoryDetails(
                                      category,
                                      monthStr,
                                      currencyCode,
                                    );
                                  }
                                } else {
                                  onSelectCategory(category.id);
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? color.withValues(alpha: 0.4)
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.beVietnamPro(
                                                fontSize: 11,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? AppTheme.darkSlate
                                                    : AppTheme.darkSlate
                                                        .withValues(alpha: 0.8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          currencyFormatter.format(total),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? AppTheme.darkSlate
                                                : AppTheme.darkSlate.withValues(
                                                    alpha: 0.8,
                                                  ),
                                          ),
                                        ),
                                        if (isSelected && total > 0) ...[
                                          const SizedBox(width: 2),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 14,
                                            color: color,
                                          ),
                                        ],
                                      ],
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
}

class DonutChartPainter extends CustomPainter {
  final List<dynamic> categories;
  final double totalSpend;
  final String? selectedCategoryId;

  DonutChartPainter({
    required this.categories,
    required this.totalSpend,
    required this.selectedCategoryId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalSpend <= 0 || categories.isEmpty) {
      final paint = Paint()
        ..color = const Color(0xFFF1F5F9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10;
      canvas.drawCircle(size.center(Offset.zero), size.width / 2 - 5, paint);
      return;
    }

    final double radius = size.width / 2;
    final Rect rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius - 8,
    );
    double startAngle = -3.141592653589793 / 2; // -pi/2

    for (var cat in categories) {
      final double amount = _parseDouble(cat['total']);
      if (amount <= 0) continue;
      final double sweepAngle = (amount / totalSpend) * 2 * 3.141592653589793;

      final category = cat['category'] as Map;
      final colorStr = category['color'] as String? ?? '#BDC3C7';
      Color color = _parseHexColor(colorStr);

      final isSelected = selectedCategoryId == category['id'];

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 16.0 : 10.0
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.blueGrey;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.categories != categories ||
        oldDelegate.totalSpend != totalSpend ||
        oldDelegate.selectedCategoryId != selectedCategoryId;
  }
}
