import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/expense.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../widgets/category_monthly/category_monthly.dart';
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
          'limit': 100,
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

  void _handleDeleteExpense(ExpenseEntity expense) {
    setState(() {
      _expenses.removeWhere((e) => e.id == expense.id);
      _totalAmount -= expense.amount;
    });
    context.read<DashboardBloc>().add(
          DashboardDeleteExpenseRequested(
            expense.id,
            Completer<bool>(),
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction deleted')),
    );
  }

  Future<void> _navigateToAddExpense() async {
    final now = DateTime.now();
    final parts = widget.monthStr.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    final initialDate = (year == now.year && month == now.month)
        ? now
        : DateTime(year, month, 1);

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
                  ? CategoryMonthlyErrorState(onRetry: _loadExpenses)
                  : _expenses.isEmpty
                      ? CategoryMonthlyEmptyState(
                          monthStr: widget.monthStr,
                          onAddExpense: _navigateToAddExpense,
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            CategoryMonthlyHeaderCard(
                              category: widget.category,
                              monthStr: widget.monthStr,
                              totalAmount: _totalAmount,
                              currencyCode: widget.currencyCode,
                            ),
                            const SizedBox(height: 24),
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
                            ..._expenses.map(
                              (expense) => CategoryMonthlyTransactionItem(
                                expense: expense,
                                currencyCode: widget.currencyCode,
                                activeWallet: activeWallet,
                                currentUser: user,
                                onDelete: () => _handleDeleteExpense(expense),
                              ),
                            ),
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
}
