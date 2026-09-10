import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/currency_helper.dart';
import '../../bloc/dashboard_bloc.dart';
import '../../bloc/dashboard_event.dart';
import '../../bloc/dashboard_state.dart';

class SetMonthlyBudgetDialog extends StatefulWidget {
  final DashboardState provider;

  const SetMonthlyBudgetDialog({super.key, required this.provider});

  @override
  State<SetMonthlyBudgetDialog> createState() => _SetMonthlyBudgetDialogState();
}

class _SetMonthlyBudgetDialogState extends State<SetMonthlyBudgetDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;
  bool _syncDailyBudget = true;
  double _currentAmount = 0.0;

  @override
  void initState() {
    super.initState();
    final initialBudget = widget.provider.activeWallet?.monthlyBudget ??
        (widget.provider.activeWallet?.dailyBudget != null
            ? widget.provider.activeWallet!.dailyBudget! *
                widget.provider.daysInCurrentMonth
            : null);

    _controller = TextEditingController(
      text: initialBudget != null ? initialBudget.toStringAsFixed(0) : '',
    );
    _currentAmount = initialBudget ?? 0.0;

    _controller.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    final parsed = double.tryParse(_controller.text.trim()) ?? 0.0;
    if (parsed != _currentAmount) {
      setState(() {
        _currentAmount = parsed;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onAmountChanged);
    _controller.dispose();
    super.dispose();
  }

  void _setPreset(double amount) {
    _controller.text = amount.toStringAsFixed(0);
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  Future<void> _handleSave() async {
    final double? newBudget = double.tryParse(_controller.text.trim());
    if (newBudget != null && newBudget >= 0) {
      setState(() {
        _isSaving = true;
      });
      try {
        final completer = Completer<bool>();
        context.read<DashboardBloc>().add(
              DashboardUpdateMonthlyBudgetRequested(
                newBudget,
                completer,
                syncDailyBudget: _syncDailyBudget,
              ),
            );
        final success = await completer.future;
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Anggaran bulanan berhasil diperbarui!'
                    : 'Gagal memperbarui anggaran bulanan.',
              ),
              backgroundColor: success ? AppTheme.secondary : AppTheme.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terjadi kesalahan: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan jumlah anggaran yang valid'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyCode = widget.provider.activeWallet?.currency ?? 'IDR';
    final formatter = CurrencyHelper.getFormatter(currencyCode);
    final daysInMonth = widget.provider.daysInCurrentMonth;
    final dailyShare = _currentAmount > 0 ? (_currentAmount / daysInMonth) : 0.0;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.white,
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
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
                  Icons.calendar_month_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Anggaran Bulanan',
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
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            splashRadius: 20,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tentukan batas target pengeluaran bulanan Anda untuk menjaga keuangan tetap seimbang dan terkendali.',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: AppTheme.darkSlateVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Input field
            TextField(
              controller: _controller,
              enabled: !_isSaving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.darkSlate,
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppTheme.primary,
                  size: 20,
                ),
                prefixText: currencyCode == 'IDR' ? 'Rp ' : '$currencyCode ',
                prefixStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  fontSize: 16,
                ),
                hintText: 'cth. 3,000,000',
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

            const SizedBox(height: 12),

            // Quick preset chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip('1 Jt', 1000000),
                _buildPresetChip('2.5 Jt', 2500000),
                _buildPresetChip('5 Jt', 5000000),
                _buildPresetChip('10 Jt', 10000000),
              ],
            ),

            const SizedBox(height: 16),

            // Real-time calculation helper box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineVariant.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_graph_rounded,
                    size: 20,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alokasi Harian Otomatis',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkSlateVariant,
                          ),
                        ),
                        Text(
                          _currentAmount > 0
                              ? '${formatter.format(dailyShare)} / hari ($daysInMonth hari)'
                              : 'Masukkan nominal di atas',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _currentAmount > 0
                                ? AppTheme.primary
                                : AppTheme.darkSlateVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Sync with daily budget checkbox
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _syncDailyBudget,
              onChanged: _isSaving
                  ? null
                  : (val) {
                      setState(() {
                        _syncDailyBudget = val ?? true;
                      });
                    },
              title: Text(
                'Perbarui target harian otomatis',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkSlate,
                ),
              ),
              subtitle: Text(
                'Sesuaikan budget harian dengan pembagian bulan ini',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: AppTheme.darkSlateVariant,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppTheme.primary,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Simpan Anggaran',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, double amount) {
    final isSelected = (_currentAmount - amount).abs() < 1;

    return InkWell(
      onTap: _isSaving ? null : () => _setPreset(amount),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withAlpha(30)
              : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.primary : AppTheme.darkSlate,
          ),
        ),
      ),
    );
  }
}
