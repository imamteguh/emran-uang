import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../bloc/dashboard_state.dart';
import '../../screens/analytics_screen.dart';

class RoutineSpendingCard extends StatelessWidget {
  final DashboardState provider;
  final ResponsiveHelper responsive;
  final NumberFormat formatter;

  const RoutineSpendingCard({
    super.key,
    required this.provider,
    required this.responsive,
    required this.formatter,
  });

  String _generateInsight(double routinePercent, double nonRoutinePercent) {
    if (routinePercent >= 0.7) {
      final p = (routinePercent * 100).round();
      return 'Pengeluaran didominasi kebutuhan rutin ($p%). Komitmen bulanan Anda terkontrol.';
    } else if (nonRoutinePercent >= 0.7) {
      final p = (nonRoutinePercent * 100).round();
      return 'Pengeluaran non-rutin tinggi ($p%). Perhatikan belanja fleksibel agar tetap hemat.';
    } else if (routinePercent > 0 && nonRoutinePercent > 0) {
      return 'Keseimbangan belanja rutin dan fleksibel terjaga dengan baik bulan ini.';
    }
    return 'Tandai transaksi rutin dan fleksibel untuk mengoptimalkan alokasi dana Anda.';
  }

  @override
  Widget build(BuildContext context) {
    final double routineSpend = provider.monthlyRoutineSpend;
    final double nonRoutineSpend = provider.monthlyNonRoutineSpend;
    final int routineCount = provider.monthlyRoutineCount;
    final int nonRoutineCount = provider.monthlyNonRoutineCount;

    final double totalSpend = routineSpend + nonRoutineSpend;
    final double routinePercent = totalSpend > 0 ? (routineSpend / totalSpend) : 0.0;
    final double nonRoutinePercent = totalSpend > 0 ? (nonRoutineSpend / totalSpend) : 0.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.scale(18)),
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
          // ── HEADER ROW ─────────────────────────────────────────────────────
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.sync_alt_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengeluaran Rutin & Non-Rutin',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: responsive.scaleFont(15),
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        Text(
                          'Bulan Ini',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: responsive.scaleFont(11),
                            fontWeight: FontWeight.w500,
                            color: AppTheme.darkSlateVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Detail',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: responsive.scaleFont(11),
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── CONTENT ────────────────────────────────────────────────────────
          if (totalSpend <= 0)
            _buildEmptyState()
          else ...[
            // Dual-Segmented Proportion Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 8,
                width: double.infinity,
                color: const Color(0xFFF1F5F9),
                child: Row(
                  children: [
                    if (routinePercent > 0)
                      Expanded(
                        flex: (routinePercent * 1000).round().clamp(1, 1000),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    if (routinePercent > 0 && nonRoutinePercent > 0)
                      const SizedBox(width: 2),
                    if (nonRoutinePercent > 0)
                      Expanded(
                        flex: (nonRoutinePercent * 1000).round().clamp(1, 1000),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B), // Amber-500
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Side-by-side metric cards
            Row(
              children: [
                // Rutin Card
                Expanded(
                  child: _buildMetricBlock(
                    label: 'RUTIN',
                    subtitle: routineCount > 0 ? '$routineCount transaksi' : 'Tagihan & langganan',
                    amount: routineSpend,
                    percent: routinePercent,
                    color: AppTheme.primary,
                    bgColor: const Color(0xFFEEF2FF),
                    icon: Icons.repeat_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                // Non-Rutin Card
                Expanded(
                  child: _buildMetricBlock(
                    label: 'NON-RUTIN',
                    subtitle: nonRoutineCount > 0 ? '$nonRoutineCount transaksi' : 'Belanja & fleksibel',
                    amount: nonRoutineSpend,
                    percent: nonRoutinePercent,
                    color: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFEF3C7),
                    icon: Icons.shopping_bag_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Smart Insight Hint
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _generateInsight(routinePercent, nonRoutinePercent),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: responsive.scaleFont(11),
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricBlock({
    required String label,
    required String subtitle,
    required double amount,
    required double percent,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    final int percentValue = (percent * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3.5,
              child: Container(color: color),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.scale(14),
                responsive.scale(12),
                responsive.scale(12),
                responsive.scale(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(icon, size: 14, color: color),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$percentValue%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatter.format(amount),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: responsive.scaleFont(14),
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkSlate,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: AppTheme.darkSlateVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.donut_large_rounded,
              size: 28,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Belum Ada Pengeluaran Bulan Ini',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tandai transaksi sebagai rutin saat mencatat untuk melihat perbandingan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.darkSlateVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
