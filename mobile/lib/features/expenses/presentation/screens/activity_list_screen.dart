import 'dart:async';
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
import '../bloc/dashboard_state.dart';
import '../widgets/category_icon.dart';
import 'expense_entry_screen.dart';

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
      context.read<DashboardBloc>().add(DashboardSelectWalletRequested(activeWallet));
    } else {
      context.read<DashboardBloc>().add(const DashboardRefreshRequested());
    }
  }

  List<DateTime> _generateWeekDates(DateTime referenceDate) {
    // Generate the Monday to Sunday week containing the reference date
    final int currentWeekday = referenceDate.weekday; // 1 = Monday, 7 = Sunday
    final DateTime monday = referenceDate.subtract(Duration(days: currentWeekday - 1));
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
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
              ),
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

  bool _hasTransaction(DateTime date, List<ExpenseEntity> allExpenses) {
    return allExpenses.any((expense) =>
        expense.date.year == date.year &&
        expense.date.month == date.month &&
        expense.date.day == date.day);
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
              'Delete Activity',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.darkSlate,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this activity? This action cannot be undone.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.darkSlateVariant,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<WalletEntity>> _buildWalletMenuItems(DashboardState provider) {
    return [
      if (provider.personalWallets.isNotEmpty) ...[
        const PopupMenuItem<WalletEntity>(
          enabled: false,
          height: 24,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'PERSONAL WALLETS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        ...provider.personalWallets.map(
          (wallet) => PopupMenuItem<WalletEntity>(
            value: wallet,
            child: Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  color: provider.activeWallet?.id == wallet.id
                      ? AppTheme.primary
                      : AppTheme.darkSlateVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    wallet.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: provider.activeWallet?.id == wallet.id
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                ),
                if (provider.activeWallet?.id == wallet.id)
                  const Icon(
                    Icons.check_rounded,
                    color: AppTheme.primary,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ],
      if (provider.sharedWallets.isNotEmpty) ...[
        if (provider.personalWallets.isNotEmpty) const PopupMenuDivider(),
        const PopupMenuItem<WalletEntity>(
          enabled: false,
          height: 24,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'GROUP WALLETS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        ...provider.sharedWallets.map(
          (wallet) => PopupMenuItem<WalletEntity>(
            value: wallet,
            child: Row(
              children: [
                Icon(
                  Icons.groups_outlined,
                  color: provider.activeWallet?.id == wallet.id
                      ? AppTheme.primary
                      : AppTheme.darkSlateVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    wallet.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: provider.activeWallet?.id == wallet.id
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                ),
                if (provider.activeWallet?.id == wallet.id)
                  const Icon(
                    Icons.check_rounded,
                    color: AppTheme.primary,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardBloc>().state;
    final authState = context.watch<AuthBloc>().state;
    final user = authState.currentUser;

    final currencyCode = provider.activeWallet?.currency ?? 'IDR';
    final currencyFormatter = CurrencyHelper.getFormatter(currencyCode);

    // Filter day's expenses
    final dayExpenses = provider.expenses.where((expense) {
      return expense.date.year == _selectedDate.year &&
          expense.date.month == _selectedDate.month &&
          expense.date.day == _selectedDate.day;
    }).toList();

    final double dailyTotal = dayExpenses.fold(0.0, (sum, expense) => sum + expense.amount);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.onBackground,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Activity List',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.onBackground,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (provider.activeWallet != null)
              PopupMenuButton<WalletEntity>(
                onSelected: (WalletEntity wallet) {
                  context.read<DashboardBloc>().add(DashboardSelectWalletRequested(wallet));
                },
                offset: const Offset(0, 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                elevation: 4,
                shadowColor: Colors.black.withAlpha(25),
                itemBuilder: (context) => _buildWalletMenuItems(provider),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      provider.isSharedMode ? Icons.groups_outlined : Icons.person_outline_rounded,
                      size: 13,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        provider.activeWallet!.name,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppTheme.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: AppTheme.primary,
            ),
            tooltip: 'Choose date',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ExpenseEntryScreen(initialDate: _selectedDate),
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
            // Calendar Month & Navigation Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_selectedDate),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.darkSlate,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _previousWeek,
                      icon: const Icon(Icons.chevron_left_rounded),
                      splashRadius: 20,
                    ),
                    IconButton(
                      onPressed: _nextWeek,
                      icon: const Icon(Icons.chevron_right_rounded),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Horizontal Calendar Bar (7 Columns)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _weekDates.map((date) {
                final isSelected = date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;
                final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;
                final hasTx = _hasTransaction(date, provider.expenses);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () => _selectDate(date),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary
                              : (isToday
                                  ? AppTheme.primary.withAlpha(20)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : (isToday
                                    ? AppTheme.primary.withAlpha(80)
                                    : Colors.grey[200]!),
                            width: 1.5,
                          ),
                          boxShadow: isSelected ? AppTheme.cardShadow : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('E').format(date).substring(0, 3),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('d').format(date),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.darkSlate,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Dot indicator
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasTx
                                    ? (isSelected
                                        ? Colors.white
                                        : AppTheme.primary)
                                    : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Daily Spending Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadow,
                border: const Border(
                  left: BorderSide(color: AppTheme.primary, width: 4.0),
                ),
              ),
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAILY SPENDING',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkSlateVariant,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormatter.format(dailyTotal),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transactions',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.darkSlate,
                  ),
                ),
                if (provider.isSharedMode)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    ? _buildEmptyState(context, _selectedDate)
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        itemCount: dayExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = dayExpenses[index];
                          final isMe = expense.userId == user?.id;
                          final catColor = Color(
                            int.parse(
                              expense.category.color.replaceFirst(
                                '#',
                                '0xFF',
                              ),
                            ),
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Dismissible(
                              key: Key('activity_${expense.id}'),
                              direction: isMe
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
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                if (!isMe) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Hanya pembuat transaksi yang dapat menghapus transaksi ini'),
                                      backgroundColor: AppTheme.error,
                                    ),
                                  );
                                  return false;
                                }
                                return await _showDeleteConfirmationDialog(context);
                              },
                              onDismissed: (_) {
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
                                      backgroundColor: catColor.withAlpha(30),
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
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              Text(
                                                DateFormat(
                                                  'hh:mm a',
                                                ).format(expense.date),
                                                style: GoogleFonts.beVietnamPro(
                                                  fontSize: 11,
                                                  color: AppTheme
                                                      .darkSlateVariant,
                                                ),
                                              ),
                                              const Text(
                                                '•',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 10,
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF1F5F9,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    12,
                                                  ),
                                                ),
                                                child: Text(
                                                  expense.category.name,
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (provider.isSharedMode)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isMe
                                                        ? const Color(0xFFE0E7FF)
                                                        : const Color(0xFFFCE7F3),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        isMe
                                                            ? Icons.person_rounded
                                                            : Icons.person_outline_rounded,
                                                        size: 11,
                                                        color: isMe
                                                            ? const Color(0xFF4338CA)
                                                            : const Color(0xFFBE185D),
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        isMe
                                                            ? 'You'
                                                            : (expense.creatorName.isNotEmpty
                                                                ? expense.creatorName
                                                                : 'Partner'),
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w600,
                                                          color: isMe
                                                              ? const Color(0xFF4338CA)
                                                              : const Color(0xFFBE185D),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
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
                                        if (provider.isSharedMode) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isMe
                                                  ? Colors.blue.withAlpha(20)
                                                  : Colors.pink.withAlpha(20),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isMe
                                                    ? Colors.blue.withAlpha(60)
                                                    : Colors.pink.withAlpha(60),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              isMe
                                                  ? 'ME'
                                                  : (expense.creatorName.length >= 2
                                                      ? expense.creatorName.substring(0, 2).toUpperCase()
                                                      : (expense.creatorName.isNotEmpty
                                                          ? expense.creatorName.toUpperCase()
                                                          : 'SO')),
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: isMe
                                                    ? Colors.blue[800]
                                                    : Colors.pink[800],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

  Widget _buildEmptyState(BuildContext context, DateTime selectedDate) {
    final isToday = selectedDate.year == DateTime.now().year &&
        selectedDate.month == DateTime.now().month &&
        selectedDate.day == DateTime.now().day;
    final dateStr = isToday ? 'today' : DateFormat('dd MMM').format(selectedDate);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40),
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '📅',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'No activity recorded on $dateStr',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'All clear! No expenses noted for this day.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExpenseEntryScreen(initialDate: selectedDate),
                    ),
                  );
                  _refreshData();
                },
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: Text(
                  'Add Expense',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
