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
          content: Text('Tagihan ini sudah lunas untuk periode saat ini.'),
        ),
      );
      return;
    }

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppTheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bayar Tagihan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Apakah Anda ingin mencatat pengeluaran rutin sebesar ${formatter.format(reminder.amount)} untuk "${reminder.title}"?',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.outline,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(bCtx).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.outline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(bCtx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Bayar Sekarang',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (!context.mounted || confirm != true) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    BuildContext? loadingDialogContext;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (dCtx) {
        loadingDialogContext = dCtx;
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 16),
              Text(
                'Memproses pembayaran...',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.darkSlate,
                ),
              ),
            ],
          ),
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
            'Pembayaran tagihan "${reminder.title}" berhasil dicatat!',
          ),
          backgroundColor: AppTheme.secondary,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Gagal mencatat pembayaran tagihan.')),
      );
    }
  }

  static Future<void> confirmAndDeleteBill({
    required BuildContext context,
    required BillReminderEntity reminder,
  }) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hapus Pengingat Tagihan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Apakah Anda yakin ingin menghapus pengingat tagihan "${reminder.title}"?',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.outline,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(bCtx).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.outline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(bCtx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Hapus',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (!context.mounted || confirm != true) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    BuildContext? loadingDialogContext;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (dCtx) {
        loadingDialogContext = dCtx;
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 16),
              Text(
                'Menghapus tagihan...',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.darkSlate,
                ),
              ),
            ],
          ),
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
          content: Text('Pengingat tagihan berhasil dihapus'),
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus pengingat tagihan'),
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
                      '${reminder.periodicity == Periodicity.yearly ? 'TAHUNAN' : 'BULANAN'} • ${formatter.format(reminder.amount)}',
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
                  isPaid ? 'Lunas' : 'Belum Bayar',
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
                'Bayar Tagihan',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.secondary,
                ),
              ),
              subtitle: Text(
                'Catat pengeluaran sebesar ${formatter.format(reminder.amount)} dan tandai lunas',
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
                'Sudah Lunas',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.secondary,
                ),
              ),
              subtitle: Text(
                'Pembayaran sudah tercatat untuk periode aktif ini',
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
              'Ubah Tagihan',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppTheme.darkSlate,
              ),
            ),
            subtitle: Text(
              'Perbarui nominal, tanggal jatuh tempo, atau periode',
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
              'Hapus Tagihan',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppTheme.error,
              ),
            ),
            subtitle: Text(
              'Hapus pengingat tagihan ini dari dompet Anda',
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
