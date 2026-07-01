import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../domain/entities/expense.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/category_icon.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final List<String> _presetIcons = [
    'restaurant',
    'directions_car',
    'shopping_bag',
    'local_hospital',
    'home',
    'receipt_long',
    'movie',
    'more_horiz',
    'flight',
    'favorite',
    'subscriptions',
    'pets',
    'card_giftcard',
    'help_outline',
    'school',
    'lightbulb',
    'shopping_cart',
  ];

  final List<String> _presetColors = [
    '#FF6B6B',
    '#4ECDC4',
    '#45B7D1',
    '#96CEB4',
    '#FFEAA7',
    '#DDA0DD',
    '#98D8C8',
    '#F7DC6F',
    '#BB8FCE',
    '#85C1E9',
    '#FF69B4',
    '#AED6F1',
    '#F0B27A',
    '#E6B0AA',
    '#BDC3C7',
    '#4F46E5',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchCategories();
    });
  }

  void _showCategoryFormDialog({ExpenseCategory? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    String selectedIcon = category?.icon ?? _presetIcons.first;
    String selectedColor = category?.color ?? _presetColors.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentColor = Color(
              int.parse(selectedColor.replaceFirst('#', '0xFF')),
            );

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                isEditing ? 'Edit Category' : 'Create Category',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlate,
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview Circle
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: currentColor.withAlpha(30),
                            shape: BoxShape.circle,
                            border: Border.all(color: currentColor, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: CategoryIcon(
                            icon: selectedIcon,
                            color: currentColor,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Name Field
                      Text(
                        'Category Name',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.darkSlateVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          color: AppTheme.darkSlate,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Subscriptions',
                          hintStyle: GoogleFonts.beVietnamPro(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF2F4F6),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Icon Picker
                      Text(
                        'Select Icon',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.darkSlateVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 52,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _presetIcons.length,
                          itemBuilder: (context, index) {
                            final iconName = _presetIcons[index];
                            final isIconSelected = selectedIcon == iconName;

                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedIcon = iconName;
                                });
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: isIconSelected
                                      ? currentColor.withAlpha(40)
                                      : const Color(0xFFF2F4F6),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isIconSelected
                                        ? currentColor
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: CategoryIcon(
                                  icon: iconName,
                                  color: isIconSelected
                                      ? currentColor
                                      : Colors.grey[600]!,
                                  size: 24,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Color Picker
                      Text(
                        'Select Color',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.darkSlateVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _presetColors.length,
                          itemBuilder: (context, index) {
                            final colHex = _presetColors[index];
                            final col = Color(
                              int.parse(colHex.replaceFirst('#', '0xFF')),
                            );
                            final isColSelected = selectedColor == colHex;

                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedColor = colHex;
                                });
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: col,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isColSelected
                                        ? Colors.black87
                                        : Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: isColSelected
                                      ? [
                                          BoxShadow(
                                            color: col.withAlpha(128),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : AppTheme.softShadow,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter category name'),
                        ),
                      );
                      return;
                    }

                    final provider = Provider.of<DashboardProvider>(
                      context,
                      listen: false,
                    );
                    bool success = false;

                    if (isEditing) {
                      success = await provider.updateCategory(
                        category.id,
                        name,
                        selectedIcon,
                        selectedColor,
                      );
                    } else {
                      success = await provider.addCategory(
                        name,
                        selectedIcon,
                        selectedColor,
                      );
                    }

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? (isEditing
                                      ? 'Category updated successfully'
                                      : 'Category created successfully')
                                : 'Failed to save category',
                          ),
                          backgroundColor: success
                              ? Colors.green
                              : Colors.redAccent,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Save' : 'Create',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleDeleteCategory(ExpenseCategory category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Delete Category',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "${category.name}"? Historical transactions will still keep this category, but you won\'t be able to select it for new entries.',
            style: GoogleFonts.beVietnamPro(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      final success = await provider.deleteCategory(category.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Category deleted successfully'
                  : 'Failed to delete category',
            ),
            backgroundColor: success ? Colors.green : Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final provider = Provider.of<DashboardProvider>(context);
    final categories = provider.categories;

    final double contentWidth = responsive.isTablet || responsive.isDesktop
        ? 480
        : double.infinity;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkSlate),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Manage Categories',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.darkSlate,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primary),
            onPressed: () => _showCategoryFormDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Container(
          width: contentWidth,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create and manage your own custom categories for more detailed financial tracking.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: AppTheme.darkSlateVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: categories.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSystem = cat.isDefault;
                          final color = Color(
                            int.parse(cat.color.replaceFirst('#', '0xFF')),
                          );

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.softShadow,
                            ),
                            child: Row(
                              children: [
                                // Category Icon Circle
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: CategoryIcon(
                                    icon: cat.icon,
                                    color: color,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppTheme.darkSlate,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSystem
                                              ? const Color(0xFFF1F5F9)
                                              : AppTheme.inversePrimary,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          isSystem
                                              ? 'System Default'
                                              : 'Custom',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isSystem
                                                ? Colors.grey[700]
                                                : AppTheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Actions (only if custom category)
                                if (!isSystem) ...[
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _showCategoryFormDialog(category: cat),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    onPressed: () => _handleDeleteCategory(cat),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
