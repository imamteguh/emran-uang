import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../domain/entities/wallet.dart';
import '../widgets/analytics_skeleton.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _activeFilterIndex = 0; // 0: This Month, 1: Last Month

  @override
  void initState() {
    super.initState();
    // Fetch analytics on init if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      if (provider.compareData == null) {
        provider.fetchAnalytics();
      }
    });
  }

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.blueGrey;
    }
  }

  String _formatMonthYear(String monthStr) {
    try {
      final parts = monthStr.split('-');
      final year = parts[0];
      final month = int.parse(parts[1]);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[month - 1]} ${year.substring(2)}';
    } catch (_) {
      return monthStr;
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  String _generateInsight(
    Map<String, dynamic> currentMonth,
    Map<String, dynamic>? previousMonth,
  ) {
    if (currentMonth['byCategory'] == null ||
        (currentMonth['byCategory'] as List).isEmpty) {
      return 'Start adding your daily expenses to see smart budget recommendations and spending trends here.';
    }

    final currentCategories = currentMonth['byCategory'] as List;
    final topCategory = currentCategories[0];
    final topCategoryName = topCategory['category']['name'] ?? 'Categories';
    final topCategoryTotal = _parseDouble(topCategory['total']);
    final totalSpend = _parseDouble(currentMonth['total']);
    final percentage = totalSpend > 0
        ? (topCategoryTotal / totalSpend * 100).round()
        : 0;

    if (previousMonth == null) {
      return 'Your top spending category is "$topCategoryName", making up $percentage% of your total monthly budget.';
    }

    // Find the same category in previous month
    double prevCategoryTotal = 0.0;
    final prevCategories = previousMonth['byCategory'] as List;
    for (var prevCat in prevCategories) {
      if (prevCat['category']['id'] == topCategory['category']['id']) {
        prevCategoryTotal = _parseDouble(prevCat['total']);
        break;
      }
    }

    if (prevCategoryTotal > 0) {
      final diff = topCategoryTotal - prevCategoryTotal;
      if (diff > 0) {
        final changePercent = ((diff / prevCategoryTotal) * 100).round();
        return 'You spent $changePercent% more on "$topCategoryName" compared to last month. Consider keeping an eye on this category to stay within budget!';
      } else {
        final changePercent = ((diff.abs() / prevCategoryTotal) * 100).round();
        return 'Awesome! You spent $changePercent% less on "$topCategoryName" compared to last month. Keep up the good work!';
      }
    }

    return 'Your top spending category is "$topCategoryName", making up $percentage% of your total monthly budget.';
  }

  Widget _buildAppBarTitle(
    DashboardProvider provider,
    AuthProvider authProvider,
    ResponsiveHelper responsive,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withAlpha(51),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            provider.activeWallet == null
                ? Icons.account_balance_wallet
                : (provider.isSharedMode
                      ? Icons.groups_rounded
                      : Icons.person_rounded),
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        if (provider.allWallets.isEmpty)
          Text(
            'WalletShare',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: responsive.scaleFont(18),
            ),
          )
        else
          PopupMenuButton<WalletEntity>(
            onSelected: (WalletEntity wallet) {
              provider.selectWallet(wallet);
            },
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            itemBuilder: (context) {
              return [
                if (provider.personalWallets.isNotEmpty) ...[
                  const PopupMenuItem<WalletEntity>(
                    enabled: false,
                    height: 24,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'PERSONAL WALLETS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  ...provider.personalWallets.map(
                    (wallet) => PopupMenuItem<WalletEntity>(
                      value: wallet,
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            color: provider.activeWallet?.id == wallet.id
                                ? AppTheme.primary
                                : AppTheme.darkSlateVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              wallet.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight:
                                    provider.activeWallet?.id == wallet.id
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: AppTheme.darkSlate,
                              ),
                            ),
                          ),
                          if (provider.activeWallet?.id == wallet.id)
                            const Icon(
                              Icons.check_rounded,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (provider.sharedWallets.isNotEmpty) ...[
                  const PopupMenuDivider(),
                  const PopupMenuItem<WalletEntity>(
                    enabled: false,
                    height: 24,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'GROUP WALLETS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  ...provider.sharedWallets.map(
                    (wallet) => PopupMenuItem<WalletEntity>(
                      value: wallet,
                      child: Row(
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            color: provider.activeWallet?.id == wallet.id
                                ? AppTheme.primary
                                : AppTheme.darkSlateVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              wallet.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight:
                                    provider.activeWallet?.id == wallet.id
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: AppTheme.darkSlate,
                              ),
                            ),
                          ),
                          if (provider.activeWallet?.id == wallet.id)
                            const Icon(
                              Icons.check_rounded,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ];
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: responsive.scale(150)),
                  child: Text(
                    provider.activeWallet?.name ?? 'Select Wallet',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: responsive.scaleFont(18),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final responsive = ResponsiveHelper(context);

    final currencyCode = provider.activeWallet?.currency ?? 'IDR';
    final currencyFormatter = CurrencyHelper.getFormatter(currencyCode);

    if (provider.isLoading && provider.compareData == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppTheme.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: _buildAppBarTitle(provider, authProvider, responsive),
        ),
        body: const SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: AnalyticsSkeleton(),
        ),
      );
    }

    final compareData = provider.compareData;
    final monthsList = compareData != null
        ? compareData['months'] as List? ?? []
        : [];

    // If no months or empty
    if (monthsList.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppTheme.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: _buildAppBarTitle(provider, authProvider, responsive),
        ),
        body: RefreshIndicator(
          onRefresh: provider.refreshData,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            children: [
              SizedBox(height: responsive.scale(100)),
              const Icon(
                Icons.analytics_outlined,
                size: 64,
                color: AppTheme.darkSlateVariant,
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'No Data Yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkSlate,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Add some expenses to see your monthly spending analysis.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.darkSlateVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filterIndex = _activeFilterIndex.clamp(0, monthsList.length - 1);
    final activeMonthData = monthsList[filterIndex] as Map<String, dynamic>;
    final activeMonthTotal = _parseDouble(activeMonthData['total']);

    // Compute trending comparison vs preceding month in list
    double changePercent = 0.0;
    String direction = 'unchanged';
    bool hasComparison = false;
    String prevMonthLabel = '';

    if (filterIndex + 1 < monthsList.length) {
      final current = _parseDouble(activeMonthData['total']);
      final prevMonthData = monthsList[filterIndex + 1] as Map<String, dynamic>;
      final previous = _parseDouble(prevMonthData['total']);
      prevMonthLabel = _formatMonthYear(prevMonthData['month'] as String);
      if (previous > 0) {
        changePercent = ((current - previous) / previous) * 100;
        direction = changePercent > 0
            ? 'increased'
            : changePercent < 0
            ? 'decreased'
            : 'unchanged';
        hasComparison = true;
      }
    }

    // Category calculation
    final activeCategories = activeMonthData['byCategory'] as List? ?? [];
    String topCatName = 'None';
    double topCatTotal = 0.0;
    double topCatPercentage = 0.0;
    if (activeCategories.isNotEmpty) {
      final topCat = activeCategories[0];
      topCatName = topCat['category']['name'] ?? 'Other';
      topCatTotal = _parseDouble(topCat['total']);
      if (activeMonthTotal > 0) {
        topCatPercentage = topCatTotal / activeMonthTotal;
      }
    }

    // Routine vs Non-routine
    double routineSpend = 0.0;
    double nonRoutineSpend = 0.0;
    final activeTypes = activeMonthData['byType'] as List? ?? [];
    for (var typeData in activeTypes) {
      if (typeData['type'] == 'ROUTINE') {
        routineSpend = _parseDouble(typeData['total']);
      } else if (typeData['type'] == 'NON_ROUTINE') {
        nonRoutineSpend = _parseDouble(typeData['total']);
      }
    }
    final totalSplitSpend = routineSpend + nonRoutineSpend;
    final routinePercent = totalSplitSpend > 0 ? routineSpend / totalSplitSpend : 0.0;
    final nonRoutinePercent = totalSplitSpend > 0 ? nonRoutineSpend / totalSplitSpend : 0.0;

    // Insight
    final prevMonthData = (filterIndex + 1 < monthsList.length)
        ? monthsList[filterIndex + 1] as Map<String, dynamic>
        : null;
    final insightMessage = _generateInsight(activeMonthData, prevMonthData);

    // Spend trend graph (reversing last 4 months for chronological view)
    final chartMonths = List.from(monthsList.take(4)).reversed.toList();
    double maxMonthTotal = 0.0;
    for (var m in chartMonths) {
      final val = _parseDouble(m['total']);
      if (val > maxMonthTotal) {
        maxMonthTotal = val;
      }
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: _buildAppBarTitle(provider, authProvider, responsive),
        actions: [
          IconButton(
            icon: const Icon(Icons.group, color: AppTheme.primary, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                    // Date Filter Row (Scrollable Tabs for All Available Months)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: List.generate(monthsList.length, (index) {
                            final monthData =
                                monthsList[index] as Map<String, dynamic>;
                            final label = _formatMonthYear(
                              monthData['month'] as String,
                            );
                            final isSelected = filterIndex == index;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _activeFilterIndex = index;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.darkSlateVariant,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Total Spending Hero Box
                Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: AppTheme.roundedBorder,
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        bottom: -10,
                        child: Icon(
                          Icons.analytics,
                          size: 130,
                          color: Colors.white.withAlpha(25),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
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
                              currencyFormatter.format(activeMonthTotal),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: responsive.scaleFont(30),
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (hasComparison)
                              Row(
                                children: [
                                  Icon(
                                    direction == 'decreased'
                                        ? Icons.trending_down
                                        : Icons.trending_up,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${changePercent.abs().toStringAsFixed(1)}% ${direction == 'decreased' ? 'less' : 'more'} than $prevMonthLabel',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            else
                              const Row(
                                children: [
                                  Icon(
                                    Icons.trending_flat,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'No comparison data available',
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
                        children: chartMonths.map((m) {
                          final label = _formatMonthYear(m['month'] as String);
                          final val = _parseDouble(m['total']);
                          final isActive = monthsList.indexOf(m) == filterIndex;
                          return _buildChartBar(
                            label,
                            val,
                            maxMonthTotal,
                            isActive,
                            currencyFormatter,
                          );
                        }).toList(),
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
                          const Icon(
                            Icons.pie_chart_outline,
                            color: AppTheme.darkSlateVariant,
                          ),
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
                                  value: topCatPercentage,
                                  strokeWidth: 12,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  color: AppTheme.primary,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Top Cat',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: AppTheme.darkSlateVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 80,
                                    ),
                                    child: Text(
                                      topCatName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(topCatPercentage * 100).round()}%',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.darkSlate,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          // Legend List
                          Expanded(
                            child: activeCategories.isEmpty
                                ? Center(
                                    child: Text(
                                      'No categories',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 12,
                                        color: AppTheme.darkSlateVariant,
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: activeCategories.map((c) {
                                      final name =
                                          c['category']['name'] ?? 'Other';
                                      final total = _parseDouble(c['total']);
                                      final colorStr =
                                          c['category']['color'] as String? ??
                                          '#BDC3C7';
                                      final color = _parseHexColor(colorStr);
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: _buildLegendItem(
                                          name,
                                          total,
                                          color,
                                          currencyFormatter,
                                        ),
                                      );
                                    }).toList(),
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
                        routineSpend,
                        'Fixed subscriptions & bills',
                        Icons.repeat,
                        AppTheme.primary,
                        currencyCode,
                        routinePercent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSplitCard(
                        'Non-Routine',
                        nonRoutineSpend,
                        'Daily dining out & travel',
                        Icons.rocket_launch,
                        AppTheme.tertiary,
                        currencyCode,
                        nonRoutinePercent,
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
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.white,
                          size: 20,
                        ),
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
                              insightMessage,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                color: AppTheme.secondary.withAlpha(200),
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {},
                              child: Text(
                                'Review Budgets',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondary,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppTheme.secondary,
                                ),
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
                    ),
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
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
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
    double percentage,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accentColor, width: 4.0)),
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
          Text(desc, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
