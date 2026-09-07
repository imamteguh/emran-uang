import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../domain/entities/bill_reminder.dart';
import '../../domain/entities/wallet.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/add_edit_bill_dialog.dart';
import '../widgets/category_icon.dart';
import '../widgets/bills_skeleton.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {

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
    DashboardState provider,
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
      final completer = Completer<bool>();
      context.read<DashboardBloc>().add(DashboardPayBillRequested(reminder, completer));
      final success = await completer.future;
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
    NumberFormat formatter,
    DashboardState provider,
  ) {
    final isPaid = reminder.isPaidForCurrentPeriod;
    final categoryColorStr = reminder.category?.color ?? '#4F46E5';
    final categoryColor = Color(
      int.parse(categoryColorStr.replaceFirst('#', '0xFF')),
    );

    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.currentUser?.id;
    final isPersonalWallet = provider.activeWallet?.type == WalletType.personal;
    final isCreator = currentUserId != null && reminder.userId == currentUserId;
    final isOwner = isPersonalWallet || isCreator || reminder.userId.isEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 12,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: CategoryIcon(
                    icon: reminder.category?.icon ?? '💰',
                    color: categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: AppTheme.darkSlate,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${reminder.periodicity.name.toUpperCase()} • ${formatter.format(reminder.amount)}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: AppTheme.darkSlateVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
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
                    isPaid ? 'Paid' : 'Unpaid',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPaid ? AppTheme.secondary : AppTheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 8),
            if (!isPaid)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.payment_rounded,
                    color: AppTheme.secondary,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Pay Bill',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.secondary,
                  ),
                ),
                subtitle: Text(
                  'Record expense of ${formatter.format(reminder.amount)} and mark as paid',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppTheme.darkSlateVariant,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _togglePayment(context, reminder, formatter, provider);
                },
              )
            else
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.secondary,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Already Paid',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.secondary,
                  ),
                ),
                subtitle: Text(
                  'Payment recorded for the current period',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppTheme.darkSlateVariant,
                  ),
                ),
                enabled: false,
              ),
            if (isOwner)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Edit Bill',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.darkSlate,
                  ),
                ),
                subtitle: Text(
                  'Modify amount, due date, or periodicity',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppTheme.darkSlateVariant,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddEditBillDialog(reminder: reminder);
                },
              )
            else
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      'Edit Bill',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Owner only',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Only the bill creator can edit this reminder',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Only the bill creator can edit this reminder.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            if (isOwner)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.error,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Delete Bill',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.error,
                  ),
                ),
                subtitle: Text(
                  'Remove this reminder from your wallet',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppTheme.darkSlateVariant,
                  ),
                ),
                onTap: () async {
                  if (!isOwner) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Only the bill creator can delete this reminder.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

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
                    final completer = Completer<bool>();
                    context.read<DashboardBloc>().add(
                          DashboardDeleteReminderRequested(
                            reminder.id,
                            completer,
                          ),
                        );
                    final success = await completer.future;
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
              )
            else
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      'Delete Bill',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Owner only',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Only the bill creator can delete this reminder',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Only the bill creator can delete this reminder.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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
    final dashboardProvider = context.watch<DashboardBloc>().state;
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
                  context.read<DashboardBloc>().add(DashboardSelectWalletRequested(wallet));
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
                  context.read<DashboardBloc>().add(const DashboardFetchRemindersRequested());
                },
                color: AppTheme.primary,
                child: dashboardProvider.isLoading && activeReminders.isEmpty
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
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
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
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildBillItem(
                        annualRenewals[index],
                        currencyFormatter,
                        dashboardProvider,
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
    DashboardState provider,
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

    String dueText;
    bool isUrgent = false;

    if (isPaid) {
      dueText = reminder.periodicity == Periodicity.yearly
          ? 'Paid for this year'
          : 'Paid this month';
    } else {
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
      } else if (reminder.periodicity == Periodicity.yearly) {
        dueText = 'Due ${_formatEnglishMonthYear(reminder.dueDate)}';
      } else {
        dueText = 'Due ${_formatEnglishDayMonth(reminder.dueDate)}';
      }
    }

    final String periodicityLabel = reminder.periodicity == Periodicity.yearly
        ? 'Annual'
        : (reminder.periodicity == Periodicity.monthly
            ? 'Monthly'
            : (reminder.periodicity == Periodicity.weekly
                ? 'Weekly'
                : 'Daily'));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            _showReminderOptions(context, reminder, formatter, provider),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softShadow,
            border: Border.all(
              color: isPaid
                  ? AppTheme.secondary.withValues(alpha: 0.25)
                  : (isUrgent
                      ? AppTheme.error.withValues(alpha: 0.3)
                      : const Color(0xFFF1F5F9)),
              width: (isPaid || isUrgent) ? 1.5 : 1.0,
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
              const SizedBox(width: 14),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            periodicityLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkSlateVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dueText,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontWeight: isUrgent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isUrgent
                                  ? AppTheme.error
                                  : (isPaid
                                      ? AppTheme.secondary
                                      : AppTheme.darkSlateVariant),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? AppTheme.secondaryContainer
                              : (isUrgent
                                  ? AppTheme.errorContainer
                                  : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isPaid
                              ? 'Paid'
                              : (isUrgent ? 'Overdue' : 'Unpaid'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPaid
                                ? AppTheme.secondary
                                : (isUrgent
                                    ? AppTheme.error
                                    : AppTheme.darkSlateVariant),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: AppTheme.darkSlateVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
