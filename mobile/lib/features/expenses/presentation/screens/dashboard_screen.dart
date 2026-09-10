import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../widgets/dashboard/dashboard.dart';
import '../widgets/dashboard_skeleton.dart';
import 'activity_list_screen.dart';
import 'ocr_scan_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DashboardBloc>();
    final provider = context.watch<DashboardBloc>().state;
    final authState = context.watch<AuthBloc>().state;
    final user = authState.currentUser;
    final responsive = ResponsiveHelper(context);

    final currencyCode = provider.activeWallet?.currency ?? 'IDR';
    final currencyFormatter = CurrencyHelper.getFormatter(currencyCode);

    return Scaffold(
      appBar: DashboardAppBar(
        provider: provider,
        responsive: responsive,
        onWalletSelected: (wallet) {
          bloc.add(DashboardSelectWalletRequested(wallet));
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            bloc.add(const DashboardRefreshRequested());
          },
          child: provider.isInitialLoad
              ? const SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: DashboardSkeleton(),
                )
              : Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double horizontalPadding = responsive.scale(16);

                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Daily Spending Hero Card
                              DailySpendingHeroCard(
                                provider: provider,
                                responsive: responsive,
                                formatter: currencyFormatter,
                              ),
                              const SizedBox(height: 16),

                              // Monthly Budget Card
                              MonthlyBudgetCard(
                                provider: provider,
                                responsive: responsive,
                                formatter: currencyFormatter,
                              ),
                              const SizedBox(height: 20),

                              // Bill Alert Banner
                              DashboardBillAlertBanner(
                                provider: provider,
                                responsive: responsive,
                                currencyFormatter: currencyFormatter,
                              ),

                              // Bento Stats Grid (Monthly Savings & Top Category)
                              DashboardBentoGrid(
                                provider: provider,
                                responsive: responsive,
                                formatter: currencyFormatter,
                              ),
                              const SizedBox(height: 20),

                              // AI Chat Quick Input Card
                              DashboardAiQuickCard(responsive: responsive),
                              const SizedBox(height: 24),

                              // Today activity section header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Today Activity',
                                    style: AppTheme.headlineSm.copyWith(
                                      fontSize: responsive.scaleFont(20),
                                      color: AppTheme.darkSlate,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ActivityListScreen(),
                                      ),
                                    ),
                                    child: Text(
                                      'See all',
                                      style: AppTheme.labelMd.copyWith(
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Today Expenses Feed
                              DashboardActivityFeed(
                                expenses: provider.todayExpenses,
                                responsive: responsive,
                                formatter: currencyFormatter,
                                currentUserId: user?.id,
                                provider: provider,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Subtle loading indicator for background refreshes
                    if (provider.isLoading)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          color: AppTheme.primary.withAlpha(120),
                          minHeight: 2,
                        ),
                      ),
                  ],
                ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    OcrScanScreen(initialWallet: provider.activeWallet),
              ),
            );
          },
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          tooltip: 'Scan Receipt with AI',
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.document_scanner_rounded, size: 26),
        ),
      ),
    );
  }
}
