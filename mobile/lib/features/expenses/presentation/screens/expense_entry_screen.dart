import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../domain/entities/expense.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/category_icon.dart';

class ExpenseEntryScreen extends StatefulWidget {
  const ExpenseEntryScreen({super.key});

  @override
  State<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends State<ExpenseEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  
  bool _isRoutine = false;
  ExpenseCategory? _selectedCategory;

  // Grid layout categories exactly from the database but as fallback
  final List<ExpenseCategory> _categories = [
    ExpenseCategory(id: 'c1', name: 'Food', icon: 'restaurant', color: '#FF6B6B'),
    ExpenseCategory(id: 'c2', name: 'Travel', icon: 'flight', color: '#85C1E9'),
    ExpenseCategory(id: 'c3', name: 'Shopping', icon: 'shopping_bag', color: '#F7DC6F'),
    ExpenseCategory(id: 'c4', name: 'Health', icon: 'local_hospital', color: '#98D8C8'),
    ExpenseCategory(id: 'c5', name: 'Home', icon: 'home', color: '#4ECDC4'),
    ExpenseCategory(id: 'c6', name: 'Bills', icon: 'lightbulb', color: '#FFEAA7'),
    ExpenseCategory(id: 'c7', name: 'Fun', icon: 'movie', color: '#DDA0DD'),
    ExpenseCategory(id: 'c8', name: 'Other', icon: 'help_outline', color: '#BDC3C7'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      await provider.fetchCategories();
      if (mounted && provider.categories.isNotEmpty) {
        setState(() {
          _selectedCategory = provider.categories.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      final double? amount = double.tryParse(_amountController.text.trim());
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a positive amount')),
        );
        return;
      }

      final provider = Provider.of<DashboardProvider>(context, listen: false);

      final newExpense = ExpenseEntity(
        id: 'new_exp_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        date: DateTime.now(),
        type: _isRoutine ? ExpenseType.routine : ExpenseType.nonRoutine,
        userId: 'user1',
        walletId: provider.activeWallet?.id ?? 'personal_w1',
        category: _selectedCategory!,
        creatorName: 'Imam',
      );

      await provider.addExpense(newExpense);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showAllCategoriesBottomSheet(
    BuildContext context,
    List<ExpenseCategory> categories,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'All Categories',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey, size: 22),
                          onPressed: () => Navigator.of(context).pop(),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = _selectedCategory?.id == cat.id;
                        final color = Color(int.parse(cat.color.replaceFirst('#', '0xFF')));

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                            });
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.softShadow,
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
                                width: isSelected ? 2.5 : 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: CategoryIcon(
                                    icon: cat.icon,
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cat.name,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppTheme.primary : AppTheme.darkSlateVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final provider = Provider.of<DashboardProvider>(context);
    final displayCategories = provider.categories.isNotEmpty ? provider.categories : _categories;

    final double cardWidth = responsive.isTablet || responsive.isDesktop ? 480 : double.infinity;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkSlateVariant),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add Transaction',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: AppTheme.darkSlate,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsive.screenPadding,
          child: Center(
            child: SizedBox(
              width: cardWidth,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Enter Amount Section
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Enter Amount',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkSlateVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Rp ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              SizedBox(
                                width: 220,
                                child: TextFormField(
                                  controller: _amountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    hintText: '0.00',
                                    fillColor: Colors.transparent,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  textAlign: TextAlign.left,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return 'Required';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Grid Categories Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Category',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.darkSlateVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showAllCategoriesBottomSheet(context, displayCategories),
                          child: const Text('See All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: displayCategories.length > 8 ? 8 : displayCategories.length,
                      itemBuilder: (context, index) {
                        final cat = displayCategories[index];
                        final isSelected = _selectedCategory?.id == cat.id;
                        final color = Color(int.parse(cat.color.replaceFirst('#', '0xFF')));

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.softShadow,
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
                                width: isSelected ? 2.5 : 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: CategoryIcon(
                                    icon: cat.icon,
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cat.name,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppTheme.primary : AppTheme.darkSlateVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Input Form Fields
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        hintText: 'What was this for?',
                        prefixIcon: Icon(Icons.edit, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Routine Toggle Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppTheme.roundedBorder,
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppTheme.secondaryContainer,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.sync, color: AppTheme.secondary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Routine Expense',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                                Text(
                                  'Set as recurring monthly',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 11,
                                    color: AppTheme.darkSlateVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isRoutine,
                            onChanged: (val) {
                              setState(() {
                                _isRoutine = val;
                              });
                            },
                            activeThumbColor: AppTheme.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Shared With section (only relevant in shared mode)
                    if (provider.isSharedMode)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppTheme.roundedBorder,
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                // Group icon
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.primary.withAlpha(25),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.group, color: AppTheme.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Dibagi Bersama',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    const SizedBox(height: 36),

                    ElevatedButton(
                      onPressed: _handleSubmit,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Save Transaction',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
