import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../bloc/dashboard_state.dart';

class MonthlySpendingLineChartHero extends StatelessWidget {
  final DashboardState provider;
  final ResponsiveHelper responsive;
  final NumberFormat formatter;

  const MonthlySpendingLineChartHero({
    super.key,
    required this.provider,
    required this.responsive,
    required this.formatter,
  });

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(now);
    final currentSpend = provider.monthlySpend;

    // Calculate comparison with last month
    double prevMonthSpend = 0.0;
    bool hasComparison = false;

    final compareMonths = provider.compareData?['months'] as List<dynamic>?;
    if (compareMonths != null && compareMonths.length > 1) {
      prevMonthSpend = _parseDouble(compareMonths[1]['total']);
      hasComparison = true;
    } else {
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;
      final prevExpenses = provider.expenses.where(
        (e) => e.date.year == prevYear && e.date.month == prevMonth,
      );
      if (prevExpenses.isNotEmpty) {
        prevMonthSpend = prevExpenses.fold(0.0, (sum, e) => sum + e.amount);
        hasComparison = true;
      }
    }

    double changePercent = 0.0;
    String direction = 'neutral';
    if (hasComparison && prevMonthSpend > 0) {
      changePercent = ((currentSpend - prevMonthSpend) / prevMonthSpend) * 100;
      if (changePercent > 0.05) {
        direction = 'increased';
      } else if (changePercent < -0.05) {
        direction = 'decreased';
      }
    } else if (hasComparison && prevMonthSpend == 0 && currentSpend > 0) {
      changePercent = 100.0;
      direction = 'increased';
    }

    // Prepare daily spending array for current month
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailySpending = List<double>.filled(daysInMonth, 0.0);
    for (final exp in provider.expenses) {
      if (exp.date.year == now.year && exp.date.month == now.month) {
        final dayIdx = (exp.date.day - 1).clamp(0, daysInMonth - 1);
        dailySpending[dayIdx] += exp.amount;
      }
    }

