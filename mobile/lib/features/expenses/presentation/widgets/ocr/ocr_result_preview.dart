import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/currency_helper.dart';
import '../../../domain/entities/expense.dart';
import '../category_icon.dart';
import 'ocr_result_card.dart';
import 'ocr_category_picker_sheet.dart';

/// Full preview of the extracted OCR receipt data (Amount, Description, Category, Date, Tips).
class OcrResultPreview extends StatelessWidget {
  final double? amount;
  final String? description;
  final ExpenseCategory? category;
  final String? rawSuggestion;
  final DateTime? date;
  final String currencyCode;
  final String currencySymbol;
  final List<ExpenseCategory> availableCategories;
  final ValueChanged<ExpenseCategory> onCategoryChanged;

  const OcrResultPreview({
    super.key,
    required this.amount,
    required this.description,
    required this.category,
    required this.rawSuggestion,
    required this.date,
    required this.currencyCode,
    required this.currencySymbol,
    required this.availableCategories,
    required this.onCategoryChanged,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Not detected (will use today)';
    try {
      return DateFormat('EEEE, d MMMM yyyy • HH:mm').format(dt);
    } catch (_) {
      try {
        return DateFormat('d MMM yyyy • HH:mm').format(dt);
      } catch (_) {
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }
  }

  String _formatAmount(double? amt, NumberFormat formatter) {
    if (amt == null) return '0';
    try {
      final formatted = formatter.format(amt);
      final symbol = formatter.currencySymbol;
      return formatted
          .replaceFirst(symbol.trim(), '')
          .replaceFirst(symbol, '')
          .trim();
    } catch (_) {
      return amt.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = CurrencyHelper.getFormatter(currencyCode);

    return Column(
      children: [
        // ── Success header ──
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.secondary.withAlpha(15),
                AppTheme.primary.withAlpha(10),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppTheme.secondary.withAlpha(40), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Extraction Complete',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    Text(
                      'Review the details below and confirm',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        color: AppTheme.darkSlateVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Amount Card ──
        OcrResultCard(
          icon: Icons.payments_rounded,
          iconColor: AppTheme.primary,
          label: 'AMOUNT',
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  currencySymbol,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _formatAmount(amount, formatter),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Description Card ──
        OcrResultCard(
          icon: Icons.description_rounded,
          iconColor: AppTheme.tertiary,
          label: 'DESCRIPTION',
          child: Text(
            description ?? 'No description',
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              color: description != null ? AppTheme.darkSlate : Colors.grey,
              fontStyle:
                  description != null ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),

        // ── Category Card ──
        OcrResultCard(
          icon: Icons.category_rounded,
          iconColor: AppTheme.secondary,
          label: 'CATEGORY',
          trailing: _buildCategorySelectorButton(context),
          child: Row(
            children: [
              if (category != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.parseHexColor(category!.color).withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CategoryIcon(
                      icon: category!.icon,
                      color: AppTheme.parseHexColor(category!.color),
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category!.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.darkSlate,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Text(
                    rawSuggestion ?? 'Tap to select category',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Date Card ──
        OcrResultCard(
          icon: Icons.calendar_today_rounded,
          iconColor: AppTheme.tertiary,
          label: 'DATE',
          child: Text(
            _formatDate(date),
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              color: date != null ? AppTheme.darkSlate : Colors.grey,
              fontStyle: date != null ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),

        // ── Tips Note ──
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 18,
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Verify the extracted details above. Tap "Use This Data" below to import into your transaction.',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppTheme.darkSlateVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCategorySelectorButton(BuildContext context) {
    if (availableCategories.isEmpty) return const SizedBox.shrink();

    final isSelected = category != null;

    return InkWell(
      onTap: () {
        OcrCategoryPickerSheet.show(
          context: context,
          selectedCategory: category,
          categories: availableCategories,
          onCategorySelected: onCategoryChanged,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.primary.withAlpha(isSelected ? 10 : 25),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: AppTheme.primary.withAlpha(isSelected ? 30 : 60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected
                  ? Icons.edit_rounded
                  : Icons.add_circle_outline_rounded,
              size: 13,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              isSelected ? 'Change' : 'Select',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
