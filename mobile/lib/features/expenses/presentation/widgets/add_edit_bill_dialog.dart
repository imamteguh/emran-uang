import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../domain/entities/bill_reminder.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import 'category_icon.dart';
import 'bills/bills_date_formatter.dart';

class AddEditBillDialog extends StatefulWidget {
  final BillReminderEntity? reminder;

  const AddEditBillDialog({super.key, this.reminder});

  @override
  State<AddEditBillDialog> createState() => _AddEditBillDialogState();
}

class _AddEditBillDialogState extends State<AddEditBillDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;

  late DateTime _selectedDate;
  late Periodicity _periodicity;
  String? _selectedCategoryId;
  late int _notifyDaysBefore;
  late bool _autoLogExpense;

  bool _isSaving = false;

  static const List<int> _presetAmounts = [
    50000,
    100000,
    250000,
    500000,
    1000000,
    2500000,
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    _titleController = TextEditingController(text: r?.title ?? '');
    _amountController = TextEditingController(
      text: r != null ? _formatNumber(r.amount.toInt()) : '',
    );
    _selectedDate = r?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _periodicity = (r?.periodicity == Periodicity.yearly)
        ? Periodicity.yearly
        : Periodicity.monthly;
    _selectedCategoryId = r?.categoryId;
    _notifyDaysBefore = r?.notifyDaysBefore ?? 3;
    _autoLogExpense = r?.autoLogExpense ?? false;

    // Fetch categories if not already available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardBloc = context.read<DashboardBloc>();
      if (dashboardBloc.state.categories.isEmpty) {
        dashboardBloc.add(const DashboardFetchCategoriesRequested());
      }
      if (mounted && _selectedCategoryId == null && dashboardBloc.state.categories.isNotEmpty) {
        setState(() {
          _selectedCategoryId = dashboardBloc.state.categories.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatNumber(int number) {
    return NumberFormat.decimalPattern('id_ID').format(number);
  }

  void _applyPreset(int amount) {
    setState(() {
      _amountController.text = _formatNumber(amount);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.darkSlate,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final categories = context.read<DashboardBloc>().state.categories;
    final effectiveCategoryId = _selectedCategoryId ??
        (categories.isNotEmpty ? categories.first.id : null);

    if (effectiveCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kategori terlebih dahulu')),
      );
      return;
    }

    // Bersihkan format ribuan dari input (titik, koma, spasi)
    final cleanText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final double? amount = double.tryParse(cleanText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan nominal yang valid (> 0)')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final dashboardBloc = context.read<DashboardBloc>();
    final periodicityStr = _periodicity
        .toString()
        .split('.')
        .last
        .toUpperCase();

    final completer = Completer<bool>();
    if (widget.reminder == null) {
      dashboardBloc.add(DashboardAddReminderRequested(
        title: _titleController.text.trim(),
        amount: amount,
        dueDate: _selectedDate,
        periodicity: periodicityStr,
        categoryId: effectiveCategoryId,
        notifyDaysBefore: _notifyDaysBefore,
        autoLogExpense: _autoLogExpense,
        completer: completer,
      ));
    } else {
      dashboardBloc.add(DashboardUpdateReminderRequested(
        id: widget.reminder!.id,
        title: _titleController.text.trim(),
        amount: amount,
        dueDate: _selectedDate,
        periodicity: periodicityStr,
        categoryId: effectiveCategoryId,
        notifyDaysBefore: _notifyDaysBefore,
        autoLogExpense: _autoLogExpense,
        completer: completer,
      ));
    }

    final success = await completer.future;

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.reminder == null
                  ? 'Tagihan "${_titleController.text.trim()}" berhasil ditambahkan'
                  : 'Perubahan tagihan berhasil disimpan',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan tagihan. Silakan coba lagi.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  String _formatIndonesianDate(DateTime date) {
    return '${BillsDateFormatter.formatDayMonth(date)} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardBloc>().state;
    final isEdit = widget.reminder != null;
    final responsive = ResponsiveHelper(context);
    final walletName = provider.activeWallet?.name ?? 'Dompet Utama';

    final effectiveCategoryId = _selectedCategoryId ??
        (provider.categories.isNotEmpty ? provider.categories.first.id : null);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
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

                  // Header Bar (Title & Close Button)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Ubah Tagihan' : 'Tambah Tagihan Baru',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: responsive.scaleFont(18),
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkSlate,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                walletName,
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.outline),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 8),

                  // 1. Title Field
                  Text(
                    'NAMA TAGIHAN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkSlateVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkSlate,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Misal: Listrik PLN, WiFi Indihome, BPJS, Kos',
                      hintStyle: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: AppTheme.outline,
                      ),
                      prefixIcon: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama tagihan tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 2. Amount Field
                  Text(
                    'NOMINAL TAGIHAN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkSlateVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppTheme.darkSlate,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: AppTheme.outline,
                        fontSize: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 16, right: 8, top: 12),
                        child: Text(
                          'Rp ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nominal tidak boleh kosong';
                      }
                      final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
                      final val = double.tryParse(clean);
                      if (val == null || val <= 0) {
                        return 'Nominal harus lebih dari 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Preset Nominal Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _presetAmounts.map((amt) {
                        final formatted = _formatNumber(amt);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => _applyPreset(amt),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                'Rp $formatted',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.darkSlate,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Category Selector
                  Text(
                    'KATEGORI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkSlateVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  provider.categories.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(color: AppTheme.primary),
                          ),
                        )
                      : SizedBox(
                          height: 88,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: provider.categories.length,
                            itemBuilder: (context, index) {
                              final cat = provider.categories[index];
                              final isSelected = effectiveCategoryId == cat.id;
                              final color = Color(
                                int.parse(cat.color.replaceFirst('#', '0xFF')),
                              );

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategoryId = cat.id;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 76,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withValues(alpha: 0.15)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? color
                                          : const Color(0xFFE2E8F0),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CategoryIcon(
                                        icon: cat.icon,
                                        color: color,
                                        size: 26,
                                      ),
                                      const SizedBox(height: 6),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          cat.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10.5,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
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
                  const SizedBox(height: 20),

                  // 4. Periodicity Switcher
                  Text(
                    'PERIODE TAGIHAN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkSlateVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Periodicity.monthly,
                      Periodicity.yearly,
                    ].map((p) {
                      final isMonthly = p == Periodicity.monthly;
                      final label = isMonthly ? 'Bulanan' : 'Tahunan';
                      final subtitle = isMonthly ? 'Setiap bulan' : 'Setiap tahun';
                      final isSelected = _periodicity == p;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _periodicity = p;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: EdgeInsets.only(
                              right: isMonthly ? 6 : 0,
                              left: isMonthly ? 0 : 6,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.darkSlate,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 10.5,
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 5. Due Date & Notification
                  Row(
                    children: [
                      // Due Date Picker
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'JATUH TEMPO',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkSlateVariant,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _selectDate(context),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 13,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      color: AppTheme.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _formatIndonesianDate(_selectedDate),
                                        style: GoogleFonts.plusJakartaSans(
                                          color: AppTheme.darkSlate,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Remind Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'INGATKAN SAYA',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkSlateVariant,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _notifyDaysBefore,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Color(0xFF64748B),
                                  ),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.darkSlate,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  isExpanded: true,
                                  items: [1, 2, 3, 5, 7].map((days) {
                                    return DropdownMenuItem<int>(
                                      value: days,
                                      child: Text(
                                        '$days hari sebelum',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _notifyDaysBefore = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 6. Auto-log Switch
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Catat Otomatis Pengeluaran',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: AppTheme.darkSlate,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Otomatis membuat transaksi saat jatuh tempo tiba.',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _autoLogExpense,
                          activeThumbColor: AppTheme.primary,
                          onChanged: (val) {
                            setState(() {
                              _autoLogExpense = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 7. Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isEdit ? 'Simpan Perubahan' : 'Tambah Tagihan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
