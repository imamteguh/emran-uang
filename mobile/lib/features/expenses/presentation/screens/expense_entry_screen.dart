import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/wallet.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/category_icon.dart';
import '../widgets/user_avatar.dart';
import 'categories_screen.dart';

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
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      await provider.fetchCategories();
      if (mounted && provider.categories.isNotEmpty) {
        setState(() {
          _selectedCategory ??= provider.categories.first;
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
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final provider = Provider.of<DashboardProvider>(context, listen: false);
        final currencyCode = provider.activeWallet?.currency ?? 'IDR';
        final decimalDigits = CurrencyHelper.getFormatter(
          currencyCode,
        ).decimalDigits;

        String amountText = _amountController.text.trim();
        if (decimalDigits == 0) {
          // IDR/JPY: remove all formatting/thousand separators
          amountText = amountText.replaceAll(RegExp(r'[.,\s]'), '');
        } else {
          // USD/EUR: standard decimals
          if (amountText.contains(',') && amountText.contains('.')) {
            amountText = amountText.replaceAll(',', '');
          } else if (amountText.contains(',')) {
            amountText = amountText.replaceAll(',', '.');
          }
        }

        final double? amount = double.tryParse(amountText);
        if (amount == null || amount <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a positive amount')),
          );
          setState(() {
            _isSaving = false;
          });
          return;
        }

        final newExpense = ExpenseEntity(
          id: 'new_exp_${DateTime.now().millisecondsSinceEpoch}',
          amount: amount,
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          date: _selectedDate,
          type: _isRoutine ? ExpenseType.routine : ExpenseType.nonRoutine,
          userId: 'user1',
          walletId: provider.activeWallet?.id ?? 'personal_w1',
          category: _selectedCategory!,
          creatorName: 'Imam',
        );

        final success = await provider.addExpense(newExpense);
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save transaction. Please try again.')),
          );
        }

        if (mounted && success) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An error occurred: $e')),
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
  }

  void _showAllCategoriesBottomSheet(
    BuildContext context,
    List<ExpenseCategory> categories,
  ) {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final filteredCategories = categories.where((cat) {
              return cat.name.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
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
                              icon: const Icon(
                                Icons.close,
                                color: Colors.grey,
                                size: 22,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              splashRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: TextField(
                          onChanged: (val) {
                            setStateModal(() {
                              searchQuery = val;
                            });
                          },
                          style: GoogleFonts.beVietnamPro(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search categories...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.primary),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 20),
                                    onPressed: () {
                                      setStateModal(() {
                                        searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      Expanded(
                        child: filteredCategories.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No categories found',
                                        style: GoogleFonts.beVietnamPro(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : GridView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.95,
                                    ),
                                itemCount: filteredCategories.length,
                                itemBuilder: (context, index) {
                                  final cat = filteredCategories[index];
                                  final isSelected = _selectedCategory?.id == cat.id;
                                  final color = Color(
                                    int.parse(cat.color.replaceFirst('#', '0xFF')),
                                  );

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedCategory = cat;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? color.withAlpha(25)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: isSelected ? AppTheme.interactiveShadow : AppTheme.softShadow,
                                        border: Border.all(
                                          color: isSelected
                                              ? color
                                              : const Color(0xFFF1F5F9),
                                          width: isSelected ? 2.5 : 1.5,
                                        ),
                                      ),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Center(
                                                child: AnimatedScale(
                                                  scale: isSelected ? 1.05 : 1.0,
                                                  duration: const Duration(milliseconds: 200),
                                                  child: Container(
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
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                                child: Text(
                                                  cat.name,
                                                  style: GoogleFonts.beVietnamPro(
                                                    fontSize: 10,
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color: isSelected
                                                        ? color
                                                        : AppTheme.darkSlateVariant,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (isSelected)
                                            Positioned(
                                              top: -4,
                                              right: -4,
                                              child: Container(
                                                padding: const EdgeInsets.all(3),
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 1.5),
                                                ),
                                                child: const Icon(
                                                  Icons.check_rounded,
                                                  color: Colors.white,
                                                  size: 10,
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
                    ],
                  ),
                );
              },
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
    final displayCategories = provider.categories;

    final List<ExpenseCategory> gridCategories = [];
    if (displayCategories.length > 8) {
      final otherCat = displayCategories.firstWhere(
        (c) => c.name.toLowerCase() == 'other',
        orElse: () => displayCategories[7],
      );

      final first7 = displayCategories
          .where((c) => c.id != otherCat.id)
          .take(7)
          .toList();

      final isSelectedInFirst7 =
          _selectedCategory != null &&
          first7.any((c) => c.id == _selectedCategory!.id);

      gridCategories.addAll(first7);

      if (isSelectedInFirst7 ||
          _selectedCategory == null ||
          _selectedCategory!.id == otherCat.id) {
        gridCategories.add(otherCat);
      } else {
        gridCategories.add(_selectedCategory!);
      }
    } else {
      gridCategories.addAll(displayCategories);
    }

    final currencyCode = provider.activeWallet?.currency ?? 'IDR';
    final currencySymbol = CurrencyHelper.getFormatter(
      currencyCode,
    ).currencySymbol;

    final double cardWidth = responsive.isTablet || responsive.isDesktop
        ? 480
        : double.infinity;

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
        actions: [
          if (provider.allWallets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: PopupMenuButton<WalletEntity>(
                  onSelected: (WalletEntity wallet) {
                    provider.selectWallet(wallet);
                  },
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.1),
                  itemBuilder: (context) {
                    return [
                      if (provider.personalWallets.isNotEmpty) ...[
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
                        ...provider.personalWallets.map(
                          (wallet) => PopupMenuItem<WalletEntity>(
                            value: wallet,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  color: provider.activeWallet?.id == wallet.id
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
                                          provider.activeWallet?.id == wallet.id
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: AppTheme.darkSlate,
                                    ),
                                  ),
                                ),
                                if (provider.activeWallet?.id == wallet.id)
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
                      if (provider.sharedWallets.isNotEmpty) ...[
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
                        ...provider.sharedWallets.map(
                          (wallet) => PopupMenuItem<WalletEntity>(
                            value: wallet,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.groups_outlined,
                                  color: provider.activeWallet?.id == wallet.id
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
                                          provider.activeWallet?.id == wallet.id
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: AppTheme.darkSlate,
                                    ),
                                  ),
                                ),
                                if (provider.activeWallet?.id == wallet.id)
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          provider.isSharedMode
                              ? Icons.groups_rounded
                              : Icons.person_rounded,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: Text(
                            provider.activeWallet?.name ?? 'Select Wallet',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppTheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
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
                    // Enter Amount Section - Redesigned to Premium Card
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppTheme.roundedBorder,
                        boxShadow: AppTheme.softShadow,
                        border: Border.all(
                          color: const Color(0xFFF1F5F9),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'ENTER AMOUNT',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppTheme.darkSlateVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withAlpha(15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  currencySymbol.trim(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _amountController,
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: false,
                                  ),
                                  inputFormatters: [
                                    CurrencyInputFormatter(
                                      CurrencyHelper.getFormatter(currencyCode),
                                    ),
                                  ],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    hintText: CurrencyHelper.getFormatter(currencyCode).decimalDigits == 0 ? '0' : '0.00',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.primary.withAlpha(70),
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    fillColor: Colors.transparent,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  textAlign: TextAlign.left,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Amount is required';
                                    }
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CategoriesScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Manage Category',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.95,
                          ),
                      itemCount: gridCategories.length,
                      itemBuilder: (context, index) {
                        final cat = gridCategories[index];
                        final isSelected = _selectedCategory?.id == cat.id;
                        final color = Color(
                          int.parse(cat.color.replaceFirst('#', '0xFF')),
                        );

                        return GestureDetector(
                          onTap: () {
                            if (cat.name.toLowerCase() == 'other') {
                              _showAllCategoriesBottomSheet(
                                context,
                                displayCategories,
                              );
                            } else {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withAlpha(25)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isSelected ? AppTheme.interactiveShadow : AppTheme.softShadow,
                              border: Border.all(
                                color: isSelected
                                    ? color
                                    : const Color(0xFFF1F5F9),
                                width: isSelected ? 2.5 : 1.5,
                              ),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Center(
                                      child: AnimatedScale(
                                        scale: isSelected ? 1.05 : 1.0,
                                        duration: const Duration(milliseconds: 200),
                                        child: Container(
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
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Text(
                                        cat.name,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 10,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? color
                                              : AppTheme.darkSlateVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Transaction Date Selector
                    Text(
                      'Transaction Date',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.darkSlateVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateChip(
                            label: 'Today',
                            isSelected: _isSameDay(_selectedDate, DateTime.now()),
                            onTap: () {
                              setState(() {
                                _selectedDate = DateTime.now();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDateChip(
                            label: 'Yesterday',
                            isSelected: _isSameDay(
                              _selectedDate,
                              DateTime.now().subtract(const Duration(days: 1)),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedDate = DateTime.now().subtract(const Duration(days: 1));
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _buildCustomDateButton(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Input Form Fields (Notes / Description)
                    TextFormField(
                      controller: _descController,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        color: AppTheme.darkSlate,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Transaction Note',
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                        hintText: 'What was this expense for?',
                        hintStyle: GoogleFonts.beVietnamPro(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.notes_rounded,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Routine Toggle Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppTheme.roundedBorder,
                        boxShadow: AppTheme.softShadow,
                        border: Border.all(
                          color: const Color(0xFFF1F5F9),
                          width: 1.5,
                        ),
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
                            child: const Icon(
                              Icons.sync,
                              color: AppTheme.secondary,
                            ),
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
                    if (provider.isSharedMode) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppTheme.roundedBorder,
                          boxShadow: AppTheme.softShadow,
                          border: Border.all(
                            color: const Color(0xFFF1F5F9),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                if (provider.activeWallet?.groupMembers !=
                                        null &&
                                    provider
                                        .activeWallet!
                                        .groupMembers!
                                        .isNotEmpty)
                                  _buildFormOverlappingAvatars(
                                    provider.activeWallet!.groupMembers!,
                                  )
                                else
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.primary.withAlpha(25),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.group,
                                      color: AppTheme.primary,
                                      size: 18,
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                Text(
                                  'Shared with Group',
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
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _isSaving ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shadowColor: AppTheme.primary.withAlpha(76),
                        elevation: 4,
                        minimumSize: const Size(double.infinity, 56),
                        shape: const StadiumBorder(),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save_rounded, size: 20),
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

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildDateChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withAlpha(20) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected ? AppTheme.interactiveShadow : AppTheme.softShadow,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primary : AppTheme.darkSlateVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateButton(BuildContext context) {
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final isYesterday = _isSameDay(_selectedDate, DateTime.now().subtract(const Duration(days: 1)));
    final isQuickSelect = isToday || isYesterday;

    final String formattedDate = DateFormat('EEE, d MMM yyyy').format(_selectedDate);

    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
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
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: !isQuickSelect ? AppTheme.primary.withAlpha(20) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !isQuickSelect ? AppTheme.primary : const Color(0xFFE2E8F0),
            width: !isQuickSelect ? 2.0 : 1.0,
          ),
          boxShadow: !isQuickSelect ? AppTheme.interactiveShadow : AppTheme.softShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: !isQuickSelect ? AppTheme.primary : AppTheme.darkSlateVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isQuickSelect ? 'Other Date...' : formattedDate,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: !isQuickSelect ? FontWeight.bold : FontWeight.normal,
                  color: !isQuickSelect ? AppTheme.primary : AppTheme.darkSlateVariant,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormOverlappingAvatars(List<dynamic> members) {
    final displayMembers = members.take(3).toList();
    final remainingCount = members.length - displayMembers.length;

    final double avatarSize = 32.0;
    final double overlapOffset = 20.0;
    double totalWidth = 0.0;
    if (displayMembers.isNotEmpty) {
      totalWidth = (displayMembers.length - 1) * overlapOffset + avatarSize;
      if (remainingCount > 0) {
        totalWidth += overlapOffset;
      }
    }

    return SizedBox(
      height: 32,
      width: totalWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < displayMembers.length; i++)
            Positioned(
              left: i * overlapOffset,
              child: UserAvatar(
                avatarUrl: displayMembers[i]['avatarUrl'],
                displayName: displayMembers[i]['displayName'] ?? '',
                size: avatarSize,
              ),
            ),
          if (remainingCount > 0)
            Positioned(
              left: displayMembers.length * overlapOffset,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: AppTheme.tertiaryFixed,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$remainingCount',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.onTertiaryFixed,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat formatter;
  CurrencyInputFormatter(this.formatter);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Strip all non-digits to get raw number value
    String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '', selection: const TextSelection.collapsed(offset: 0));
    }

    double value = double.parse(digitsOnly);
    if (formatter.decimalDigits! > 0) {
      value /= 100.0;
    }

    // Format the number part (without the currency symbol prefix)
    String symbol = formatter.currencySymbol;
    String formatted = formatter.format(value);
    
    // Safely remove the currency symbol from the formatted text
    // E.g., for 'Rp 10.000', remove 'Rp ' or 'Rp'
    String formattedNumber = formatted
        .replaceFirst(symbol.trim(), '')
        .replaceFirst(symbol, '')
        .trim();

    return newValue.copyWith(
      text: formattedNumber,
      selection: TextSelection.collapsed(offset: formattedNumber.length),
    );
  }
}
