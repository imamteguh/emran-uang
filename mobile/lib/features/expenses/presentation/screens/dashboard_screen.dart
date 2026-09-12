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
import 'shared_groups_screen.dart';

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
      backgroundColor: const Color(0xFF0F172A), // Top background color (Navy)
      appBar: DashboardAppBar(
        provider: provider,
        responsive: responsive,
        onWalletSelected: (wallet) {
          bloc.add(DashboardSelectWalletRequested(wallet));
        },
        onManageGroups: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SharedGroupsScreen(),
            ),
          );
        },
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppTheme.primary,
          backgroundColor: Colors.white,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── TOP SECTION (Dark Navy Background) ─────────────────
                              Container(
                                color: const Color(0xFF0F172A),
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  8,
                                  horizontalPadding,
                                  20,
                                ),
                                child: MonthlySpendingLineChartHero(
                                  provider: provider,
                                  responsive: responsive,
                                  formatter: currencyFormatter,
                                ),
                              ),

                              // ── BOTTOM SECTION (Modern Light Surface) ──────────────
                              Container(
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  color: Color(
                                    0xFFF8FAFC,
                                  ), // Second background color
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(28),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      offset: Offset(0, -3),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  20,
                                  horizontalPadding,
                                  36,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Alert Tagihan Jatuh Tempo (Overdue, Today, Soon)
                                    DashboardBillAlertBanner(
                                      provider: provider,
                                      responsive: responsive,
                                      currencyFormatter: currencyFormatter,
                                    ),

                                    // Pengeluaran per Kategori Donat Chart (Top 5)
                                    CategoryDonutChartCard(
                                      provider: provider,
                                      responsive: responsive,
                                      formatter: currencyFormatter,
                                    ),
                                    const SizedBox(height: 16),

                                    // Pengeluaran Rutin & Non-Rutin Card
                                    RoutineSpendingCard(
                                      provider: provider,
                                      responsive: responsive,
                                      formatter: currencyFormatter,
                                    ),
                                    const SizedBox(height: 16),

                                    // Anggaran Bulanan per Kategori
                                    CategoryMonthlyBudgetCard(
                                      provider: provider,
                                      responsive: responsive,
                                      formatter: currencyFormatter,
                                    ),
                                    const SizedBox(height: 16),

                                    // AI Chat Quick Input Card
                                    DashboardAiQuickCard(
                                      responsive: responsive,
                                    ),
                                    const SizedBox(height: 24),

                                    // Today transaction section header
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Transaksi Hari Ini',
                                          style: AppTheme.headlineSm.copyWith(
                                            fontSize: responsive.scaleFont(18),
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.darkSlate,
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
                          color: const Color(0xFF38BDF8),
                          minHeight: 2,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
