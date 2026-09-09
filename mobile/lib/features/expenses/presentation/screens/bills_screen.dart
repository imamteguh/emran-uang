import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../widgets/bills_skeleton.dart';
import '../widgets/bills/bills.dart';

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final dashboardBloc = context.watch<DashboardBloc>();
    final dashboardState = dashboardBloc.state;
    final currencyCode = dashboardState.activeWallet?.currency ?? 'IDR';
    final currencyFormatter = CurrencyHelper.getFormatter(currencyCode);

    final summary = BillsSummaryData.fromReminders(dashboardState.reminders);

    return Scaffold(
      appBar: BillsAppBar(
        dashboardState: dashboardState,
        responsive: responsive,
        onWalletSelected: (wallet) {
          dashboardBloc.add(DashboardSelectWalletRequested(wallet));
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (dashboardState.isLoading)
              const LinearProgressIndicator(
                color: AppTheme.primary,
                backgroundColor: Color(0xFFF1F5F9),
                minHeight: 2,
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  dashboardBloc.add(const DashboardFetchRemindersRequested());
                },
                color: AppTheme.primary,
                child: dashboardState.isLoading && summary.activeReminders.isEmpty
                    ? const SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: BillsSkeleton(),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: responsive.screenPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Summary Header
                            Text(
                              'Daftar Tagihan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: responsive.scaleFont(28),
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkSlate,
                              ),
                            ),
                            const SizedBox(height: 12),
                            BillsAlertBanner(
                              overdueBills: summary.overdueBills,
                              dueTodayBills: summary.dueTodayBills,
                              dueSoonBills: summary.dueSoonBills,
                              currencyFormatter: currencyFormatter,
                              responsive: responsive,
                            ),
                            const SizedBox(height: 20),

                            // Bento Outflow Card
                            BillsOutflowCard(
                              totalMonthlyOutflow: summary.totalMonthlyOutflow,
                              currencyFormatter: currencyFormatter,
                              responsive: responsive,
                            ),
                            const SizedBox(height: 16),

                            // Paid vs Pending Side-by-side Bento Cards
                            BillsPaidPendingCard(
                              paidThisMonth: summary.paidThisMonth,
                              pendingThisMonth: summary.pendingThisMonth,
                              currencyFormatter: currencyFormatter,
                            ),
                            const SizedBox(height: 32),

                            // Monthly/Regular Bills Section
                            BillsSectionHeader(
                              title: 'Tagihan Bulanan',
                              responsive: responsive,
                              onAdd: () => BillActionsHelper.showAddEditBillDialog(
                                context: context,
                              ),
                            ),
                            const SizedBox(height: 8),

                            if (summary.regularBills.isEmpty)
                              const BillsEmptyState(
                                icon: Icons.receipt_long_outlined,
                                title: 'Belum ada tagihan bulanan',
                                description:
                                    'Tekan "Tambah" untuk mencatat tagihan listrik, internet, kos, dsb.',
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: summary.regularBills.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, index) {
                                  final bill = summary.regularBills[index];
                                  return BillCardItem(
                                    reminder: bill,
                                    formatter: currencyFormatter,
                                    onTap: () =>
                                        BillActionsHelper.showReminderOptions(
                                      context: context,
                                      reminder: bill,
                                      formatter: currencyFormatter,
                                      provider: dashboardState,
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 32),

                            // Annual Renewals Section
                            BillsSectionHeader(
                              title: 'Tagihan Tahunan',
                              responsive: responsive,
                            ),
                            const SizedBox(height: 16),

                            if (summary.annualRenewals.isEmpty)
                              const BillsEmptyState(
                                icon: Icons.calendar_today_outlined,
                                title: 'Belum ada tagihan tahunan',
                                description:
                                    'Tagihan tahunan seperti pajak kendaraan, domain, atau asuransi akan muncul di sini.',
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: summary.annualRenewals.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, index) {
                                  final bill = summary.annualRenewals[index];
                                  return BillCardItem(
                                    reminder: bill,
                                    formatter: currencyFormatter,
                                    onTap: () =>
                                        BillActionsHelper.showReminderOptions(
                                      context: context,
                                      reminder: bill,
                                      formatter: currencyFormatter,
                                      provider: dashboardState,
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 24),
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
