import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'shared_groups_screen.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../domain/entities/bill_reminder.dart';
import '../../domain/entities/wallet.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/add_edit_bill_dialog.dart';
import '../widgets/category_icon.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bellController;
  bool _bellClicked = false;

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

  void _handleBellClick() {
    setState(() {
      _bellClicked = !_bellClicked;
    });
    _bellController.stop();
    _bellController.forward(from: 0.0).then((_) {
      if (!_bellClicked) {
        _bellController.repeat(reverse: true);
      }
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🔔 ', style: TextStyle(fontSize: 16)),
            Expanded(
              child: Text(
                'Bill reminders are synced in real-time!',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAddEditBillDialog({BillReminderEntity? reminder}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditBillDialog(reminder: reminder),
    );
  }

  void _togglePayment(
    BuildContext context,
    BillReminderEntity reminder,
    NumberFormat formatter,
    DashboardProvider provider,
  ) async {
    if (reminder.isPaidForCurrentPeriod) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This bill has already been paid for the current period.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Pay Bill',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Do you want to record a regular expense of ${formatter.format(reminder.amount)} for "${reminder.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.outline),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Pay',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
      final success = await provider.payBill(reminder);
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading dialog
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment for "${reminder.title}" successfully recorded as an expense!',
              ),
              backgroundColor: AppTheme.secondary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to record payment.')),
          );
        }
      }
    }
  }

  void _showReminderOptions(
    BuildContext context,
    BillReminderEntity reminder,
    DashboardProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 24,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                reminder.title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.darkSlate,
                ),
              ),
            ),
            const Divider(color: Color(0xFFF1F5F9)),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppTheme.primary),
              title: Text('Edit Bill', style: GoogleFonts.beVietnamPro()),
              onTap: () {
                Navigator.of(context).pop();
                _showAddEditBillDialog(reminder: reminder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.error),
              title: Text(
                'Delete Bill',
                style: GoogleFonts.beVietnamPro(color: AppTheme.error),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      'Delete Bill',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to delete the bill reminder "${reminder.title}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppTheme.outline),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (!context.mounted) return;

                if (confirm == true) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  );
                  final success = await provider.deleteReminder(reminder.id);
                  if (context.mounted) {
                    Navigator.of(context).pop(); // dismiss loading dialog
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bill successfully deleted'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to delete bill'),
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatEnglishMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatEnglishDayMonth(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final currencyCode = dashboardProvider.activeWallet?.currency ?? 'IDR';
    final currencyFormatter = CurrencyHelper.getFormatter(currencyCode);

    // Filter active reminders
    final activeReminders = dashboardProvider.reminders
        .where((r) => r.status == ReminderStatus.active)
        .toList();

    // Outflow calculations
    double totalMonthlyOutflow = 0;
    double paidThisMonth = 0;
    double pendingThisMonth = 0;

    for (var r in activeReminders) {
      double monthlyAmt = r.amount;
      if (r.periodicity == Periodicity.daily) {
        monthlyAmt = r.amount * 30.4;
      } else if (r.periodicity == Periodicity.weekly) {
        monthlyAmt = r.amount * 4.33;
      } else if (r.periodicity == Periodicity.yearly) {
        monthlyAmt = r.amount / 12.0;
      }

      totalMonthlyOutflow += monthlyAmt;
      if (r.isPaidForCurrentPeriod) {
        paidThisMonth += monthlyAmt;
      } else {
        pendingThisMonth += monthlyAmt;
      }
    }

    // Partition lists
    final regularBills = activeReminders
        .where((r) => r.periodicity != Periodicity.yearly)
        .toList();
    final annualRenewals = activeReminders
        .where((r) => r.periodicity == Periodicity.yearly)
        .toList();

    // Due in next 7 days count
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    final dueSoonCount = activeReminders.where((r) {
      return !r.isPaidForCurrentPeriod &&
          r.dueDate.isAfter(now.subtract(const Duration(days: 1))) &&
          r.dueDate.isBefore(nextWeek);
    }).length;

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
                dashboardProvider.activeWallet == null
                    ? Icons.account_balance_wallet
                    : (dashboardProvider.isSharedMode
                        ? Icons.groups_rounded
                        : Icons.person_rounded),
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            if (dashboardProvider.allWallets.isEmpty)
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
                  dashboardProvider.selectWallet(wallet);
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
                    if (dashboardProvider.personalWallets.isNotEmpty) ...[
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
                      ...dashboardProvider.personalWallets.map(
                        (wallet) => PopupMenuItem<WalletEntity>(
                          value: wallet,
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                color: dashboardProvider.activeWallet?.id ==
                                        wallet.id
                                    ? AppTheme.primary
                                    : AppTheme.darkSlateVariant,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  wallet.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight:
                                        dashboardProvider.activeWallet?.id ==
                                                wallet.id
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                              ),
                              if (dashboardProvider.activeWallet?.id ==
                                  wallet.id)
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
                    if (dashboardProvider.sharedWallets.isNotEmpty) ...[
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
                      ...dashboardProvider.sharedWallets.map(
                        (wallet) => PopupMenuItem<WalletEntity>(
                          value: wallet,
                          child: Row(
                            children: [
                              Icon(
                                Icons.groups_outlined,
                                color: dashboardProvider.activeWallet?.id ==
                                        wallet.id
                                    ? AppTheme.primary
                                    : AppTheme.darkSlateVariant,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  wallet.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight:
                                        dashboardProvider.activeWallet?.id ==
                                                wallet.id
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                              ),
                              if (dashboardProvider.activeWallet?.id ==
                                  wallet.id)
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
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: responsive.scale(150),
                      ),
                      child: Text(
                        dashboardProvider.activeWallet?.name ?? 'Select Wallet',
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
            icon: const Icon(
              Icons.group_outlined,
              size: 28,
              color: AppTheme.primary,
            ),
            splashRadius: 24,
          ),
          IconButton(
            onPressed: _handleBellClick,
            icon: const Icon(
              Icons.notifications_none_outlined,
              size: 28,
              color: AppTheme.primary,
            ),
            splashRadius: 24,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (dashboardProvider.isLoading)
              const LinearProgressIndicator(
                color: AppTheme.primary,
                backgroundColor: Color(0xFFF1F5F9),
                minHeight: 2,
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await dashboardProvider.fetchReminders();
                },
                color: AppTheme.primary,
                child: dashboardProvider.isLoading && activeReminders.isEmpty
                    ? const SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: 400,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: AppTheme.primary),
                                SizedBox(height: 16),
                                Text(
                                  'Loading bills...',
                                  style: TextStyle(
                                    color: AppTheme.darkSlateVariant,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: responsive.screenPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Summary Header
                Text(
                  'Upcoming Bills',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: responsive.scaleFont(28),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dueSoonCount > 0
                      ? 'You have $dueSoonCount bills due in the next 7 days.'
                      : 'All your bills are paid for the next 7 days.',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: responsive.scaleFont(14),
                    color: dueSoonCount > 0
                        ? AppTheme.error
                        : AppTheme.darkSlateVariant,
                    fontWeight: dueSoonCount > 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 24),

                // Bento Outflow Card
                Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: AppTheme.roundedBorder,
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Stack(
                    children: [
                      // Decorative background shapes
                      Positioned(
                        right: -32,
                        bottom: -32,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 48,
                        top: -48,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ESTIMATED MONTHLY OUTFLOW',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    currencyFormatter.format(
                                      totalMonthlyOutflow,
                                    ),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: responsive.scaleFont(32),
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedBuilder(
                              animation: _bellController,
                              builder: (context, child) {
                                double rotation = 0.0;
                                if (!_bellClicked) {
                                  rotation =
                                      (_bellController.value * 0.2) - 0.1;
                                }
                                return Transform.rotate(
                                  angle: rotation,
                                  child: GestureDetector(
                                    onTap: _handleBellClick,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.notifications_active_outlined,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Paid vs Pending Side-by-side Bento Cards
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppTheme.softShadow,
                          border: const Border(
                            top: BorderSide(
                              color: AppTheme.secondary,
                              width: 3.0,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PAID',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currencyFormatter.format(paidThisMonth),
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkSlate),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppTheme.softShadow,
                          border: Border(
                            top: BorderSide(
                              color: pendingThisMonth > 0
                                  ? AppTheme.error
                                  : Colors.grey,
                              width: 3.0,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PENDING',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: pendingThisMonth > 0
                                    ? AppTheme.error
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currencyFormatter.format(pendingThisMonth),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkSlate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Monthly/Regular Bills Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Regular Bills',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: responsive.scaleFont(18),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddEditBillDialog(),
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                      label: Text(
                        'Add',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (regularBills.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: AppTheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No regular bills at this time',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap "Add" to start tracking bills like electricity, internet, etc.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: AppTheme.darkSlateVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: regularBills.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildBillItem(
                        regularBills[index],
                        currencyFormatter,
                        dashboardProvider,
                      );
                    },
                  ),
                const SizedBox(height: 32),

                // Annual Renewals Section
                Text(
                  'Annual Renewals',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: responsive.scaleFont(18),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const SizedBox(height: 16),

                if (annualRenewals.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 48,
                          color: AppTheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No annual renewals at this time',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Annual bills like taxes or insurance will appear here.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: AppTheme.darkSlateVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: annualRenewals.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final reminder = annualRenewals[index];
                      final categoryColorStr =
                          reminder.category?.color ?? '#E2E8F0';
                      final categoryColor = Color(
                        int.parse(categoryColorStr.replaceFirst('#', '0xFF')),
                      );
                      final isPaid = reminder.isPaidForCurrentPeriod;

                      // Progress calculation based on current month relative to due date
                      final now = DateTime.now();
                      final monthsRemaining =
                          reminder.dueDate.difference(now).inDays / 30.0;
                      double progress =
                          1.0 - (monthsRemaining.clamp(0.0, 12.0) / 12.0);
                      if (isPaid) progress = 1.0;

                      final totalAmount = reminder.amount;
                      final savedAmount = totalAmount * progress;

                      return GestureDetector(
                        onLongPress: () => _showReminderOptions(
                          context,
                          reminder,
                          dashboardProvider,
                        ),
                        child: CustomPaint(
                          painter: DashedRectPainter(
                            color: isPaid
                                ? AppTheme.secondary
                                : const Color(0xFFC3C6D7),
                            strokeWidth: 2.0,
                          ),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  categoryColor.withValues(alpha: 0.03),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: categoryColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: categoryColor.withValues(alpha: 0.2),
                                      width: 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: CategoryIcon(
                                    icon: reminder.category?.icon ?? '💰',
                                    color: categoryColor,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  reminder.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Next annual payment of ${currencyFormatter.format(reminder.amount)} due in ${_formatEnglishMonthYear(reminder.dueDate)}.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 13,
                                    color: AppTheme.darkSlateVariant,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 10,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: progress,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isPaid
                                            ? AppTheme.secondary
                                            : AppTheme.primary,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isPaid
                                            ? 'Done for this year!'
                                            : '${currencyFormatter.format(savedAmount)} saved of ${currencyFormatter.format(totalAmount)} goal',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.darkSlateVariant,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isPaid
                                            ? AppTheme.secondaryContainer
                                            : AppTheme.errorContainer,
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                      ),
                                      child: Text(
                                        isPaid ? 'Paid' : 'Pending',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isPaid
                                              ? AppTheme.secondary
                                              : AppTheme.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (!isPaid) ...[
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _togglePayment(
                                      context,
                                      reminder,
                                      currencyFormatter,
                                      dashboardProvider,
                                    ),
                                    icon: const Icon(
                                      Icons.payment_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Pay Renewal'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
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

  Widget _buildBillItem(
    BillReminderEntity reminder,
    NumberFormat formatter,
    DashboardProvider provider,
  ) {
    final categoryColorStr = reminder.category?.color ?? '#4F46E5';
    final categoryColor = Color(
      int.parse(categoryColorStr.replaceFirst('#', '0xFF')),
    );
    final bgIconColor = categoryColor.withValues(alpha: 0.15);
    final iconColor = categoryColor;
    final isPaid = reminder.isPaidForCurrentPeriod;

    // Calculate due state
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      reminder.dueDate.year,
      reminder.dueDate.month,
      reminder.dueDate.day,
    );
    final daysUntilDue = due.difference(today).inDays;

    String dueText =
        'Due ${_formatEnglishDayMonth(reminder.dueDate)}';
    bool isUrgent = false;

    if (!isPaid) {
      if (daysUntilDue < 0) {
        dueText = 'Overdue by ${daysUntilDue.abs()} days';
        isUrgent = true;
      } else if (daysUntilDue == 0) {
        dueText = 'Due TODAY';
        isUrgent = true;
      } else if (daysUntilDue <= 3) {
        dueText =
            'Due in $daysUntilDue days (${_formatEnglishDayMonth(reminder.dueDate)})';
        isUrgent = true;
      }
    } else {
      dueText = 'Paid this month';
    }

    return GestureDetector(
      onLongPress: () => _showReminderOptions(context, reminder, provider),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
          border: Border.all(
            color: isPaid
                ? AppTheme.secondary.withValues(alpha: 0.3)
                : Colors.transparent,
            width: isPaid ? 1.5 : 0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgIconColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: CategoryIcon(
                icon: reminder.category?.icon ?? '💰',
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dueText,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      fontWeight: isUrgent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isUrgent
                          ? AppTheme.error
                          : AppTheme.darkSlateVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatter.format(reminder.amount),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () =>
                      _togglePayment(context, reminder, formatter, provider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppTheme.secondaryContainer
                          : AppTheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isPaid ? 'Paid' : 'Pay',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPaid ? AppTheme.secondary : AppTheme.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedRectPainter({
    this.color = const Color(0xFFC3C6D7),
    this.strokeWidth = 2.0,
    this.dashWidth = 8.0,
    this.dashSpace = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );
    path.addRRect(rrect);

    final dashPath = Path();
    var distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(DashedRectPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      dashWidth != oldDelegate.dashWidth ||
      dashSpace != oldDelegate.dashSpace;
}
