import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }
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
        return;
      }

      final newExpense = ExpenseEntity(
        id: 'new_exp_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
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
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.95,
                          ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
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
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary.withAlpha(20)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.softShadow,
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : const Color(0xFFF1F5F9),
                                width: isSelected ? 2.5 : 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: CategoryIcon(
                                    icon: cat.icon,
                                    color: color,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  cat.name,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.darkSlateVariant,
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
                                currencySymbol,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                child: TextFormField(
                                  controller: _amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
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
                                    if (val == null || val.isEmpty) {
                                      return 'Required';
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
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary.withAlpha(20)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.softShadow,
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : const Color(0xFFF1F5F9),
                                width: isSelected ? 2.5 : 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: CategoryIcon(
                                    icon: cat.icon,
                                    color: color,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  cat.name,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.darkSlateVariant,
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
                    const SizedBox(height: 32),

                    // Input Form Fields
                    TextFormField(
                      controller: _descController,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        color: AppTheme.darkSlate,
                      ),
                      decoration: InputDecoration(
                        hintText: 'What was this for?',
                        hintStyle: GoogleFonts.beVietnamPro(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        suffixIcon: Icon(
                          Icons.edit,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF2F4F6),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 2,
                          ),
                        ),
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
                    const SizedBox(height: 36),

                    ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shadowColor: AppTheme.primary.withValues(alpha: 0.3),
                        elevation: 6,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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
