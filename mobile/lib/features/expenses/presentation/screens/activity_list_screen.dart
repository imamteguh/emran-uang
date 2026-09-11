import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../widgets/activity/activity.dart';
import 'expense_entry_screen.dart';
import 'transaction_history_screen.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  late DateTime _selectedDate;
  late List<DateTime> _weekDates;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _weekDates = _generateWeekDates(_selectedDate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    final activeWallet = context.read<DashboardBloc>().state.activeWallet;
    if (activeWallet != null) {
      context.read<DashboardBloc>().add(
        DashboardSelectWalletRequested(activeWallet),
      );
    } else {
      context.read<DashboardBloc>().add(const DashboardRefreshRequested());
    }
  }

  List<DateTime> _generateWeekDates(DateTime referenceDate) {
    final int currentWeekday = referenceDate.weekday; // 1 = Monday, 7 = Sunday
    final DateTime monday = referenceDate.subtract(
      Duration(days: currentWeekday - 1),
    );
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  void _previousWeek() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 7));
      _weekDates = _generateWeekDates(_selectedDate);
    });
  }

  void _nextWeek() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 7));
      _weekDates = _generateWeekDates(_selectedDate);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.darkSlate,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _weekDates = _generateWeekDates(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardBloc>().state;
    final authState = context.watch<AuthBloc>().state;
    final user = authState.currentUser;

    final currencyCode = provider.activeWallet?.currency ?? 'IDR';
    final currencyFormatter = CurrencyHelper.getFormatter(currencyCode);

    final dayExpenses = provider.expenses.where((expense) {
      return expense.date.year == _selectedDate.year &&
          expense.date.month == _selectedDate.month &&
          expense.date.day == _selectedDate.day;
    }).toList();

    final double dailyTotal = dayExpenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: ActivityAppBar(
        provider: provider,
        onPickDate: _pickDate,
        onWalletSelected: (wallet) {
          context.read<DashboardBloc>().add(
            DashboardSelectWalletRequested(wallet),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  ExpenseEntryScreen(initialDate: _selectedDate),
            ),
          );
          _refreshData();
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Expense',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Month & Week Navigation
            ActivityWeekCalendar(
              selectedDate: _selectedDate,
              weekDates: _weekDates,
              allExpenses: provider.expenses,
              onSelectDate: _selectDate,
              onPreviousWeek: _previousWeek,
              onNextWeek: _nextWeek,
            ),
            const SizedBox(height: 20),

            // Daily Spending Hero Card
            ActivityDailySpendingCard(
              dailyTotal: dailyTotal,
              currencyFormatter: currencyFormatter,
            ),
            const SizedBox(height: 24),

            // Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Transactions',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TransactionHistoryScreen(),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.receipt_long_rounded,
                              size: 13,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Mutasi 31 Hari',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (provider.isSharedMode)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.groups_rounded,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Shared Wallet',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Transaction List with Pull-to-Refresh
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: () async {
                  _refreshData();
                },
                child: dayExpenses.isEmpty
                    ? ActivityEmptyState(selectedDate: _selectedDate)
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        itemCount: dayExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = dayExpenses[index];
                          return ActivityTransactionItem(
                            expense: expense,
                            provider: provider,
                            currentUserId: user?.id,
                            currencyFormatter: currencyFormatter,
                            onDelete: () {
                              context.read<DashboardBloc>().add(
                                DashboardDeleteExpenseRequested(
                                  expense.id,
                                  Completer<bool>(),
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Expense deleted'),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