    final double maxDaily = dailySpending.fold(0.0, math.max);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF131D2E), // Modern dark slate container
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top tag & month label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL PENGELUARAN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: responsive.scaleFont(11),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 1.1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            monthName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: responsive.scaleFont(11),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Amount display
                Text(
                  formatter.format(currentSpend),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: responsive.scaleFont(28),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),

                // Month-over-month comparison badge
                Row(
                  children: [
                    _buildComparisonBadge(direction, changePercent, hasComparison),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasComparison
                            ? 'vs bulan lalu (${formatter.format(prevMonthSpend)})'
                            : 'Belum ada data bulan lalu',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: responsive.scaleFont(11),
                          color: const Color(0xFF94A3B8),
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

          // Line Chart Area
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SizedBox(
              height: 105,
              width: double.infinity,
              child: CustomPaint(
                painter: MonthlySpendingLineChartPainter(
                  dailySpending: dailySpending,
                  daysInMonth: daysInMonth,
                  currentDay: now.day,
                  maxDaily: maxDaily,
                ),
              ),
            ),
          ),

          // Day axis labels row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDayLabel('Tgl 1'),
                _buildDayLabel('5'),
                _buildDayLabel('10'),
                _buildDayLabel('15'),
                _buildDayLabel('20'),
                _buildDayLabel('25'),
                _buildDayLabel('$daysInMonth'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF64748B),
      ),
    );
  }

  Widget _buildComparisonBadge(
    String direction,
    double changePercent,
    bool hasComparison,
  ) {
    if (!hasComparison) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Bulan baru',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFCBD5E1),
          ),
        ),
      );
    }

    final isIncreased = direction == 'increased';
    final isDecreased = direction == 'decreased';

    final Color badgeBg = isIncreased
        ? const Color(0xFF7F1D1D).withValues(alpha: 0.35)
        : (isDecreased
            ? const Color(0xFF064E3B).withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.1));

    final Color badgeText = isIncreased
        ? const Color(0xFFF87171)
        : (isDecreased
            ? const Color(0xFF34D399)
            : const Color(0xFFCBD5E1));

    final IconData icon = isIncreased
        ? Icons.trending_up_rounded
        : (isDecreased
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded);

    final String sign = isIncreased ? '+' : (isDecreased ? '-' : '');
    final String pctText = '$sign${changePercent.abs().toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeText.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: badgeText),
          const SizedBox(width: 4),
          Text(
            pctText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badgeText,
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlySpendingLineChartPainter extends CustomPainter {
  final List<double> dailySpending;
  final int daysInMonth;
  final int currentDay;
  final double maxDaily;

  MonthlySpendingLineChartPainter({
    required this.dailySpending,
    required this.daysInMonth,
    required this.currentDay,
    required this.maxDaily,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double topPadding = 8.0;
    const double bottomPadding = 4.0;
    const double horizontalPadding = 4.0;

    final double chartWidth = size.width - (horizontalPadding * 2);
    final double chartHeight = size.height - bottomPadding - topPadding;

    // Draw horizontal grid guide lines (3 dashed/faint lines)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 3; i++) {
      final y = topPadding + (chartHeight / 2) * i;
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(size.width - horizontalPadding, y),
        gridPaint,
      );
    }

    if (dailySpending.isEmpty || maxDaily <= 0) {
      // Empty state baseline
      final baselinePaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final y = topPadding + chartHeight;
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(size.width - horizontalPadding, y),
        baselinePaint,
      );
      return;
    }

    // Generate points for the daily curve
    final List<Offset> points = [];
    int peakDayIdx = 0;
    double highestAmount = 0.0;

    for (int i = 0; i < daysInMonth; i++) {
      final double x = horizontalPadding + (i / (daysInMonth - 1)) * chartWidth;
      final double spend = dailySpending[i];
      if (spend > highestAmount) {
        highestAmount = spend;
        peakDayIdx = i;
      }
      final double normalized = maxDaily > 0 ? (spend / maxDaily) : 0.0;
      final double y = topPadding + chartHeight - (normalized * chartHeight);
      points.add(Offset(x, y));
    }

    // Create smooth bezier curve path
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPointX = (p0.dx + p1.dx) / 2;
      path.cubicTo(
        controlPointX,
        p0.dy,
        controlPointX,
        p1.dy,
        p1.dx,
        p1.dy,
      );
    }

    // Create gradient fill area under the line
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, topPadding + chartHeight)
      ..lineTo(points.first.dx, topPadding + chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: 0.28),
          const Color(0xFF0284C7).withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(
        Rect.fromLTWH(
          horizontalPadding,
          topPadding,
          chartWidth,
          chartHeight,
        ),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw the glowing line
    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF38BDF8), Color(0xFF60A5FA), Color(0xFF818CF8)],
      ).createShader(
        Rect.fromLTWH(horizontalPadding, topPadding, chartWidth, chartHeight),
      )
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);

    // Highlight peak day point with glow
    if (highestAmount > 0 && peakDayIdx < points.length) {
      final peakPoint = points[peakDayIdx];

      // Outer glow
      final outerGlowPaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(peakPoint, 7, outerGlowPaint);

      // Inner dot
      final innerDotPaint = Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(peakPoint, 3.5, innerDotPaint);

      // Center white dot
      final centerDotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(peakPoint, 1.5, centerDotPaint);
    }

    // Highlight today's point
    final todayIdx = (currentDay - 1).clamp(0, points.length - 1);
    if (todayIdx != peakDayIdx) {
      final todayPoint = points[todayIdx];
      final todayPaint = Paint()
        ..color = const Color(0xFF818CF8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(todayPoint, 3, todayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MonthlySpendingLineChartPainter oldDelegate) {
    return oldDelegate.dailySpending != dailySpending ||
        oldDelegate.daysInMonth != daysInMonth ||
        oldDelegate.currentDay != currentDay ||
        oldDelegate.maxDaily != maxDaily;
  }
}
