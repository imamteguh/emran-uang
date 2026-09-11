import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/expense.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../widgets/category_icon.dart';
import '../widgets/transaction_history/sticky_date_header_delegate.dart';
import '../widgets/transaction_history/transaction_calendar_filter_sheet.dart';
import '../widgets/transaction_history/transaction_detail_modal.dart';
import 'expense_entry_screen.dart';

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
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _criteria = TransactionFilterCriteria(
      startDate: widget.initialStartDate ?? today.subtract(const Duration(days: 30)),
      endDate: widget.initialEndDate ?? today,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCalendarFilter(BuildContext context, List<ExpenseCategory> categories) {
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

      // Type filter
      if (_criteria.type != null && expense.type != _criteria.type) {
        return false;
      }

      // Category filter
      if (_criteria.categoryId != null &&
          expense.category.id != _criteria.categoryId) {
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
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<String, List<ExpenseEntity>> _groupExpensesByDate(
      List<ExpenseEntity> expenses) {
    final Map<String, List<ExpenseEntity>> grouped = {};
    for (final exp in expenses) {
      final key = DateFormat('yyyy-MM-dd').format(exp.date);
      grouped.putIfAbsent(key, () => []).add(exp);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ExpenseEntryScreen(
                initialDate: DateTime.now(),
              ),
            ),
          );
          if (context.mounted) {
            context.read<DashboardBloc>().add(const DashboardRefreshRequested());
          }
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Catat Mutasi',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async {
            context.read<DashboardBloc>().add(const DashboardRefreshRequested());
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── 1. MyBCA Gradient App Bar ─────────────────────────────────
              SliverAppBar(
                expandedHeight: 120.0,
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFF003EA7),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isSearching ? Icons.close_rounded : Icons.search_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                    ),
                    tooltip: 'Filter Kalender (Maks 31 Hari)',
                    onPressed: () =>
                        _openCalendarFilter(context, provider.categories),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                  title: Text(
                    'Mutasi Rekening',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF004BC6),
                          Color(0xFF002D80),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── 2. Informasi Rekening & Ringkasan Card (MyBCA Style) ───────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF003EA7), Color(0xFF00225E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF003EA7).withAlpha(60),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Account Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  activeWallet?.name ?? 'Dompet Utama',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(35),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                provider.isSharedMode
                                    ? 'DOMPET BERSAMA'
                                    : 'TABUNGAN',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Masked Account / ID
                        Text(
                          'NO. REK: 8820 •••• ${activeWallet != null && activeWallet.id.length >= 4 ? activeWallet.id.substring(activeWallet.id.length - 4).toUpperCase() : "0000"}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12.5,
                            color: Colors.white70,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 14),

                        // Total Mutasi in Range
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL MUTASI (DEBIT)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white70,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '- ${currencyFormatter.format(totalExpenseAmount)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'DB',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${filteredExpenses.length} Transaksi',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Search Bar (if searching)
              if (_isSearching)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Cari berita, catatan, atau kategori...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),

              // ── 3. Sticky Filter & Period Bar (MyBCA Style) ───────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _FilterBarDelegate(
                  periodText: periodString,
                  dayCount: _criteria.dayCount,
                  selectedType: _criteria.type,
                  onCalendarTap: () =>
                      _openCalendarFilter(context, provider.categories),
                  onTypeSelected: (type) {
                    setState(() {
                      _criteria = _criteria.copyWith(
                        type: type,
                        clearType: type == null,
                      );
                    });
                  },
                ),
              ),

              // ── 4. Empty State or Grouped Sticky Date Lists ───────────────
              if (groupedExpenses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            size: 40,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak Ada Transaksi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tidak ada mutasi pada periode $periodString.\nMaksimal rentang tanggal adalah 31 hari.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _openCalendarFilter(context, provider.categories),
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
                          icon: const Icon(Icons.calendar_month_rounded, size: 18),
                          label: const Text('Ubah Filter Kalender'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Render sticky date groups
                for (final entry in groupedExpenses.entries)
                  SliverMainAxisGroup(
                    slivers: [
                      // Pinned Sticky Date Header
                      SliverPersistentHeader(
                        pinned: true,
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
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final expense = entry.value[index];
                            final formattedTime =
                                DateFormat('HH:mm').format(expense.date);
                            final catColor = Color(int.tryParse(expense
                                        .category.color
                                        .replaceFirst('#', '0xFF')) ??
                                    0xFF4F46E5);

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
                                                    style: GoogleFonts
                                                        .plusJakartaSans(
                                                      fontSize: 11.5,
                                                      color: const Color(
                                                          0xFF64748B),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  if (expense.type ==
                                                      ExpenseType.routine) ...[
                                                    const SizedBox(width: 4),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 5,
                                                        vertical: 1,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFFEFF6FF),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Text(
                                                        'Rutin',
                                                        style: GoogleFonts
                                                            .plusJakartaSans(
                                                          fontSize: 9.5,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: const Color(
                                                              0xFF1D4ED8),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              if (provider.isSharedMode &&
                                                  expense.creatorName.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  'oleh ${expense.creatorName}',
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 11,
                                                    color: const Color(
                                                        0xFF94A3B8),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),

                                        // Right amount & DB badge (MyBCA style)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '- ${currencyFormatter.format(expense.amount)}',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(
                                                    0xFFDC2626), // DB Red
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 5,
                                                vertical: 1,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEE2E2),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'DB',
                                                style: GoogleFonts
                                                    .plusJakartaSans(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                  color:
                                                      const Color(0xFFDC2626),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (index < entry.value.length - 1)
                                      const Padding(
                                        padding: EdgeInsets.only(
                                            left: 56, top: 12),
                                        child: Divider(
                                          height: 1,
                                          color: Color(0xFFF1F5F9),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: entry.value.length,
                        ),
                      ),
                    ],
                  ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Persistent Filter Bar Delegate ───────────────────────────────────────────

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final String periodText;
  final int dayCount;
  final ExpenseType? selectedType;
  final VoidCallback onCalendarTap;
  final ValueChanged<ExpenseType?> onTypeSelected;

  _FilterBarDelegate({
    required this.periodText,
    required this.dayCount,
    required this.selectedType,
    required this.onCalendarTap,
    required this.onTypeSelected,
  });

  @override
  double get minExtent => 60.0;

  @override
  double get maxExtent => 60.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: 60.0,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        boxShadow: shrinkOffset > 0 || overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Period Chip (opens Calendar Filter)
          InkWell(
            onTap: onCalendarTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 15,
                    color: Color(0xFF1D4ED8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$periodText ($dayCount H)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: Color(0xFF1D4ED8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Type Chips (Semua, Rutin, Non-Rutin)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTypeChip('Semua', null),
                  const SizedBox(width: 6),
                  _buildTypeChip('Rutin', ExpenseType.routine),
                  const SizedBox(width: 6),
                  _buildTypeChip('Non-Rutin', ExpenseType.nonRoutine),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, ExpenseType? type) {
    final isSelected = selectedType == type;
    return InkWell(
      onTap: () => onTypeSelected(type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.darkSlate,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FilterBarDelegate oldDelegate) {
    return oldDelegate.periodText != periodText ||
        oldDelegate.dayCount != dayCount ||
        oldDelegate.selectedType != selectedType;
  }
}
