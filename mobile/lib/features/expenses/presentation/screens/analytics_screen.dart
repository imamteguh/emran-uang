import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/wallet.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../widgets/analytics/analytics.dart';
import '../widgets/analytics_skeleton.dart';
import 'category_monthly_expenses_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ScrollController _tabScrollController = ScrollController();
  int _activeFilterIndex = 0;
  String? _selectedCategoryId;

  @override
  void dispose() {
    _tabScrollController.dispose();
    super.dispose();
  }

  void _navigateToCategoryDetails(
    ExpenseCategory category,
    String monthStr,
    String currencyCode,
  ) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => CategoryMonthlyExpensesScreen(
              category: category,
              monthStr: monthStr,
              walletId:
                  context.read<DashboardBloc>().state.activeWallet?.id ?? '',
              walletName:
                  context.read<DashboardBloc>().state.activeWallet?.name ?? '',
              currencyCode: currencyCode,
            ),
          ),
        )
        .then((_) {
          if (!mounted) return;
          context.read<DashboardBloc>().add(const DashboardRefreshRequested());
        });
  }

  void _scrollToNewestTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tabScrollController.hasClients &&
          _tabScrollController.position.maxScrollExtent > 0) {
        _tabScrollController.jumpTo(
          _tabScrollController.position.maxScrollExtent,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardBloc = context.read<DashboardBloc>();
      if (dashboardBloc.state.compareData == null) {
        dashboardBloc.add(const DashboardFetchAnalyticsRequested());
      }
      _scrollToNewestTab();
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

  void _onWalletSelected(WalletEntity wallet) {
    setState(() {
      _selectedCategoryId = null;
    });
    context.read<DashboardBloc>().add(
      DashboardSelectWalletRequested(wallet),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardBloc>().state;
    final responsive = ResponsiveHelper(context);

    final currencyCode = provider.activeWallet?.currency ?? 'IDR';
    final currencyFormatter = CurrencyHelper.getFormatter(currencyCode);

    if ((provider.isLoading || provider.isLoadingAnalytics) &&
        provider.compareData == null) {
      return Scaffold(
        appBar: AnalyticsAppBar(
          provider: provider,
          responsive: responsive,
          onWalletSelected: _onWalletSelected,
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

    if (monthsList.isEmpty) {
      return Scaffold(
        appBar: AnalyticsAppBar(
          provider: provider,
          responsive: responsive,
          onWalletSelected: _onWalletSelected,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            context.read<DashboardBloc>().add(
              const DashboardRefreshRequested(),
            );
          },
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

    final activeCategories = activeMonthData['byCategory'] as List? ?? [];
    final allSystemCategories = provider.categories;

    final List<Map<String, dynamic>> displayedCategories = [];
    for (var c in activeCategories) {
      displayedCategories.add({
        'category': c['category'],
        'total': _parseDouble(c['total']),
        'count': c['count'] ?? 0,
        'isActive': true,
      });
    }

    String? currentSelectedId = _selectedCategoryId;
    final existsInActive = activeCategories.any(
      (c) => c['category']['id'] == currentSelectedId,
    );
    if (!existsInActive || currentSelectedId == null) {
      if (activeCategories.isNotEmpty) {
        currentSelectedId = activeCategories[0]['category']['id'];
      } else {
        currentSelectedId = null;
      }
      _selectedCategoryId = currentSelectedId;
    }

    ExpenseCategory? selectedCategory;
    double selectedCategoryTotal = 0.0;
    double selectedCategoryPercentage = 0.0;

    if (currentSelectedId != null) {
      Map<String, dynamic>? activeMatch;
      for (var c in activeCategories) {
        if (c is Map &&
            c['category'] != null &&
            c['category']['id'] == currentSelectedId) {
          activeMatch = Map<String, dynamic>.from(c);
          break;
        }
      }

      ExpenseCategory? sysMatch;
      for (var cat in allSystemCategories) {
        if (cat.id == currentSelectedId) {
          sysMatch = cat;
          break;
        }
      }
      if (sysMatch == null && allSystemCategories.isNotEmpty) {
        sysMatch = allSystemCategories.first;
      }

      if (sysMatch != null) {
        selectedCategory = sysMatch;
        selectedCategoryTotal = activeMatch != null
            ? _parseDouble(activeMatch['total'])
            : 0.0;
        if (activeMonthTotal > 0) {
          selectedCategoryPercentage = selectedCategoryTotal / activeMonthTotal;
        }
      }
    }

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
    final routinePercent = totalSplitSpend > 0
        ? routineSpend / totalSplitSpend
        : 0.0;
    final nonRoutinePercent = totalSplitSpend > 0
        ? nonRoutineSpend / totalSplitSpend
        : 0.0;

    final prevMonthData = (filterIndex + 1 < monthsList.length)
        ? monthsList[filterIndex + 1] as Map<String, dynamic>
        : null;
    final insightMessage = _generateInsight(activeMonthData, prevMonthData);

    final chartMonths = List.from(monthsList.take(4)).reversed.toList();
    double maxMonthTotal = 0.0;
    for (var m in chartMonths) {
      final val = _parseDouble(m['total']);
      if (val > maxMonthTotal) {
        maxMonthTotal = val;
      }
    }

    return Scaffold(
      appBar: AnalyticsAppBar(
        provider: provider,
        responsive: responsive,
        onWalletSelected: _onWalletSelected,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (provider.isLoading || provider.isLoadingAnalytics)
              const LinearProgressIndicator(
                color: AppTheme.primary,
                backgroundColor: Color(0xFFF1F5F9),
                minHeight: 2,
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<DashboardBloc>().add(
                    const DashboardRefreshRequested(),
                  );
                },
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
                          const SizedBox(width: 8),
                          // Month Tabs
                          Flexible(
                            child: AnalyticsMonthTabs(
                              controller: _tabScrollController,
                              monthsList: monthsList,
                              activeFilterIndex: filterIndex,
                              onTabSelected: (index) {
                                setState(() {
                                  _activeFilterIndex = index;
                                });
                              },
                              monthYearFormatter: _formatMonthYear,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Overview Hero Card
                      AnalyticsOverviewCard(
                        totalSpend: activeMonthTotal,
                        hasComparison: hasComparison,
                        direction: direction,
                        changePercent: changePercent,
                        prevMonthLabel: prevMonthLabel,
                        currencyFormatter: currencyFormatter,
                        responsive: responsive,
                      ),
                      const SizedBox(height: 20),

                      // Spending Comparison Bar Chart
                      AnalyticsSpendingComparisonChart(
                        chartMonths: chartMonths,
                        monthsList: monthsList,
                        filterIndex: filterIndex,
                        maxMonthTotal: maxMonthTotal,
                        currencyFormatter: currencyFormatter,
                        monthYearFormatter: _formatMonthYear,
                        parseDouble: _parseDouble,
                      ),
                      const SizedBox(height: 24),

                      // Category Split Card
                      AnalyticsCategorySplitCard(
                        activeMonthData: activeMonthData,
                        activeMonthTotal: activeMonthTotal,
                        activeCategories: activeCategories,
                        displayedCategories: displayedCategories,
                        selectedCategoryId: currentSelectedId,
                        selectedCategory: selectedCategory,
                        selectedCategoryTotal: selectedCategoryTotal,
                        selectedCategoryPercentage: selectedCategoryPercentage,
                        currencyCode: currencyCode,
                        currencyFormatter: currencyFormatter,
                        onSelectCategory: (id) {
                          setState(() {
                            _selectedCategoryId = id;
                          });
                        },
                        onNavigateToCategoryDetails: _navigateToCategoryDetails,
                        parseHexColor: _parseHexColor,
                      ),
                      const SizedBox(height: 24),

                      // Routine vs Non-Routine Split Row
                      AnalyticsRoutineSplitRow(
                        routineSpend: routineSpend,
                        nonRoutineSpend: nonRoutineSpend,
                        routinePercent: routinePercent,
                        nonRoutinePercent: nonRoutinePercent,
                        currencyCode: currencyCode,
                      ),
                      const SizedBox(height: 24),

                      // Insight Card
                      AnalyticsInsightCard(
                        insightMessage: insightMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
