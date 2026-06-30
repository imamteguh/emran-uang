import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../domain/entities/bill_reminder.dart';
import '../providers/dashboard_provider.dart';
import 'category_icon.dart';

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

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    _titleController = TextEditingController(text: r?.title ?? '');
    _amountController = TextEditingController(
      text: r != null ? r.amount.toStringAsFixed(0) : '',
    );
    _selectedDate = r?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _periodicity = r?.periodicity ?? Periodicity.monthly;
    _selectedCategoryId = r?.categoryId;
    _notifyDaysBefore = r?.notifyDaysBefore ?? 3;
    _autoLogExpense = r?.autoLogExpense ?? false;

    // Fetch categories if not already available
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      if (provider.categories.isEmpty) {
        await provider.fetchCategories();
      }
      if (mounted) {
        setState(() {
          if (_selectedCategoryId == null && provider.categories.isNotEmpty) {
            _selectedCategoryId = provider.categories.first.id;
          }
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
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category first')),
      );
      return;
    }

    final double? amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final provider = Provider.of<DashboardProvider>(context, listen: false);
    bool success;

    final periodicityStr = _periodicity
        .toString()
        .split('.')
        .last
        .toUpperCase();

    if (widget.reminder == null) {
      // Create new
      success = await provider.addReminder(
        title: _titleController.text.trim(),
        amount: amount,
        dueDate: _selectedDate,
        periodicity: periodicityStr,
        categoryId: _selectedCategoryId,
        notifyDaysBefore: _notifyDaysBefore,
        autoLogExpense: _autoLogExpense,
      );
    } else {
      // Update existing
      success = await provider.updateReminder(
        id: widget.reminder!.id,
        title: _titleController.text.trim(),
        amount: amount,
        dueDate: _selectedDate,
        periodicity: periodicityStr,
        categoryId: _selectedCategoryId,
        notifyDaysBefore: _notifyDaysBefore,
        autoLogExpense: _autoLogExpense,
      );
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save bill. Please try again.'),
          ),
        );
      }
    }
  }

  String _formatEnglishDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    final isEdit = widget.reminder != null;
    final responsive = ResponsiveHelper(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Indicator & Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Bill' : 'Add New Bill',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: responsive.scaleFont(20),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.outline),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 20),

              // Title Field
              Text(
                'BILL NAME',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlateVariant,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.beVietnamPro(color: AppTheme.darkSlate),
                decoration: InputDecoration(
                  hintText: 'e.g. Netflix, Electricity, Wifi',
                  hintStyle: GoogleFonts.beVietnamPro(color: AppTheme.outline),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bill name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Amount Field
              Text(
                'AMOUNT (Rp)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlateVariant,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.darkSlate,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: AppTheme.outline,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 16, right: 8, top: 14),
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
                    return 'Amount cannot be empty';
                  }
                  final double? val = double.tryParse(value);
                  if (val == null || val <= 0) {
                    return 'Amount must be a positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category Selector (Horizontal Scroll)
              Text(
                'CATEGORY',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlateVariant,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              provider.categories.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : SizedBox(
                      height: 84,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: provider.categories.length,
                        itemBuilder: (context, index) {
                          final cat = provider.categories[index];
                          final isSelected = _selectedCategoryId == cat.id;
                          final color = Color(
                            int.parse(cat.color.replaceFirst('#', '0xFF')),
                          );

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategoryId = cat.id;
                              });
                            },
                            child: Container(
                              width: 72,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withValues(alpha: 0.15)
                                    : Colors.white,
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
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
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
              const SizedBox(height: 20),

              // Periodicity Pills
              Text(
                'BILL PERIOD',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlateVariant,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: Periodicity.values.map((p) {
                  final label = p == Periodicity.daily
                      ? 'Daily'
                      : p == Periodicity.weekly
                      ? 'Weekly'
                      : p == Periodicity.monthly
                      ? 'Monthly'
                      : 'Yearly';
                  final isSelected = _periodicity == p;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _periodicity = p;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected ? AppTheme.softShadow : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.darkSlate,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Due Date Selector & Remind Me
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DUE DATE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkSlateVariant,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: AppTheme.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formatEnglishDate(_selectedDate),
                                    style: GoogleFonts.beVietnamPro(
                                      color: AppTheme.darkSlate,
                                      fontSize: 13,
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

                  // Notify days before
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REMIND ME',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkSlateVariant,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _notifyDaysBefore,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: AppTheme.outline,
                              ),
                              style: GoogleFonts.beVietnamPro(
                                color: AppTheme.darkSlate,
                                fontSize: 13,
                              ),
                              isExpanded: true,
                              items: [1, 3, 5, 7].map((days) {
                                return DropdownMenuItem<int>(
                                  value: days,
                                  child: Text(
                                    '$days day${days > 1 ? 's' : ''} before',
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

              // Auto log expense switch
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auto-log Expense',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.darkSlate,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Automatically record transaction on due date.',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              color: AppTheme.darkSlateVariant,
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
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
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
                          isEdit ? 'Save Changes' : 'Create Bill',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
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
    );
  }
}
