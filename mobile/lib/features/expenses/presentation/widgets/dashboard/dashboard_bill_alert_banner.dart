import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../domain/entities/bill_reminder.dart';
import '../../bloc/dashboard_state.dart';
import '../../screens/main_shell.dart';

class DashboardBillAlertBanner extends StatelessWidget {
  final DashboardState provider;
  final ResponsiveHelper responsive;
  final NumberFormat currencyFormatter;

  const DashboardBillAlertBanner({
    super.key,
    required this.provider,
    required this.responsive,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final activeReminders = provider.reminders
        .where((r) => r.status == ReminderStatus.active)
        .toList();

    final overdueBills = activeReminders.where((r) => r.isOverdue).toList();
    final dueTodayBills = activeReminders.where((r) => r.isDueToday).toList();
    final dueSoonBills = activeReminders.where((r) => r.isDueSoon()).toList();

    if (overdueBills.isEmpty && dueTodayBills.isEmpty && dueSoonBills.isEmpty) {
      return const SizedBox.shrink();
    }

    String title;
    String subtitle;
    Color bgColor;
    Color borderColor;
    Color iconColor;
    IconData icon;
    String badgeText;
    Color badgeColor;
    Color badgeBg;

    if (overdueBills.isNotEmpty) {
      final bill = overdueBills.first;
      final count = overdueBills.length;
      title = count > 1
          ? '$count Tagihan Lewat Jatuh Tempo!'
          : 'Tagihan "${bill.title}" Terlambat!';
      subtitle = count > 1
          ? '${bill.title} (${currencyFormatter.format(bill.amount)}) dan ${count - 1} tagihan lainnya'
          : 'Total: ${currencyFormatter.format(bill.amount)} • Lewat ${bill.getDaysUntilDue().abs()} hari lalu';
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFCA5A5);
      iconColor = AppTheme.error;
      icon = Icons.warning_amber_rounded;
      badgeText = 'OVERDUE';
      badgeColor = AppTheme.error;
      badgeBg = const Color(0xFFFEE2E2);
    } else if (dueTodayBills.isNotEmpty) {
      final bill = dueTodayBills.first;
      final count = dueTodayBills.length;
      title = count > 1
          ? '$count Tagihan Jatuh Tempo HARI INI!'
          : 'Tagihan "${bill.title}" Jatuh Tempo HARI INI!';
      subtitle =
          'Nominal: ${currencyFormatter.format(bill.amount)} • Siapkan pembayaran hari ini';
      bgColor = const Color(0xFFFFF7ED);
      borderColor = const Color(0xFFFDBA74);
      iconColor = const Color(0xFFEA580C);
      icon = Icons.alarm_rounded;
      badgeText = 'HARI INI';
      badgeColor = const Color(0xFFEA580C);
      badgeBg = const Color(0xFFFFEDD5);
    } else {
      final bill = dueSoonBills.first;
      final days = bill.getDaysUntilDue();
      title = 'Pengingat Tagihan "${bill.title}"';
      subtitle =
          'Jatuh tempo dlm $days hari (${currencyFormatter.format(bill.amount)})';
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFCD34D);
      iconColor = const Color(0xFFD97706);
      icon = Icons.schedule_rounded;
      badgeText = 'H-$days';
      badgeColor = const Color(0xFFD97706);
      badgeBg = const Color(0xFFFEF3C7);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            TabNotification(2).dispatch(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkSlate,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          color: AppTheme.darkSlateVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppTheme.darkSlateVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
