import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/category_icon.dart';
import '../../domain/entities/wallet.dart';
import 'expense_entry_screen.dart';
import 'shared_groups_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final responsive = ResponsiveHelper(context);

    final currencyCode = provider.activeWallet?.currency ?? 'IDR';
    final currencyFormatter = CurrencyHelper.getFormatter(currencyCode);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(51),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                provider.activeWallet == null
                    ? Icons.account_balance_wallet
                    : (provider.isSharedMode ? Icons.groups_rounded : Icons.person_rounded),
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            if (provider.allWallets.isEmpty)
              Text(
                'WalletShare',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: responsive.scaleFont(18),
                ),
              )
            else
              PopupMenuButton<WalletEntity>(
                onSelected: (WalletEntity wallet) {
                  provider.selectWallet(wallet);
                },
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.1),
                itemBuilder: (context) {
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
                                const Icon(Icons.check_rounded, color: AppTheme.primary, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (provider.sharedWallets.isNotEmpty) ...[
                      const PopupMenuDivider(),
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
                                const Icon(Icons.check_rounded, color: AppTheme.primary, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ];
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: responsive.scale(150)),
                      child: Text(
                        provider.activeWallet?.name ?? 'Select Wallet',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: responsive.scaleFont(18),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SharedGroupsScreen()),
              );
            },
            icon: const Icon(Icons.group_outlined, size: 28, color: AppTheme.primary),
            splashRadius: 24,
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
            icon: const Icon(Icons.notifications_none_outlined, size: 28, color: AppTheme.primary),
            splashRadius: 24,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await provider.refreshData();
          },
          child: LayoutBuilder(
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
                    _buildDailySummaryCard(
                      context,
                      provider,
                      responsive,
                      currencyFormatter,
                    ),
                    const SizedBox(height: 20),

                    // Bento Stats Grid (Monthly Savings & Top Category)
                    _buildBentoGrid(
                      context,
                      provider,
                      responsive,
                      currencyFormatter,
                    ),
                    const SizedBox(height: 24),

                    // Recent activity section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Activity',
                          style: AppTheme.headlineSm.copyWith(
                            fontSize: responsive.scaleFont(20),
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showAllExpensesBottomSheet(
                            context,
                            provider,
                            currencyFormatter,
                            user?.id,
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

                    if (provider.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                        ),
                      )
                    else if (provider.expenses.isEmpty)
                      _buildEmptyState(provider)
                    else
                      _buildExpensesList(
                        context,
                        provider,
                        responsive,
                        currencyFormatter,
                        user?.id,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExpenseEntryScreen()),
            );
          },
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }



  // ─── Daily Summary Card ───────────────────────────────────────────────────

  void _showSetBudgetDialog(BuildContext context, DashboardProvider provider) {
    final controller = TextEditingController(
      text: provider.activeWallet?.dailyBudget != null
          ? provider.activeWallet!.dailyBudget!.toStringAsFixed(0)
          : '',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Daily Budget Limit',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set your daily target limit. A realistic budget helps you optimize your savings automatically.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.darkSlateVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.darkSlate,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.payments_outlined,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  prefixText: 'Rp ',
                  prefixStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    fontSize: 16,
                  ),
                  hintText: 'e.g. 150,000',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final double? newBudget = double.tryParse(
                    controller.text.trim(),
                  );
                  if (newBudget != null && newBudget >= 0) {
                    final success = await provider.updateDailyBudget(newBudget);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Daily budget updated!'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to update budget.'),
                          ),
                        );
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid amount'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save Limit',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDailySummaryCard(
    BuildContext context,
    DashboardProvider provider,
    ResponsiveHelper responsive,
    NumberFormat formatter,
  ) {
    final double budgetLimit = provider.activeWallet?.dailyBudget ?? 0.0;
    final double spendToday = provider.todaySpend;
    final double budgetPercent = budgetLimit <= 0
        ? 0.0
        : (spendToday > budgetLimit ? 1.0 : (spendToday / budgetLimit));

    return Container(
      decoration: BoxDecoration(
        boxShadow: AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: AppTheme.roundedBorder,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppTheme.primary, width: 4.0),
            ),
          ),
          child: Stack(
            children: [
              // Subtle Background Graphic
              Positioned(
                top: -48,
                right: -48,
                width: 192,
                height: 192,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(8), // ~3% opacity
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TODAY\'S SPENDING',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: responsive.scaleFont(12),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkSlateVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatter.format(spendToday),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: responsive.scaleFont(32),
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _showSetBudgetDialog(context, provider),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Daily Budget',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 12,
                                  color: AppTheme.darkSlateVariant,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.edit, size: 14, color: AppTheme.primary),
                            ],
                          ),
                          Text(
                            budgetLimit > 0
                                ? formatter.format(budgetLimit)
                                : 'Tap to set',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: budgetPercent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Bento Grid ────────────────────────────────────────────────────────────

  Widget _buildBentoGrid(
    BuildContext context,
    DashboardProvider provider,
    ResponsiveHelper responsive,
    NumberFormat formatter,
  ) {
    final double dailyBudget = provider.activeWallet?.dailyBudget ?? 0.0;
    final int daysInMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month + 1,
      0,
    ).day;
    final double monthlyBudgetLimit = dailyBudget * daysInMonth;
    final double monthlySavings = dailyBudget > 0
        ? (monthlyBudgetLimit - provider.monthlySpend).clamp(
            0.0,
            double.infinity,
          )
        : 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.35,
      children: [
        // Monthly Savings Block
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.savings_outlined, color: AppTheme.secondary),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Savings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondary.withAlpha(200),
                    ),
                  ),
                  Text(
                    formatter.format(monthlySavings),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: responsive.scaleFont(16),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Top Category Block
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.tertiaryFixed,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CategoryIcon(
                icon: provider.topCategoryIcon,
                color: AppTheme.tertiary,
                size: 28,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Category',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.tertiary.withAlpha(200),
                    ),
                  ),
                  Text(
                    provider.topCategory,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: responsive.scaleFont(16),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.tertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Expenses List Activity Feed ──────────────────────────────────────────

  Widget _buildExpensesList(
    BuildContext context,
    DashboardProvider provider,
    ResponsiveHelper responsive,
    NumberFormat formatter,
    String? currentUserId,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.expenses.length,
      itemBuilder: (context, index) {
        final expense = provider.expenses[index];
        final catColor = Color(
          int.parse(expense.category.color.replaceFirst('#', '0xFF')),
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: Key(expense.id),
            direction: DismissDirection.endToStart,
            background: Container(
              padding: const EdgeInsets.only(right: 20),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: AppTheme.error,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              provider.deleteExpense(expense.id);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Expense deleted')));
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: catColor.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: CategoryIcon(
                      icon: expense.category.icon,
                      color: catColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.description ?? expense.category.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              DateFormat('hh:mm a').format(expense.date),
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                color: AppTheme.darkSlateVariant,
                              ),
                            ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                expense.category.name,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '-${formatter.format(expense.amount)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkSlate,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: expense.userId == currentUserId
                              ? Colors.blue[100]
                              : Colors.pink[100],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          expense.userId == currentUserId
                              ? 'ME'
                              : (expense.creatorName.length >= 2
                                    ? expense.creatorName
                                          .substring(0, 2)
                                          .toUpperCase()
                                    : (expense.creatorName.isNotEmpty
                                          ? expense.creatorName.toUpperCase()
                                          : 'SO')),
                          style: const TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
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
      },
    );
  }

  void _showAllExpensesBottomSheet(
    BuildContext context,
    DashboardProvider provider,
    NumberFormat formatter,
    String? currentUserId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC), // Premium light background
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'All Transactions',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${provider.expenses.length}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 22,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: provider.expenses.isEmpty
                      ? Center(
                          child: Text(
                            'No transactions yet',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.grey[500],
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: provider.expenses.length,
                          itemBuilder: (context, index) {
                            final expense = provider.expenses[index];
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
                                key: Key('all_${expense.id}'),
                                direction: DismissDirection.endToStart,
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
                                onDismissed: (_) {
                                  provider.deleteExpense(expense.id);
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
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.darkSlate,
                                                    fontSize: 14,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  DateFormat(
                                                    'dd MMM yyyy, hh:mm a',
                                                  ).format(expense.date),
                                                  style:
                                                      GoogleFonts.beVietnamPro(
                                                        fontSize: 11,
                                                        color: AppTheme
                                                            .darkSlateVariant,
                                                      ),
                                                ),
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
                                            '-${formatter.format(expense.amount)}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.darkSlate,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color:
                                                  expense.userId ==
                                                      currentUserId
                                                  ? Colors.blue[100]
                                                  : Colors.pink[100],
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1,
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              expense.userId == currentUserId
                                                  ? 'ME'
                                                  : (expense
                                                                .creatorName
                                                                .length >=
                                                            2
                                                        ? expense.creatorName
                                                              .substring(0, 2)
                                                              .toUpperCase()
                                                        : (expense
                                                                  .creatorName
                                                                  .isNotEmpty
                                                              ? expense
                                                                    .creatorName
                                                                    .toUpperCase()
                                                              : 'SO')),
                                              style: const TextStyle(
                                                fontSize: 7,
                                                fontWeight: FontWeight.bold,
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
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(DashboardProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.roundedBorder,
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          const Text('🐷', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'No activity recorded yet',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            provider.isSharedMode
                ? 'Data bersama belum memiliki catatan pengeluaran.'
                : 'Klik tombol "+" di bawah untuk mencatat pengeluaran.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
