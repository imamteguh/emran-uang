import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/bills_skeleton.dart';
import '../widgets/bills/bills.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  // 0: Tagihan, 1: Anggaran
  int _selectedTab = 0;

  // Filter Tagihan: 0: Semua, 1: Belum Bayar, 2: Lunas, 3: Jatuh Tempo
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final dashboardBloc = context.watch<DashboardBloc>();
    final dashboardState = dashboardBloc.state;
    final currencyCode = dashboardState.activeWallet?.currency ?? 'IDR';
    final currencyFormatter = CurrencyHelper.getFormatter(currencyCode);

    final summary = BillsSummaryData.fromReminders(dashboardState.reminders);
    final double horizontalPadding = responsive.scale(16);

    final unpaidBills = summary.activeReminders
        .where((b) => !b.isPaidForCurrentPeriod)
        .toList();
    final paidBills = summary.activeReminders
        .where((b) => b.isPaidForCurrentPeriod)
        .toList();
    final urgentBills = [
      ...summary.overdueBills,
      ...summary.dueTodayBills,
      ...summary.dueSoonBills,
    ];

    final int totalCategoryBudgets =
        dashboardState.categoryBudgetStatuses.length;

    return Scaffold(
      backgroundColor: const Color(
        0xFF0F172A,
      ), // Latar belakang utama atas (Dark Navy)
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Tagihan & Anggaran',
          style: GoogleFonts.plusJakartaSans(
            fontSize: responsive.scaleFont(19),
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Segarkan',
            onPressed: () {
              dashboardBloc.add(const DashboardFetchRemindersRequested());
              dashboardBloc.add(const DashboardFetchCategoriesRequested());
              dashboardBloc.add(const DashboardRefreshRequested());
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (dashboardState.isLoading)
              const LinearProgressIndicator(
                color: AppTheme.primary,
                backgroundColor: Color(0xFF1E293B),
                minHeight: 2,
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  dashboardBloc.add(const DashboardFetchRemindersRequested());
                  dashboardBloc.add(const DashboardFetchCategoriesRequested());
                  dashboardBloc.add(const DashboardRefreshRequested());
                },
                color: AppTheme.primary,
                backgroundColor: Colors.white,
                child:
                    dashboardState.isLoading &&
                        summary.activeReminders.isEmpty &&
                        dashboardState.categoryBudgetStatuses.isEmpty
                    ? const SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: BillsSkeleton(),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── LATAR BELAKANG 1: TOP HEADER SECTION (DARK NAVY) ───────
                            Container(
                              color: const Color(0xFF0F172A),
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                4,
                                horizontalPadding,
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. CARD NAMA DOMPET (SEPERTI RIWAYAT AKTIVITAS)
                                  BillsWalletCard(
                                    provider: dashboardState,
                                    bloc: dashboardBloc,
                                  ),
                                  const SizedBox(height: 12),

                                  // 2. TAB SWITCHER (SOLID NON-FLOATING SELECTION)
                                  _buildTabBar(
                                    billCount: summary.activeReminders.length,
                                    budgetCount: totalCategoryBudgets,
                                    responsive: responsive,
                                  ),
                                ],
                              ),
                            ),

                            // ── LATAR BELAKANG 2: MAIN CONTENT (LIGHT SURFACE) ─────
                            Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                20,
                                horizontalPadding,
                                24, // Padding bawah rapi tanpa FAB
                              ),
                              child: _selectedTab == 0
                                  ? _buildBillsTabContent(
                                      context: context,
                                      summary: summary,
                                      unpaidBills: unpaidBills,
                                      paidBills: paidBills,
                                      urgentBills: urgentBills,
                                      currencyFormatter: currencyFormatter,
                                      responsive: responsive,
                                      dashboardState: dashboardState,
                                    )
                                  : _buildBudgetTabContent(
                                      dashboardState: dashboardState,
                                      currencyFormatter: currencyFormatter,
                                      responsive: responsive,
                                    ),
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

  /// Modern Non-Floating Tab Bar Switcher di Header Dark Navy
  Widget _buildTabBar({
    required int billCount,
    required int budgetCount,
    required ResponsiveHelper responsive,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Tab 0: Tagihan
          Expanded(
            child: InkWell(
              onTap: () {
                if (_selectedTab != 0) {
                  setState(() => _selectedTab = 0);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? AppTheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTab == 0
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 16,
                      color: _selectedTab == 0
                          ? Colors.white
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Tagihan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: _selectedTab == 0
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: _selectedTab == 0
                            ? Colors.white
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    if (billCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0
                              ? Colors.white.withValues(alpha: 0.25)
                              : const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$billCount',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 0
                                ? Colors.white
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Tab 1: Anggaran
          Expanded(
            child: InkWell(
              onTap: () {
                if (_selectedTab != 1) {
                  setState(() => _selectedTab = 1);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? AppTheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTab == 1
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_rounded,
                      size: 16,
                      color: _selectedTab == 1
                          ? Colors.white
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Anggaran',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: _selectedTab == 1
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: _selectedTab == 1
                            ? Colors.white
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    if (budgetCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1
                              ? Colors.white.withValues(alpha: 0.25)
                              : const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$budgetCount',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 1
                                ? Colors.white
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ringkasan Anggaran Kategori pada Latar Belakang Putih
  Widget _buildCategoryBudgetHeroCard({
    required DashboardState dashboardState,
    required dynamic currencyFormatter,
    required ResponsiveHelper responsive,
  }) {
    final limit = dashboardState.totalCategoryBudgetLimit;
    final spend = dashboardState.totalCategoryBudgetSpend;
    final remaining = dashboardState.totalCategoryBudgetRemaining;
    final hasBudgets = limit > 0;
    final percent = (dashboardState.totalCategoryBudgetPercent * 100).round();
    final isOver = dashboardState.isOverTotalCategoryBudget;
    final count = dashboardState.categoryBudgetStatuses.length;

    final Color statusColor = isOver
        ? const Color(0xFFF43F5E)
        : (percent >= 80 ? const Color(0xFFF59E0B) : const Color(0xFF10B981));
    final String statusText = isOver
        ? 'Overbudget'
        : (percent >= 80 ? 'Mendekati Batas' : 'Aman');

    final Color statusBg = isOver
        ? const Color(0xFFFEE2E2)
        : (percent >= 80 ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7));

    final Color statusBorder = isOver
        ? const Color(0xFFFECDD3)
        : (percent >= 80 ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: const Icon(
                      Icons.pie_chart_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Anggaran Kategori ($count)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        hasBudgets
                            ? currencyFormatter.format(limit)
                            : 'Belum Ditetapkan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (hasBudgets)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (hasBudgets) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (spend / limit).clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 7,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Terpakai: ${currencyFormatter.format(spend)} ($percent%)',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  isOver
                      ? 'Lebih: ${currencyFormatter.format(spend - limit)}'
                      : 'Sisa: ${currencyFormatter.format(remaining)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isOver
                        ? const Color(0xFFF43F5E)
                        : const Color(0xFF0284C7),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'Tetapkan batas anggaran untuk tiap kategori pada daftar di bawah.',
              style: GoogleFonts.beVietnamPro(
                fontSize: 11.5,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Konten Tab 0: Tagihan (Seluruhnya pada Latar Belakang Putih)
  Widget _buildBillsTabContent({
    required BuildContext context,
    required BillsSummaryData summary,
    required List<dynamic> unpaidBills,
    required List<dynamic> paidBills,
    required List<dynamic> urgentBills,
    required dynamic currencyFormatter,
    required ResponsiveHelper responsive,
    required dynamic dashboardState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul & Deskripsi Header dengan Tombol Tambah
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengingat & Tagihan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: responsive.scaleFont(20),
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkSlate,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola komitmen rutin dan pantau pengeluaran tagihan',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: responsive.scaleFont(12),
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => BillActionsHelper.showAddEditBillDialog(
                context: context,
              ),
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
                color: AppTheme.primary,
              ),
              label: Text(
                'Tambah',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Alert Banner Tagihan Jatuh Tempo / Mendekati (isDarkBackground: false)
        BillsAlertBanner(
          overdueBills: summary.overdueBills,
          dueTodayBills: summary.dueTodayBills,
          dueSoonBills: summary.dueSoonBills,
          currencyFormatter: currencyFormatter,
          responsive: responsive,
          isDarkBackground: false,
        ),

        const SizedBox(height: 14),

        // Bento Card: Total Estimasi Tagihan Bulanan (isDarkBackground: false)
        BillsOutflowCard(
          totalMonthlyOutflow: summary.totalMonthlyOutflow,
          currencyFormatter: currencyFormatter,
          responsive: responsive,
          isDarkBackground: false,
        ),
        const SizedBox(height: 12),

        // Bento Cards: Sudah Dibayar vs Belum Dibayar (isDarkBackground: false)
        BillsPaidPendingCard(
          paidThisMonth: summary.paidThisMonth,
          pendingThisMonth: summary.pendingThisMonth,
          currencyFormatter: currencyFormatter,
          isDarkBackground: false,
        ),
        const SizedBox(height: 20),

        // FILTER CHIPS (Semua, Belum Bayar, Lunas, Jatuh Tempo)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                index: 0,
                label: 'Semua',
                count: summary.activeReminders.length,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                index: 1,
                label: 'Belum Bayar',
                count: unpaidBills.length,
                accentColor: const Color(0xFFF43F5E),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                index: 2,
                label: 'Lunas',
                count: paidBills.length,
                accentColor: const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                index: 3,
                label: 'Jatuh Tempo',
                count: urgentBills.length,
                accentColor: const Color(0xFFEA580C),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // KONTEN DAFTAR TAGIHAN SESUAI FILTER
        _buildFilteredList(
          context: context,
          summary: summary,
          unpaidBills: unpaidBills,
          paidBills: paidBills,
          urgentBills: urgentBills,
          currencyFormatter: currencyFormatter,
          responsive: responsive,
          dashboardState: dashboardState,
        ),
      ],
    );
  }

  /// Konten Tab 1: Anggaran (Seluruhnya pada Latar Belakang Putih)
  Widget _buildBudgetTabContent({
    required DashboardState dashboardState,
    required dynamic currencyFormatter,
    required ResponsiveHelper responsive,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul & Deskripsi Header
        Text(
          'Anggaran per Kategori',
          style: GoogleFonts.plusJakartaSans(
            fontSize: responsive.scaleFont(20),
            fontWeight: FontWeight.w800,
            color: AppTheme.darkSlate,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Atur dan pantau batas pengeluaran untuk setiap kategori',
          style: GoogleFonts.beVietnamPro(
            fontSize: responsive.scaleFont(12),
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 14),

        // Ringkasan Anggaran Kategori (White Card)
        _buildCategoryBudgetHeroCard(
          dashboardState: dashboardState,
          currencyFormatter: currencyFormatter,
          responsive: responsive,
        ),
        const SizedBox(height: 24),

        // Daftar Anggaran Kategori
        BudgetManagementView(
          provider: dashboardState,
          currencyFormatter: currencyFormatter,
          responsive: responsive,
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required int index,
    required String label,
    required int count,
    Color? accentColor,
  }) {
    final isSelected = _selectedFilter == index;
    final color = accentColor ?? AppTheme.primary;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.darkSlate,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.darkSlateVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredList({
    required BuildContext context,
    required BillsSummaryData summary,
    required List<dynamic> unpaidBills,
    required List<dynamic> paidBills,
    required List<dynamic> urgentBills,
    required dynamic currencyFormatter,
    required ResponsiveHelper responsive,
    required dynamic dashboardState,
  }) {
    switch (_selectedFilter) {
      case 1: // Belum Bayar
        if (unpaidBills.isEmpty) {
          return const BillsEmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'Semua Tagihan Sudah Lunas',
            description:
                'Hebat! Seluruh tagihan aktif Anda telah tercatat lunas untuk periode ini.',
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: unpaidBills.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final bill = unpaidBills[index];
            return BillCardItem(
              reminder: bill,
              formatter: currencyFormatter,
              onTap: () => BillActionsHelper.showReminderOptions(
                context: context,
                reminder: bill,
                formatter: currencyFormatter,
                provider: dashboardState,
              ),
            );
          },
        );

      case 2: // Lunas
        if (paidBills.isEmpty) {
          return const BillsEmptyState(
            icon: Icons.hourglass_empty_rounded,
            title: 'Belum Ada Tagihan Lunas',
            description:
                'Tagihan yang sudah dibayar pada periode ini akan muncul di sini.',
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: paidBills.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final bill = paidBills[index];
            return BillCardItem(
              reminder: bill,
              formatter: currencyFormatter,
              onTap: () => BillActionsHelper.showReminderOptions(
                context: context,
                reminder: bill,
                formatter: currencyFormatter,
                provider: dashboardState,
              ),
            );
          },
        );

      case 3: // Jatuh Tempo
        if (urgentBills.isEmpty) {
          return const BillsEmptyState(
            icon: Icons.verified_rounded,
            title: 'Tidak Ada Tagihan Mendesak',
            description:
                'Tidak ada tagihan yang terlambat atau mendekati jatuh tempo saat ini.',
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: urgentBills.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final bill = urgentBills[index];
            return BillCardItem(
              reminder: bill,
              formatter: currencyFormatter,
              onTap: () => BillActionsHelper.showReminderOptions(
                context: context,
                reminder: bill,
                formatter: currencyFormatter,
                provider: dashboardState,
              ),
            );
          },
        );

      case 0: // Semua
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly/Regular Bills Section
            BillsSectionHeader(
              title: 'Tagihan Bulanan',
              responsive: responsive,
              onAdd: () =>
                  BillActionsHelper.showAddEditBillDialog(context: context),
            ),
            const SizedBox(height: 10),

            if (summary.regularBills.isEmpty)
              BillsEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada tagihan bulanan',
                description:
                    'Tekan "Tambah" untuk mencatat tagihan listrik, internet, kos, dsb.',
                actionLabel: 'Tambah Tagihan',
                onAction: () =>
                    BillActionsHelper.showAddEditBillDialog(context: context),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: summary.regularBills.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final bill = summary.regularBills[index];
                  return BillCardItem(
                    reminder: bill,
                    formatter: currencyFormatter,
                    onTap: () => BillActionsHelper.showReminderOptions(
                      context: context,
                      reminder: bill,
                      formatter: currencyFormatter,
                      provider: dashboardState,
                    ),
                  );
                },
              ),
            const SizedBox(height: 28),

            // Annual Renewals Section
            BillsSectionHeader(
              title: 'Tagihan Tahunan & Langganan',
              responsive: responsive,
            ),
            const SizedBox(height: 10),

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
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final bill = summary.annualRenewals[index];
                  return BillCardItem(
                    reminder: bill,
                    formatter: currencyFormatter,
                    onTap: () => BillActionsHelper.showReminderOptions(
                      context: context,
                      reminder: bill,
                      formatter: currencyFormatter,
                      provider: dashboardState,
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
        );
    }
  }
}
