import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/bill_reminder.dart';
import '../../bloc/dashboard_bloc.dart';
import '../../bloc/dashboard_event.dart';
import '../../bloc/dashboard_state.dart';
import '../add_edit_bill_dialog.dart';
import '../category_icon.dart';

class BillActionsHelper {
  static void showAddEditBillDialog({
    required BuildContext context,
    BillReminderEntity? reminder,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditBillDialog(reminder: reminder),
    );
  }

  static Future<void> togglePayment({
    required BuildContext context,
    required BillReminderEntity reminder,
    required NumberFormat formatter,
  }) async {
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
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
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
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.outline),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
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

    if (!context.mounted || confirm != true) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    BuildContext? loadingDialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dCtx) {
        loadingDialogContext = dCtx;
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        );
      },
    );

    final completer = Completer<bool>();
    context.read<DashboardBloc>().add(DashboardPayBillRequested(reminder, completer));

    bool success = false;
    try {
      success = await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );
    } catch (_) {
      success = false;
    }

    // Dismiss loading dialog safely
    if (loadingDialogContext != null && loadingDialogContext!.mounted) {
      Navigator.of(loadingDialogContext!).pop();
    } else if (rootNavigator.canPop()) {
      rootNavigator.pop();
    }

    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Payment for "${reminder.title}" successfully recorded as an expense!',
          ),
          backgroundColor: AppTheme.secondary,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Failed to record payment.')),
      );
    }
  }

  static Future<void> confirmAndDeleteBill({
    required BuildContext context,
    required BillReminderEntity reminder,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
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
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.outline),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
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

    if (!context.mounted || confirm != true) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    BuildContext? loadingDialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dCtx) {
        loadingDialogContext = dCtx;
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        );
      },
    );

    final completer = Completer<bool>();
    context.read<DashboardBloc>().add(
          DashboardDeleteReminderRequested(
            reminder.id,
            completer,
          ),
        );

    bool success = false;
    try {
      success = await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );
    } catch (_) {
      success = false;
    }

    // Dismiss loading dialog safely
    if (loadingDialogContext != null && loadingDialogContext!.mounted) {
      Navigator.of(loadingDialogContext!).pop();
    } else if (rootNavigator.canPop()) {
      rootNavigator.pop();
    }

    if (success) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Bill successfully deleted'),
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to delete bill'),
        ),
      );
    }
  }

  static void showReminderOptions({
    required BuildContext context,
    required BillReminderEntity reminder,
    required NumberFormat formatter,
    required DashboardState provider,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => BillOptionsSheet(
        reminder: reminder,
        formatter: formatter,
        provider: provider,
        onPay: () {
          Navigator.of(sheetContext).pop();
          togglePayment(
            context: context,
            reminder: reminder,
            formatter: formatter,
          );
        },
        onEdit: () {
          Navigator.of(sheetContext).pop();
          showAddEditBillDialog(
            context: context,
            reminder: reminder,
          );
        },
        onDelete: () {
          Navigator.of(sheetContext).pop();
          confirmAndDeleteBill(
            context: context,
            reminder: reminder,
          );
        },
      ),
    );
  }
}

class BillOptionsSheet extends StatelessWidget {
  final BillReminderEntity reminder;
  final NumberFormat formatter;
  final DashboardState provider;
  final VoidCallback onPay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BillOptionsSheet({
    super.key,
    required this.reminder,
    required this.formatter,
    required this.provider,
    required this.onPay,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = reminder.isPaidForCurrentPeriod;
    final categoryColorStr = reminder.category?.color ?? '#4F46E5';
    final categoryColor = Color(
      int.parse(categoryColorStr.replaceFirst('#', '0xFF')),
    );

    return Container(
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
              onTap: onPay,
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
            onTap: onEdit,
          ),
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
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}
