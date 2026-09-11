import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/wallet.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../widgets/category_icon.dart';
import '../widgets/transaction_history/sticky_date_header_delegate.dart';
import '../widgets/transaction_history/transaction_calendar_filter_sheet.dart';
import '../widgets/transaction_history/transaction_detail_modal.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const TransactionHistoryScreen({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late TransactionFilterCriteria _criteria;
  final TextEditingController _searchController = TextEditingController();
  bool _isAmountVisible = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _criteria = TransactionFilterCriteria(
      startDate:
          widget.initialStartDate ?? today.subtract(const Duration(days: 30)),
      endDate: widget.initialEndDate ?? today,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCalendarFilter(
    BuildContext context,
    List<ExpenseCategory> categories,
  ) {
    TransactionCalendarFilterSheet.show(
      context,
      initialCriteria: _criteria,
      categories: categories,
      onApply: (newCriteria) {
        setState(() {
          _criteria = newCriteria;
        });
      },
    );
  }

  void _showWalletPicker(
    BuildContext context,
    DashboardBloc bloc,
    dynamic provider,
  ) {
    final personalWallets = provider.personalWallets as List<WalletEntity>;
    final sharedWallets = provider.sharedWallets as List<WalletEntity>;
    final activeWallet = provider.activeWallet as WalletEntity?;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pilih Dompet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const SizedBox(height: 16),
                if (personalWallets.isNotEmpty) ...[
                  Text(
                    'DOMPET PRIBADI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...personalWallets.map((wallet) {
                    final isSelected = activeWallet?.id == wallet.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withAlpha(25)
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.darkSlate,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        wallet.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.darkSlate,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.primary,
                            )
                          : null,
                      onTap: () {
                        bloc.add(DashboardSelectWalletRequested(wallet));
                        Navigator.of(ctx).pop();
                      },
                    );
                  }),
                ],
                if (sharedWallets.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'DOMPET BERSAMA',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...sharedWallets.map((wallet) {
                    final isSelected = activeWallet?.id == wallet.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withAlpha(25)
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.groups_outlined,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.darkSlate,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        wallet.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.darkSlate,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.primary,
                            )
                          : null,
                      onTap: () {
                        bloc.add(DashboardSelectWalletRequested(wallet));
                        Navigator.of(ctx).pop();
                      },
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<ExpenseEntity> _filterExpenses(List<ExpenseEntity> allExpenses) {
    final start = DateTime(
      _criteria.startDate.year,
      _criteria.startDate.month,
      _criteria.startDate.day,
      0,
      0,
      0,
    );
    final end = DateTime(
      _criteria.endDate.year,
      _criteria.endDate.month,
      _criteria.endDate.day,
      23,
      59,
      59,
      999,
    );

    final searchQuery = _searchController.text.trim().toLowerCase();

    return allExpenses.where((expense) {
      // Date range check
      if (expense.date.isBefore(start) || expense.date.isAfter(end)) {
        return false;
      }

      // Search query
      if (searchQuery.isNotEmpty) {
        final desc = expense.description?.toLowerCase() ?? '';
        final catName = expense.category.name.toLowerCase();
        if (!desc.contains(searchQuery) && !catName.contains(searchQuery)) {
          return false;
        }
      }

      return true;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<String, List<ExpenseEntity>> _groupExpensesByDate(
    List<ExpenseEntity> expenses,
  ) {
    final Map<String, List<ExpenseEntity>> grouped = {};
    for (final exp in expenses) {
      final key = DateFormat('yyyy-MM-dd').format(exp.date);
      grouped.putIfAbsent(key, () => []).add(exp);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DashboardBloc>();
    final provider = context.watch<DashboardBloc>().state;
    final authState = context.watch<AuthBloc>().state;
    final user = authState.currentUser;

    final activeWallet = provider.activeWallet;
    final currencyCode = activeWallet?.currency ?? 'IDR';
    final currencyFormatter = CurrencyHelper.getFormatter(currencyCode);

    final filteredExpenses = _filterExpenses(provider.expenses);
    final groupedExpenses = _groupExpensesByDate(filteredExpenses);

    final double totalExpenseAmount = filteredExpenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );

    final periodString =
        '${DateFormat('dd MMM yyyy', 'id_ID').format(_criteria.startDate)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(_criteria.endDate)}';

    return Scaffold(
      backgroundColor: const Color(
        0xFF10376D,
      ), // Top background matching brighter gradient
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async {
            bloc.add(const DashboardRefreshRequested());
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── Unified Sticky Top Section: Wallet Header + Collapsible Total + Sticky Filter Controls ──
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTransactionHeaderDelegate(
                  topPadding: MediaQuery.of(context).padding.top,
                  activeWallet: activeWallet,
                  onWalletTap: () => _showWalletPicker(context, bloc, provider),
                  isAmountVisible: _isAmountVisible,
                  onToggleAmount: () {
                    setState(() {
                      _isAmountVisible = !_isAmountVisible;
                    });
                  },
                  totalAmount: totalExpenseAmount,
                  currencyFormatter: currencyFormatter,
                  currencyCode: currencyCode,
                  periodString: periodString,
                  dayCount: _criteria.dayCount,
                  isSharedMode: provider.isSharedMode,
                  searchController: _searchController,
                  onSearchChanged: (_) => setState(() {}),
                  onClearSearch: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  onCalendarTap: () =>
                      _openCalendarFilter(context, provider.categories),
                  onBackTap: () => Navigator.of(context).pop(),
                ),
              ),

              // ── 4. Empty State or Grouped Date Lists ───────────────
              if (groupedExpenses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  fillOverscroll: true,
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.all(32.0),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFDBEAFE),
                              ),
                            ),
                            child: const Icon(
                              Icons.receipt_long_outlined,
                              size: 36,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak Ada Aktivitas',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkSlate,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tidak ada catatan transaksi pada periode $periodString.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: () => _openCalendarFilter(
                              context,
                              provider.categories,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(
                              Icons.calendar_month_rounded,
                              size: 18,
                            ),
                            label: const Text('Ubah Rentang Tanggal'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                // Render date groups (no TRX or DB bank terms)
                for (final entry in groupedExpenses.entries)
                  SliverMainAxisGroup(
                    slivers: [
                      // Section Date Header (scrolls under sticky top header)
                      SliverPersistentHeader(
                        pinned: false,
                        delegate: StickyDateHeaderDelegate(
                          date: DateTime.parse(entry.key),
                          count: entry.value.length,
                          totalAmount: entry.value.fold(
                            0.0,
                            (sum, e) => sum + e.amount,
                          ),
                          currencyFormatter: currencyFormatter,
                        ),
                      ),

                      // List of transactions for this date
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final expense = entry.value[index];
                          final formattedTime = DateFormat(
                            'HH:mm',
                          ).format(expense.date);
                          final catColor = Color(
                            int.tryParse(
                                  expense.category.color.replaceFirst(
                                    '#',
                                    '0xFF',
                                  ),
                                ) ??
                                0xFF4F46E5,
                          );

                          return InkWell(
                            onTap: () => TransactionDetailModal.show(
                              context,
                              expense: expense,
                              provider: provider,
                              currentUserId: user?.id,
                              currencyFormatter: currencyFormatter,
                            ),
                            child: Container(
                              color: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Category icon
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: catColor.withAlpha(25),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: CategoryIcon(
                                            icon: expense.category.icon,
                                            color: catColor,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      // Center details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (expense.description != null &&
                                                      expense.description!
                                                          .trim()
                                                          .isNotEmpty)
                                                  ? expense.description!.trim()
                                                  : expense.category.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.darkSlate,
                                                  ),
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                Text(
                                                  '$formattedTime WIB • ${expense.category.name}',
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                        fontSize: 11.5,
                                                        color: const Color(
                                                          0xFF64748B,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                                if (expense.type ==
                                                    ExpenseType.routine) ...[
                                                  const SizedBox(width: 4),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 5,
                                                          vertical: 1,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFEFF6FF,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'Rutin',
                                                      style:
                                                          GoogleFonts.plusJakartaSans(
                                                            fontSize: 9.5,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: const Color(
                                                              0xFF1D4ED8,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (provider.isSharedMode &&
                                                expense
                                                    .creatorName
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'oleh ${expense.creatorName}',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                      fontSize: 11,
                                                      color: const Color(
                                                        0xFF94A3B8,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Right amount (clean, without bank DB badge)
                                      Text(
                                        '- ${currencyFormatter.format(expense.amount)}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (index < entry.value.length - 1)
                                    const Padding(
                                      padding: EdgeInsets.only(
                                        left: 56,
                                        top: 12,
                                      ),
                                      child: Divider(
                                        height: 1,
                                        color: Color(0xFFF1F5F9),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }, childCount: entry.value.length),
                      ),
                    ],
                  ),

                // Fill remaining space with solid white background to eliminate any bottom gap
                SliverFillRemaining(
                  hasScrollBody: false,
                  fillOverscroll: true,
                  child: Container(
                    color: Colors.white,
                    child: const SafeArea(
                      top: false,
                      child: SizedBox(height: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyTransactionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final WalletEntity? activeWallet;
  final VoidCallback onWalletTap;
  final bool isAmountVisible;
  final VoidCallback onToggleAmount;
  final double totalAmount;
  final NumberFormat currencyFormatter;
  final String currencyCode;
  final String periodString;
  final int dayCount;
  final bool isSharedMode;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onCalendarTap;
  final VoidCallback onBackTap;

  _StickyTransactionHeaderDelegate({
    required this.topPadding,
    required this.activeWallet,
    required this.onWalletTap,
    required this.isAmountVisible,
    required this.onToggleAmount,
    required this.totalAmount,
    required this.currencyFormatter,
    required this.currencyCode,
    required this.periodString,
    required this.dayCount,
    required this.isSharedMode,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onCalendarTap,
    required this.onBackTap,
  });

  static const double _appBarHeight = 44.0;
  static const double _walletHeaderHeight = 54.0;
  static const double _collapsibleCardHeight = 104.0;
  static const double _filterHeight = 58.0;

  @override
  double get minExtent =>
      topPadding + _appBarHeight + 6.0 + _walletHeaderHeight + _filterHeight;

  @override
  double get maxExtent => minExtent + _collapsibleCardHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final collapseDistance = maxExtent - minExtent;
    final progress = collapseDistance > 0
        ? (shrinkOffset / collapseDistance).clamp(0.0, 1.0)
        : 0.0;

    final collapsibleHeight = (1.0 - progress) * _collapsibleCardHeight;
    final collapsibleOpacity = (1.0 - progress).clamp(0.0, 1.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF10376D), // Rich navy-blue
            Color(0xFF1E58A8), // Lighter royal cobalt blue
          ],
        ),
      ),
      child: Column(
        children: [
          // 1. Top Safe Area Padding
          // const SizedBox(height: topPadding),

          // 2. AppBar Row (Back button + "Riwayat Aktivitas")
          SizedBox(
            height: _appBarHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: onBackTap,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Riwayat Aktivitas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),

          // 3. Card Container (Sticky Top Wallet Selector + Collapsible Bottom)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.10 + 0.08 * (1.0 - progress),
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Upper Card: Wallet Selector (Always sticky with border radius)
                  InkWell(
                    onTap: onWalletTap,
                    borderRadius: BorderRadius.vertical(
                      top: const Radius.circular(16),
                      bottom: Radius.circular(16 * progress),
                    ),
                    child: Container(
                      height: _walletHeaderHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xFF163E78),
                        borderRadius: BorderRadius.vertical(
                          top: const Radius.circular(16),
                          bottom: Radius.circular(16 * progress),
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Nama Dompet',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activeWallet?.name ?? 'Dompet Utama',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Lower Card: Total Pengeluaran (Collapses smoothly as user scrolls)
                  if (progress < 1.0)
                    ClipRect(
                      child: SizedBox(
                        height: collapsibleHeight,
                        child: Opacity(
                          opacity: collapsibleOpacity,
                          child: OverflowBox(
                            minHeight: 0,
                            maxHeight: _collapsibleCardHeight,
                            alignment: Alignment.topCenter,
                            child: Container(
                              height: _collapsibleCardHeight,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(16),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Total Pengeluaran',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isAmountVisible
                                            ? currencyFormatter.format(
                                                totalAmount,
                                              )
                                            : '$currencyCode ••••••••',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.darkSlate,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: onToggleAmount,
                                        borderRadius: BorderRadius.circular(20),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Icon(
                                            isAmountVisible
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: const Color(0xFF004BC6),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${isSharedMode ? "Dompet Bersama" : "Dompet Pribadi"} • $periodString ($dayCount Hari)',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: topPadding),

          // 4. Filter Control Area (Search + Calendar - Sticky with rounded top)
          Container(
            height: _filterHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24 - 8 * progress),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, -2),
                  blurRadius: 6,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                // Search Input Field
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: searchController,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.darkSlate,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                padding: EdgeInsets.zero,
                                onPressed: onClearSearch,
                              )
                            : null,
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: onSearchChanged,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Calendar Filter Button
                InkWell(
                  onTap: onCalendarTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTransactionHeaderDelegate oldDelegate) {
    return true;
  }
}
