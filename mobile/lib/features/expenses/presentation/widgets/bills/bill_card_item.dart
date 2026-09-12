import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/bill_reminder.dart';
import '../category_icon.dart';
import 'bills_date_formatter.dart';

class BillCardItem extends StatelessWidget {
  final BillReminderEntity reminder;
  final NumberFormat formatter;
  final VoidCallback onTap;

  const BillCardItem({
    super.key,
    required this.reminder,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColorStr = reminder.category?.color ?? '#4F46E5';
    final categoryColor = Color(
      int.parse(categoryColorStr.replaceFirst('#', '0xFF')),
    );
    final bgIconColor = categoryColor.withValues(alpha: 0.15);
    final iconColor = categoryColor;
    final isPaid = reminder.isPaidForCurrentPeriod;

    // Calculate accurate recurring due state
    final effectiveDue = reminder.getEffectiveDueDate();
    final daysUntilDue = reminder.getDaysUntilDue();
    final isOverdue = reminder.isOverdue;
    final isDueToday = reminder.isDueToday;
    final isDueSoon = reminder.isDueSoon();
    final isUrgent = reminder.needsAlert;

    String dueText;
    String statusBadgeLabel;
    Color statusBadgeColor;
    Color statusBadgeBgColor;

    if (isPaid) {
      dueText = reminder.periodicity == Periodicity.yearly
          ? 'Lunas tahun ini (berikutnya ${BillsDateFormatter.formatDayMonth(effectiveDue)})'
          : 'Lunas bulan ini (berikutnya ${BillsDateFormatter.formatDayMonth(effectiveDue)})';
      statusBadgeLabel = 'Lunas';
      statusBadgeColor = AppTheme.secondary;
      statusBadgeBgColor = AppTheme.secondaryContainer;
    } else if (isOverdue) {
      dueText =
          'Lewat ${daysUntilDue.abs()} hari (${BillsDateFormatter.formatDayMonth(effectiveDue)})';
      statusBadgeLabel = 'Lewat Tempo';
      statusBadgeColor = AppTheme.error;
      statusBadgeBgColor = AppTheme.errorContainer;
    } else if (isDueToday) {
      dueText = 'Jatuh tempo HARI INI';
      statusBadgeLabel = 'Hari Ini';
      statusBadgeColor = const Color(0xFFEA580C);
      statusBadgeBgColor = const Color(0xFFFFEDD5);
    } else if (isDueSoon) {
      dueText =
          'Jatuh tempo dlm $daysUntilDue hari (${BillsDateFormatter.formatDayMonth(effectiveDue)})';
      statusBadgeLabel = 'Segera Tiba';
      statusBadgeColor = const Color(0xFFD97706);
      statusBadgeBgColor = const Color(0xFFFEF3C7);
    } else {
      dueText = reminder.periodicity == Periodicity.yearly
          ? 'Jatuh tempo ${BillsDateFormatter.formatMonthYear(effectiveDue)}'
          : 'Jatuh tempo ${BillsDateFormatter.formatDayMonth(effectiveDue)}';
      statusBadgeLabel = 'Belum Bayar';
      statusBadgeColor = AppTheme.darkSlateVariant;
      statusBadgeBgColor = const Color(0xFFF1F5F9);
    }


    final String periodicityLabel = reminder.periodicity == Periodicity.yearly
        ? 'Tahunan'
        : 'Bulanan';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softShadow,
            border: Border.all(
              color: isPaid
                  ? AppTheme.secondary.withValues(alpha: 0.25)
                  : (isUrgent
                      ? AppTheme.error.withValues(alpha: 0.3)
                      : const Color(0xFFF1F5F9)),
              width: (isPaid || isUrgent) ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgIconColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: CategoryIcon(
                  icon: reminder.category?.icon ?? '💰',
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.darkSlate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            periodicityLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkSlateVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dueText,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontWeight: isUrgent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isUrgent
                                  ? AppTheme.error
                                  : (isPaid
                                      ? AppTheme.secondary
                                      : AppTheme.darkSlateVariant),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatter.format(reminder.amount),
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusBadgeBgColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusBadgeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusBadgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: AppTheme.darkSlateVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
