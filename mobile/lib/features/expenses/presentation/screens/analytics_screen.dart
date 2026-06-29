import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/user_avatar.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final responsive = ResponsiveHelper(context);

    final currencyCode = provider.activeWallet?.currency ?? 'IDR';
    final currencyFormatter = CurrencyHelper.getFormatter(currencyCode);

    final total = provider.totalSpend;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            UserAvatar(
              avatarUrl: user?.avatarUrl,
              displayName: user?.displayName ?? 'User',
              size: 40,
            ),
            const SizedBox(width: 12),
            Text(
              'WalletShare',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: responsive.scaleFont(20),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group, color: AppTheme.primary, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsive.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title
              Text(
                'MONTHLY INSIGHTS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: responsive.scaleFont(11),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlateVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Analysis',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: responsive.scaleFont(28),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  // Simple Date Filter Row
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'This Month',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Last Month',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkSlateVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Total Spending Hero Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: AppTheme.roundedBorder,
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Spending',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.format(total),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: responsive.scaleFont(30),
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.trending_down, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          '4% less than last month',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Spending Comparison Bar Chart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.roundedBorder,
                  boxShadow: AppTheme.softShadow,
                  border: const Border(
                    top: BorderSide(color: AppTheme.primary, width: 3.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spending Comparison',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildChartBar('June', total * 0.7, total, false, currencyFormatter),
                        _buildChartBar('July', total * 0.85, total, false, currencyFormatter),
                        _buildChartBar('Aug', total * 1.05, total, false, currencyFormatter),
                        _buildChartBar('Sep', total, total, true, currencyFormatter),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Category Split Card
              Container(
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
                        const Icon(Icons.pie_chart_outline, color: AppTheme.darkSlateVariant),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // Custom Pie chart simulation (Progress Ring)
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 110,
                              height: 110,
                              child: CircularProgressIndicator(
                                value: total > 0 ? 0.45 : 0.0,
                                strokeWidth: 12,
                                backgroundColor: const Color(0xFFF1F5F9),
                                color: AppTheme.primary,
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  'Top Cat',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: AppTheme.darkSlateVariant,
                                  ),
                                ),
                                Text(
                                  'Bills',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        // Legend List
                        Expanded(
                          child: Column(
                            children: [
                              _buildLegendItem('Bills', total * 0.45, AppTheme.primary, currencyFormatter),
                              const SizedBox(height: 8),
                              _buildLegendItem('Food & Dining', total * 0.30, AppTheme.secondary, currencyFormatter),
                              const SizedBox(height: 8),
                              _buildLegendItem('Fun & Hobbies', total * 0.25, AppTheme.tertiary, currencyFormatter),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Routine vs Non-Routine Split Row
              Row(
                children: [
                  Expanded(
                    child: _buildSplitCard(
                      'Routine',
                      total * 0.65,
                      'Rent, Netflix, bills',
                      Icons.repeat,
                      AppTheme.primary,
                      currencyCode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSplitCard(
                      'Non-Routine',
                      total * 0.35,
                      'Dining out, Travel',
                      Icons.rocket_launch,
                      AppTheme.tertiary,
                      currencyCode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Insight Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryContainer,
                  borderRadius: AppTheme.roundedBorder,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Budget Insight',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You spent 12% more on Dining Out than last month. Consider moving Rp 150.000 from your "Fun" budget to cover it!',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              color: AppTheme.secondary.withAlpha(200),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Chart Bar Painter helper ──────────────────────────────────────────────

  Widget _buildChartBar(
    String label,
    double value,
    double maxValue,
    bool isCurrent,
    NumberFormat formatter,
  ) {
    const double barHeightMax = 100.0;
    final double percentage = maxValue > 0 ? (value / maxValue) : 0.0;
    final double barHeight = barHeightMax * percentage;

    return Column(
      children: [
        Container(
          width: 32,
          height: barHeight < 8 ? 8 : barHeight,
          decoration: BoxDecoration(
            color: isCurrent ? AppTheme.primary : AppTheme.primaryFixedDim,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(30),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? AppTheme.primary : AppTheme.darkSlateVariant,
          ),
        ),
      ],
    );
  }

  // ─── Legend Item Helper ────────────────────────────────────────────────────

  Widget _buildLegendItem(
    String name,
    double amount,
    Color color,
    NumberFormat formatter,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
            Text(
              name,
              style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Text(
          formatter.format(amount),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ─── Routine vs Variable card helper ───────────────────────────────────────

  Widget _buildSplitCard(
    String label,
    double amount,
    String desc,
    IconData icon,
    Color accentColor,
    String currencyCode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: accentColor, width: 4.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyHelper.format(amount, currencyCode),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
