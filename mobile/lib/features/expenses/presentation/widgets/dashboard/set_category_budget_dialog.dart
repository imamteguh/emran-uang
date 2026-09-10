import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/expense.dart';
import '../../bloc/dashboard_bloc.dart';
import '../../bloc/dashboard_event.dart';
import '../../bloc/dashboard_state.dart';
import '../category_icon.dart';

class SetCategoryBudgetDialog extends StatefulWidget {
  final DashboardState provider;
  final String? initialCategoryId;

  const SetCategoryBudgetDialog({
    super.key,
    required this.provider,
    this.initialCategoryId,
  });

  @override
  State<SetCategoryBudgetDialog> createState() =>
      _SetCategoryBudgetDialogState();
}

class _SetCategoryBudgetDialogState extends State<SetCategoryBudgetDialog> {
  late final TextEditingController _controller;
  String? _selectedCategoryId;
  bool _isSaving = false;
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    final categories = widget.provider.categories;

    // Pick initial category
    if (widget.initialCategoryId != null &&
        categories.any((c) => c.id == widget.initialCategoryId)) {
      _selectedCategoryId = widget.initialCategoryId;
    } else if (categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }

    final initialBudget = _getExistingBudgetForCategory(_selectedCategoryId);
    _controller = TextEditingController(
      text: initialBudget > 0 ? initialBudget.toStringAsFixed(0) : '',
    );
  }

  double _getExistingBudgetForCategory(String? categoryId) {
    if (categoryId == null) return 0.0;
    final wallet = widget.provider.activeWallet;
    if (wallet == null) return 0.0;
    for (final cb in wallet.categoryBudgets) {
      if (cb.categoryId == categoryId) {
        return cb.amount;
      }
    }
    return 0.0;
  }

  ExpenseCategory? get _selectedCategory {
    if (_selectedCategoryId == null) return null;
    try {
      return widget.provider.categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
      );
    } catch (_) {
      return null;
    }
  }

  void _onCategoryChanged(String? newCategoryId) {
    if (newCategoryId == null || newCategoryId == _selectedCategoryId) return;
    setState(() {
      _selectedCategoryId = newCategoryId;
      final existing = _getExistingBudgetForCategory(newCategoryId);
      _controller.text = existing > 0 ? existing.toStringAsFixed(0) : '';
    });
  }

  @override
  void dispose() {
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
    final catId = _selectedCategoryId;
    if (catId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih kategori terlebih dahulu.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final text = _controller.text.trim().replaceAll('.', '');
    final double? newBudget = double.tryParse(text);
    if (newBudget == null || newBudget < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nominal anggaran yang valid.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final completer = Completer<bool>();
      context.read<DashboardBloc>().add(
            DashboardSetCategoryBudgetRequested(
              categoryId: catId,
              amount: newBudget,
              completer: completer,
            ),
          );
      final success = await completer.future;
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (newBudget > 0
                      ? 'Anggaran kategori berhasil disimpan!'
                      : 'Anggaran kategori berhasil dihapus.')
                  : 'Gagal memperbarui anggaran kategori.',
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
  }

  Future<void> _handleDelete() async {
    final catId = _selectedCategoryId;
    if (catId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final completer = Completer<bool>();
      context.read<DashboardBloc>().add(
            DashboardDeleteCategoryBudgetRequested(
              categoryId: catId,
              completer: completer,
            ),
          );
      final success = await completer.future;
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Anggaran kategori berhasil dihapus.'
                  : 'Gagal menghapus anggaran kategori.',
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
  }

  @override
  Widget build(BuildContext context) {
    final selectedCat = _selectedCategory;
    final currentSpend = _selectedCategoryId != null
        ? widget.provider.categorySpendInCurrentMonth(_selectedCategoryId!)
        : 0.0;
    final existingBudget = _getExistingBudgetForCategory(_selectedCategoryId);
    final hasExistingBudget = existingBudget > 0;
    final Color catColor = selectedCat != null
        ? AppTheme.parseHexColor(selectedCat.color)
        : AppTheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: catColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CategoryIcon(
                        icon: selectedCat?.icon ?? 'category',
                        color: catColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Atur Anggaran Kategori',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkSlate,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Batas pengeluaran bulanan kategori ini',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: AppTheme.darkSlateVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: AppTheme.darkSlateVariant,
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Category Selector
                Text(
                  'Pilih Kategori',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkSlateVariant,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.outlineVariant.withAlpha(80),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategoryId,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: widget.provider.categories.map((cat) {
                        final color = AppTheme.parseHexColor(cat.color);
                        final budget = _getExistingBudgetForCategory(cat.id);
                        return DropdownMenuItem<String>(
                          value: cat.id,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              CategoryIcon(
                                icon: cat.icon,
                                color: color,
                                size: 16,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  cat.name,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                              ),
                              if (budget > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _currencyFormatter.format(budget),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.secondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: _isSaving ? null : _onCategoryChanged,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Real Month Spending Info Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: catColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: catColor.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: catColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pengeluaran bulan ini (${selectedCat?.name ?? "Kategori"}):',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                color: AppTheme.darkSlateVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currencyFormatter.format(currentSpend),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: currentSpend > existingBudget &&
                                        existingBudget > 0
                                    ? AppTheme.error
                                    : AppTheme.darkSlate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Amount Input Field
                Text(
                  'Nominal Anggaran Bulanan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkSlateVariant,
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  enabled: !_isSaving,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkSlate,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Text(
                        'Rp',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    hintText: '0',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      color: AppTheme.outlineVariant,
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.outlineVariant.withAlpha(80),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Quick Preset Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip('250 rb', 250000),
                    _buildChip('500 rb', 500000),
                    _buildChip('1 jt', 1000000),
                    _buildChip('2 jt', 2000000),
                    _buildChip('3 jt', 3000000),
                    _buildChip('5 jt', 5000000),
                  ],
                ),

                const SizedBox(height: 22),

                // Action Buttons
                Row(
                  children: [
                    if (hasExistingBudget) ...[
                      OutlinedButton(
                        onPressed: _isSaving ? null : _handleDelete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        child: const Icon(Icons.delete_outline, size: 20),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isSaving ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.darkSlateVariant,
                          side: BorderSide(
                            color: AppTheme.outlineVariant.withAlpha(120),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Simpan Anggaran',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, double amount) {
    return InkWell(
      onTap: _isSaving ? null : () => _setPreset(amount),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.outlineVariant.withAlpha(60)),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkSlate,
          ),
        ),
      ),
    );
  }
}
