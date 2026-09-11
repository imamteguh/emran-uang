import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';

class StickyDateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final DateTime date;
  final int count;
  final double totalAmount;
  final NumberFormat currencyFormatter;

  StickyDateHeaderDelegate({
    required this.date,
    required this.count,
    required this.totalAmount,
    required this.currencyFormatter,
  });

  @override
  double get minExtent => 42.0;

  @override
  double get maxExtent => 42.0;

  String _formatDateHeader(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final difference = today.difference(target).inDays;

    final dateString = DateFormat('dd MMM yyyy', 'id_ID').format(d);

    if (difference == 0) {
      return 'Hari Ini, $dateString';
    } else if (difference == 1) {
      return 'Kemarin, $dateString';
    } else {
      final dayName = DateFormat('EEEE', 'id_ID').format(d);
      return '$dayName, $dateString';
    }
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isStuck = shrinkOffset > 0 || overlapsContent;

    return Container(
      height: 42.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: isStuck ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isStuck ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          top: BorderSide(
            color: const Color(0xFFE2E8F0),
            width: isStuck ? 0.5 : 1,
          ),
        ),
        boxShadow: isStuck
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDateHeader(date),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkSlate,
                ),
              ),
            ],
          ),
          Text(
            '$count TRX • -${currencyFormatter.format(totalAmount)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFDC2626), // DB Red
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant StickyDateHeaderDelegate oldDelegate) {
    return oldDelegate.date != date ||
        oldDelegate.count != count ||
        oldDelegate.totalAmount != totalAmount ||
        oldDelegate.currencyFormatter != currencyFormatter;
  }
}
