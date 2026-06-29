import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/user_avatar.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bellController;
  bool _bellClicked = false;

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

  void _handleBellClick() {
    setState(() {
      _bellClicked = !_bellClicked;
    });
    // Trigger quick click animation
    _bellController.stop();
    _bellController.forward(from: 0.0).then((_) {
      if (!_bellClicked) {
        _bellController.repeat(reverse: true);
      }
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🔔 ', style: TextStyle(fontSize: 16)),
            Expanded(
              child: Text(
                'Reminders are synced with your partner!',
                style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final currencyCode = dashboardProvider.activeWallet?.currency ?? 'IDR';
    final currencyFormatter = CurrencyHelper.getFormatter(currencyCode);

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
              // Summary Header
              Text(
                'Upcoming Bills',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: responsive.scaleFont(28),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You have 4 bills due in the next 7 days.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: responsive.scaleFont(14),
                  color: AppTheme.darkSlateVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Bento Outflow Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: AppTheme.roundedBorder,
                  boxShadow: AppTheme.softShadow,
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL MONTHLY OUTFLOW',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withAlpha(200),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currencyFormatter.format(1240000), // Rp 1.240.000
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: responsive.scaleFont(32),
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _bellController,
                          builder: (context, child) {
                            double rotation = 0.0;
                            if (!_bellClicked) {
                              rotation = (_bellController.value * 0.2) - 0.1; // small shake
                            }
                            return Transform.rotate(
                              angle: rotation,
                              child: GestureDetector(
                                onTap: _handleBellClick,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(50),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.notifications_active_outlined,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Paid vs Pending Side-by-side Bento Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.softShadow,
                        border: const Border(
                          top: BorderSide(color: AppTheme.secondary, width: 3.0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PAID THIS MONTH',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currencyFormatter.format(840000),
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
                        border: const Border(
                          top: BorderSide(color: AppTheme.error, width: 3.0),
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
                              color: AppTheme.error,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currencyFormatter.format(400000),
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
              ),
              const SizedBox(height: 32),

              // Monthly Bills Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monthly Bills',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: responsive.scaleFont(18),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Add New',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Bills List
              _buildBillItem(
                'Fiber Internet',
                'Due Oct 12',
                120000,
                true,
                Icons.wifi,
                AppTheme.secondaryContainer,
                AppTheme.secondary,
                currencyFormatter,
              ),
              const SizedBox(height: 12),
              _buildBillItem(
                'Electric Utility',
                'Due Oct 15 (In 3 days)',
                280000,
                false,
                Icons.bolt,
                AppTheme.primaryFixed,
                AppTheme.primary,
                currencyFormatter,
                isUrgent: true,
              ),
              const SizedBox(height: 12),
              _buildBillItem(
                'Streaming Bundle',
                'Due Oct 18',
                32000,
                false,
                Icons.movie_outlined,
                AppTheme.tertiaryFixed,
                AppTheme.tertiary,
                currencyFormatter,
              ),
              const SizedBox(height: 32),

              // Annual Renewals Section
              Text(
                'Annual Renewals',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: responsive.scaleFont(18),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9), // surface-container-low
                  borderRadius: AppTheme.roundedBorder,
                  border: Border.all(
                    color: AppTheme.outlineVariant,
                    width: 2.0,
                    style: BorderStyle.solid, // simulated dashed or clean thin outline
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.calendar_today_outlined,
                        color: AppTheme.outline,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Car Insurance',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Next annual payment of ${currencyFormatter.format(1200000)} due in December.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: AppTheme.darkSlateVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.85,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${currencyFormatter.format(1020000)} saved of ${currencyFormatter.format(1200000)} goal',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkSlateVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillItem(
    String name,
    String dueText,
    double amount,
    bool isPaid,
    IconData icon,
    Color bgIconColor,
    Color iconColor,
    NumberFormat formatter, {
    bool isUrgent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
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
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dueText,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                    color: isUrgent ? AppTheme.error : AppTheme.darkSlateVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatter.format(amount),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid ? AppTheme.secondaryContainer : AppTheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPaid ? 'Paid' : 'Pending',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? AppTheme.secondary : AppTheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
