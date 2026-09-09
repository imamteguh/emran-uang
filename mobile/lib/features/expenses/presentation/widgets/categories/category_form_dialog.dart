import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/expense.dart';
import '../../bloc/dashboard_bloc.dart';
import '../../bloc/dashboard_event.dart';
import '../category_icon.dart';

class CategoryFormDialog extends StatefulWidget {
  final ExpenseCategory? category;

  const CategoryFormDialog({
    super.key,
    this.category,
  });

  static Future<void> show(BuildContext context, {ExpenseCategory? category}) {
    return showDialog(
      context: context,
      builder: (_) => CategoryFormDialog(category: category),
    );
  }

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  static const List<String> presetIcons = [
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

  static const List<String> presetColors = [
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

  late final TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.icon ?? presetIcons.first;
    _selectedColor = widget.category?.color ?? presetColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter category name')),
      );
      return;
    }

    final dashboardBloc = context.read<DashboardBloc>();
    final isEditing = widget.category != null;
    final completer = Completer<bool>();

    if (isEditing) {
      dashboardBloc.add(DashboardUpdateCategoryRequested(
        id: widget.category!.id,
        name: name,
        icon: _selectedIcon,
        color: _selectedColor,
        completer: completer,
      ));
    } else {
      dashboardBloc.add(DashboardAddCategoryRequested(
        name: name,
        icon: _selectedIcon,
        color: _selectedColor,
        completer: completer,
      ));
    }

    final success = await completer.future;

    if (mounted) {
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
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    final currentColor = Color(
      int.parse(_selectedColor.replaceFirst('#', '0xFF')),
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
                    icon: _selectedIcon,
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
                controller: _nameController,
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
                  itemCount: presetIcons.length,
                  itemBuilder: (context, index) {
                    final iconName = presetIcons[index];
                    final isIconSelected = _selectedIcon == iconName;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = iconName),
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
                  itemCount: presetColors.length,
                  itemBuilder: (context, index) {
                    final colHex = presetColors[index];
                    final col = Color(
                      int.parse(colHex.replaceFirst('#', '0xFF')),
                    );
                    final isColSelected = _selectedColor == colHex;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = colHex),
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
          onPressed: _handleSave,
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
  }
}
