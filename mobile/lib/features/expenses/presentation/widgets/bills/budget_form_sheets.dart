import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../expenses/domain/entities/expense.dart';
import '../../bloc/dashboard_bloc.dart';
import '../../bloc/dashboard_event.dart';
import '../../bloc/dashboard_state.dart';
import '../category_icon.dart';

class BudgetFormSheets {
  /// Opens the Monthly Budget Bottom Sheet Form
  static Future<void> showSetMonthlyBudgetSheet({
    required BuildContext context,
    required DashboardState provider,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SetMonthlyBudgetSheet(provider: provider),
    );
  }

  /// Opens the Category Budget Bottom Sheet Form
  static Future<void> showSetCategoryBudgetSheet({
    required BuildContext context,
    required DashboardState provider,
    String? categoryId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SetCategoryBudgetSheet(
        provider: provider,
        initialCategoryId: categoryId,
      ),
    );
  }

  /// Opens the Delete Category Budget Confirmation Bottom Sheet
  static Future<void> showConfirmDeleteCategoryBudgetSheet({
    required BuildContext context,
    required ExpenseCategory category,
    required DashboardState provider,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ConfirmDeleteCategoryBudgetSheet(
        category: category,
        provider: provider,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. SET MONTHLY BUDGET SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _SetMonthlyBudgetSheet extends StatefulWidget {
  final DashboardState provider;

  const _SetMonthlyBudgetSheet({required this.provider});

  @override
  State<_SetMonthlyBudgetSheet> createState() => _SetMonthlyBudgetSheetState();
}

class _SetMonthlyBudgetSheetState extends State<_SetMonthlyBudgetSheet> {
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
          if (success) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Batas anggaran bulanan berhasil disimpan'),
                backgroundColor: AppTheme.secondary,
              ),
            );
          } else {
            setState(() {
              _isSaving = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal menyimpan anggaran bulanan'),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = [1000000.0, 2000000.0, 3000000.0, 5000000.0, 10000000.0];
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atur Anggaran Bulanan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Batas total pengeluaran dompet per bulan',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: AppTheme.darkSlateVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.outline),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: Color(0xFFF1F5F9), height: 20),
            const SizedBox(height: 12),

            // Input Field
            Text(
              'NOMINAL ANGGARAN',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkSlateVariant,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkSlate,
              ),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
                hintText: '0',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Preset Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: presets.map((amount) {
                  final isSelected = _currentAmount == amount;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(
                        formatter.format(amount),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.darkSlate,
                        ),
                      ),
                      backgroundColor: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide.none,
                      ),
                      onPressed: () => _setPreset(amount),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Sync with Daily Budget Switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sync_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sinkronkan Anggaran Harian',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        Text(
                          'Otomatis hitung batas harian (dibagi hari dlm bulan)',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 10.5,
                            color: AppTheme.darkSlateVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _syncDailyBudget,
                    activeThumbColor: AppTheme.primary,
                    onChanged: (val) {
                      setState(() {
                        _syncDailyBudget = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Simpan Anggaran Bulanan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. SET CATEGORY BUDGET SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _SetCategoryBudgetSheet extends StatefulWidget {
  final DashboardState provider;
  final String? initialCategoryId;

  const _SetCategoryBudgetSheet({
    required this.provider,
    this.initialCategoryId,
  });

  @override
  State<_SetCategoryBudgetSheet> createState() => _SetCategoryBudgetSheetState();
}

class _SetCategoryBudgetSheetState extends State<_SetCategoryBudgetSheet> {
  late final TextEditingController _controller;
  String? _selectedCategoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final categories = widget.provider.categories;

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onCategorySelected(String catId) {
    setState(() {
      _selectedCategoryId = catId;
      final existing = _getExistingBudgetForCategory(catId);
      _controller.text = existing > 0 ? existing.toStringAsFixed(0) : '';
    });
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
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }

    final double? amount = double.tryParse(_controller.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal anggaran yang valid')),
      );
      return;
    }

    final wallet = widget.provider.activeWallet;
    if (wallet == null) return;

    setState(() {
      _isSaving = true;
    });

    final completer = Completer<bool>();
    context.read<DashboardBloc>().add(
          DashboardSetCategoryBudgetRequested(
            categoryId: catId,
            amount: amount,
            completer: completer,
          ),
        );

    final success = await completer.future;
    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anggaran kategori berhasil disimpan'),
            backgroundColor: AppTheme.secondary,
          ),
        );
      } else {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan anggaran kategori'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.provider.categories;
    final isEdit = widget.initialCategoryId != null;
    final presets = [250000.0, 500000.0, 1000000.0, 1500000.0, 2500000.0];
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Ubah Anggaran Kategori' : 'Tambah Anggaran Kategori',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tentukan kuota pengeluaran untuk kategori ini',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: AppTheme.darkSlateVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.outline),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: Color(0xFFF1F5F9), height: 20),
            const SizedBox(height: 10),

            // Category Selection (Horizontal List)
            Text(
              'PILIH KATEGORI',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkSlateVariant,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 74,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategoryId == cat.id;
                  final color = Color(
                    int.parse(cat.color.replaceFirst('#', '0xFF')),
                  );

                  return GestureDetector(
                    onTap: () => _onCategorySelected(cat.id),
                    child: Container(
                      width: 68,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? color : const Color(0xFFE2E8F0),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CategoryIcon(
                            icon: cat.icon,
                            color: color,
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              cat.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: AppTheme.darkSlate,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // Input Field
            Text(
              'BATAS ANGGARAN (Rp)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkSlateVariant,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkSlate,
              ),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
                hintText: '0',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Preset Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: presets.map((amount) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(
                        formatter.format(amount),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      backgroundColor: const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide.none,
                      ),
                      onPressed: () => _setPreset(amount),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Simpan Anggaran Kategori',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. CONFIRM DELETE CATEGORY BUDGET SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmDeleteCategoryBudgetSheet extends StatelessWidget {
  final ExpenseCategory category;
  final DashboardState provider;

  const _ConfirmDeleteCategoryBudgetSheet({
    required this.category,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
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
            'Hapus Anggaran Kategori',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Apakah Anda yakin ingin menghapus batasan anggaran untuk kategori "${category.name}"?',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppTheme.darkSlateVariant,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final wallet = provider.activeWallet;
                    if (wallet == null) return;
                    final completer = Completer<bool>();
                    context.read<DashboardBloc>().add(
                          DashboardDeleteCategoryBudgetRequested(
                            categoryId: category.id,
                            completer: completer,
                          ),
                        );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Hapus',
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
    );
  }
}
