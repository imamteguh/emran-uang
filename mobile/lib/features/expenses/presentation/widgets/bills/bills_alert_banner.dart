import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../domain/entities/bill_reminder.dart';

class BillsAlertBanner extends StatelessWidget {
  final List<BillReminderEntity> overdueBills;
  final List<BillReminderEntity> dueTodayBills;
  final List<BillReminderEntity> dueSoonBills;
  final NumberFormat currencyFormatter;
  final ResponsiveHelper responsive;

  const BillsAlertBanner({
    super.key,
    required this.overdueBills,
    required this.dueTodayBills,
    required this.dueSoonBills,
    required this.currencyFormatter,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    if (overdueBills.isNotEmpty) {
      final totalOverdue =
          overdueBills.fold<double>(0, (sum, b) => sum + b.amount);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.error,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perhatian: ${overdueBills.length} Tagihan Lewat Jatuh Tempo!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total tertunggak: ${currencyFormatter.format(totalOverdue)}. Segera lakukan pembayaran.',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      color: const Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (dueTodayBills.isNotEmpty) {
      final totalDueToday =
          dueTodayBills.fold<double>(0, (sum, b) => sum + b.amount);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDBA74)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFEDD5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.alarm_rounded,
                color: Color(0xFFEA580C),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${dueTodayBills.length} Tagihan Jatuh Tempo HARI INI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF9A3412),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total hari ini: ${currencyFormatter.format(totalDueToday)}. Segera selesaikan pembayaran.',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      color: const Color(0xFFC2410C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (dueSoonBills.isNotEmpty) {
      final nextBill = dueSoonBills.first;
      final days = nextBill.getDaysUntilDue();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: Color(0xFFD97706),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengingat: ${dueSoonBills.length} Tagihan Mendekati Jatuh Tempo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${nextBill.title} (${currencyFormatter.format(nextBill.amount)}) jatuh tempo dalam $days hari.',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppTheme.secondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Semua Tagihan Terkendali',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF166534),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Semua tagihan sudah lunas atau belum mendekati jatuh tempo.',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}
