import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/wallet.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../widgets/category_icon.dart';
import 'expense_entry_screen.dart';

class CategoryMonthlyExpensesScreen extends StatefulWidget {
  final ExpenseCategory category;
  final String monthStr; // format: YYYY-MM
  final String walletId;
  final String walletName;
  final String currencyCode;

  const CategoryMonthlyExpensesScreen({
    super.key,
    required this.category,
    required this.monthStr,
    required this.walletId,
    required this.walletName,
    required this.currencyCode,
  });

  @override
  State<CategoryMonthlyExpensesScreen> createState() =>
      _CategoryMonthlyExpensesScreenState();
}

class _CategoryMonthlyExpensesScreenState
    extends State<CategoryMonthlyExpensesScreen> {
  List<ExpenseEntity> _expenses = [];
  bool _isLoading = true;
  bool _isError = false;
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final response = await DioClient().dio.get(
        '/expenses',
        queryParameters: {
          'walletId': widget.walletId,
          'timeframe': 'monthly',
          'date': widget.monthStr,
          'categoryId': widget.category.id,
          'limit': 100, // Load all transactions for this category this month
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final list = response.data['data'] as List;
        final fetchedExpenses =
            list.map((item) => ExpenseEntity.fromJson(item as Map)).toList();

        if (mounted) {
          setState(() {
            _expenses = fetchedExpenses;
            _totalAmount = fetchedExpenses.fold(
                0.0, (sum, expense) => sum + expense.amount);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isError = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading category expenses: $e');
      if (mounted) {
        setState(() {
          _isError = true;
          _isLoading = false;
        });
      }
    }
  }

  String _formatMonthYear(String monthStr) {
    try {
      final parts = monthStr.split('-');
      final year = parts[0];
      final month = int.parse(parts[1]);
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      return '${months[month - 1]} $year';
    } catch (_) {
      return monthStr;
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Transaction',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.darkSlate,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.darkSlateVariant,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.darkSlateVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Delete',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddExpense() async {
    final now = DateTime.now();
    final parts = widget.monthStr.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    DateTime initialDate;
    if (year == now.year && month == now.month) {
      initialDate = now;
    } else {
      initialDate = DateTime(year, month, 1);
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseEntryScreen(
          initialDate: initialDate,
          initialCategory: widget.category,
        ),
      ),
    );
    _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState.currentUser;
    final dashboardState = context.watch<DashboardBloc>().state;
    final activeWallet = dashboardState.activeWallet;

    final currencyFormatter = CurrencyHelper.getFormatter(widget.currencyCode);
    final catColor = Color(
      int.parse(widget.category.color.replaceFirst('#', '0xFF')),
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.darkSlate,
          ),
        ),
        title: Text(
          'Monthly Details',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.darkSlate,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadExpenses,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
            tooltip: 'Refresh list',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadExpenses,
          color: AppTheme.primary,
          child: _isLoading
              ? const CategoryExpensesSkeleton()
              : _isError
                  ? _buildErrorState()
                  : _expenses.isEmpty
                      ? _buildEmptyState()
                      : ListView(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          // Category Header Card
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AppTheme.roundedBorder,
                              boxShadow: AppTheme.softShadow,
                              border: Border(
                                left: BorderSide(color: catColor, width: 6.0),
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: catColor.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: CategoryIcon(
                                    icon: widget.category.icon,
                                    color: catColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.category.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.darkSlate,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatMonthYear(widget.monthStr),
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 13,
                                          color: AppTheme.darkSlateVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'TOTAL SPEND',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.darkSlateVariant,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currencyFormatter.format(_totalAmount),
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
                          ),
                          const SizedBox(height: 24),

                          // Transactions List Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Transactions (${_expenses.length})',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.darkSlate,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withAlpha(15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.walletName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Transactions Items
                          ..._expenses.map((expense) {
                            final isPersonalWallet =
                                activeWallet?.type == WalletType.personal;
                            final isCreator =
                                user != null && expense.userId == user.id;
                            final isOwner = isPersonalWallet ||
                                isCreator ||
                                expense.userId.isEmpty;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Dismissible(
                                key: Key('cat_month_${expense.id}'),
                                direction: isOwner
                                    ? DismissDirection.endToStart
                                    : DismissDirection.none,
                                background: Container(
                                  padding: const EdgeInsets.only(right: 20),
                                  alignment: Alignment.centerRight,
                                  decoration: BoxDecoration(
                                    color: AppTheme.error,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  if (!isOwner) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Hanya pembuat transaksi yang dapat menghapus transaksi ini',
                                        ),
                                        backgroundColor: AppTheme.error,
                                      ),
                                    );
                                    return false;
                                  }
                                  return await _showDeleteConfirmationDialog(
                                    context,
                                  );
                                },
                                onDismissed: (_) {
                                  // Optimistic UI updates
                                  setState(() {
                                    _expenses.removeWhere(
                                        (e) => e.id == expense.id);
                                    _totalAmount -= expense.amount;
                                  });
                                  context.read<DashboardBloc>().add(
                                        DashboardDeleteExpenseRequested(
                                          expense.id,
                                          Completer<bool>(),
                                        ),
                                      );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Transaction deleted'),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: AppTheme.softShadow,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: catColor.withAlpha(25),
                                        child: CategoryIcon(
                                          icon: expense.category.icon,
                                          color: catColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              expense.description ??
                                                  expense.category.name,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.darkSlate,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  DateFormat('dd MMM, hh:mm a')
                                                      .format(expense.date),
                                                  style: GoogleFonts.beVietnamPro(
                                                    fontSize: 11,
                                                    color: AppTheme
                                                        .darkSlateVariant,
                                                  ),
                                                ),
                                                if (expense.type ==
                                                    ExpenseType.routine) ...[
                                                  const SizedBox(width: 6),
                                                  const Text(
                                                    '•',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 6,
                                                      vertical: 1.5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.primary
                                                          .withAlpha(15),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        6,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'ROUTINE',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 8,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppTheme.primary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '-${currencyFormatter.format(expense.amount)}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.darkSlate,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              expense.creatorName.toUpperCase(),
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddExpense,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '📦',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions recorded',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No expenses noted for this category in ${_formatMonthYear(widget.monthStr)}.',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: AppTheme.darkSlateVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddExpense,
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: Text(
                'Add Transaction',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load transactions',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Something went wrong while retrieving the transactions list. Please try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: AppTheme.darkSlateVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadExpenses,
              icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
              label: Text(
                'Retry',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryExpensesSkeleton extends StatelessWidget {
  const CategoryExpensesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card placeholder
            Container(
              height: 96,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            const SizedBox(height: 24),
            // Title placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 140,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Container(
                  width: 80,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Expense list items placeholder
            _buildExpenseItemSkeleton(),
            const SizedBox(height: 12),
            _buildExpenseItemSkeleton(),
            const SizedBox(height: 12),
            _buildExpenseItemSkeleton(),
            const SizedBox(height: 12),
            _buildExpenseItemSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItemSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 70,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
