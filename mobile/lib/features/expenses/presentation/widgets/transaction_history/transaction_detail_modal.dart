import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/expense.dart';
import '../../bloc/dashboard_bloc.dart';
import '../../bloc/dashboard_event.dart';
import '../../bloc/dashboard_state.dart';
import '../category_icon.dart';

class TransactionDetailModal extends StatelessWidget {
  final ExpenseEntity expense;
  final DashboardState provider;
  final String? currentUserId;
  final NumberFormat currencyFormatter;
  final VoidCallback? onDeleted;

  const TransactionDetailModal({
    super.key,
    required this.expense,
    required this.provider,
    required this.currentUserId,
    required this.currencyFormatter,
    this.onDeleted,
  });

  static Future<void> show(
    BuildContext context, {
    required ExpenseEntity expense,
    required DashboardState provider,
    required String? currentUserId,
    required NumberFormat currencyFormatter,
    VoidCallback? onDeleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionDetailModal(
        expense: expense,
        provider: provider,
        currentUserId: currentUserId,
        currencyFormatter: currencyFormatter,
        onDeleted: onDeleted,
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Hapus Transaksi?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Transaksi ini akan dihapus permanen dari riwayat aktivitas.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final completer = Completer<bool>();
      context.read<DashboardBloc>().add(
            DashboardDeleteExpenseRequested(expense.id, completer),
          );
      Navigator.of(context).pop(); // Close detail sheet
      onDeleted?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil dihapus'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(expense.date);
    final walletName = provider.activeWallet?.name ?? 'Dompet';
    final isShared = provider.isSharedMode;
    final isOwner =
        currentUserId == null || expense.userId == currentUserId || !isShared;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Detail Transaksi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 16),

              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7), // Light green
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF16A34A),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Transaksi Berhasil',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Amount
              Text(
                '- ${currencyFormatter.format(expense.amount)}',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFDC2626),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),

              // Receipt Box
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildRow(
                      label: 'Tanggal & Waktu',
                      value: '$formattedDate WIB',
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 20),
                    _buildRow(
                      label: 'Jenis Transaksi',
                      value: expense.type == ExpenseType.routine
                          ? 'Pengeluaran Rutin'
                          : 'Pengeluaran Non-Rutin',
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 20),
                    _buildRow(
                      label: 'Kategori',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Color(int.tryParse(expense.category.color
                                          .replaceFirst('#', '0xFF')) ??
                                      0xFF4F46E5)
                                  .withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: CategoryIcon(
                              icon: expense.category.icon,
                              color: Color(int.tryParse(expense.category.color
                                          .replaceFirst('#', '0xFF')) ??
                                      0xFF4F46E5),
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            expense.category.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkSlate,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 20),
                    _buildRow(
                      label: 'Rekening Sumber',
                      value: walletName,
                    ),
                    if (expense.description != null &&
                        expense.description!.trim().isNotEmpty) ...[
                      const Divider(color: Color(0xFFE2E8F0), height: 20),
                      _buildRow(
                        label: 'Catatan / Berita',
                        value: expense.description!.trim(),
                      ),
                    ],
                    if (isShared) ...[
                      const Divider(color: Color(0xFFE2E8F0), height: 20),
                      _buildRow(
                        label: 'Dicatat Oleh',
                        value: expense.creatorName,
                      ),
                    ],
                    const Divider(color: Color(0xFFE2E8F0), height: 20),
                    _buildRow(
                      label: 'ID Transaksi',
                      child: InkWell(
                        onTap: () => _copyToClipboard(
                          context,
                          expense.id,
                          'ID Transaksi',
                        ),
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          children: [
                            Text(
                              expense.id.length > 14
                                  ? '${expense.id.substring(0, 8)}...${expense.id.substring(expense.id.length - 4)}'
                                  : expense.id,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: AppTheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (isOwner) ...[
                      OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        label: Text(
                          'Hapus',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Tutup',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required String label,
    String? value,
    Widget? child,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (child != null)
          child
        else
          Flexible(
            child: Text(
              value ?? '-',
              textAlign: TextAlign.end,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkSlate,
              ),
            ),
          ),
      ],
    );
  }
}
