import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';

class BillsPaidPendingCard extends StatelessWidget {
  final double paidThisMonth;
  final double pendingThisMonth;
  final NumberFormat currencyFormatter;

  const BillsPaidPendingCard({
    super.key,
    required this.paidThisMonth,
    required this.pendingThisMonth,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
              border: const Border(
                top: BorderSide(
                  color: AppTheme.secondary,
                  width: 3.0,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAID',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currencyFormatter.format(paidThisMonth),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkSlate,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
              border: Border(
                top: BorderSide(
                  color: pendingThisMonth > 0 ? AppTheme.error : Colors.grey,
                  width: 3.0,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PENDING',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: pendingThisMonth > 0 ? AppTheme.error : Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currencyFormatter.format(pendingThisMonth),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkSlate,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
