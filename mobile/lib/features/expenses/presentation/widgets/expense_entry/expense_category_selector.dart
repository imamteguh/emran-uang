import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/expense.dart';
import '../../screens/categories_screen.dart';
import '../category_icon.dart';
import 'expense_category_picker_sheet.dart';

class ExpenseCategorySelector extends StatelessWidget {
  final List<ExpenseCategory> categories;
  final ExpenseCategory? selectedCategory;
  final ValueChanged<ExpenseCategory> onCategorySelected;

  const ExpenseCategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  List<ExpenseCategory> _buildGridCategories() {
    final List<ExpenseCategory> gridCategories = [];
    if (categories.length > 8) {
      final otherCat = categories.firstWhere(
        (c) =>
            c.name.toLowerCase() == 'other' ||
            c.name.toLowerCase() == 'lainnya',
        orElse: () => categories[7],
      );

      final first7 = categories
          .where((c) => c.id != otherCat.id)
          .take(7)
          .toList();

      final isSelectedInFirst7 = selectedCategory != null &&
          first7.any((c) => c.id == selectedCategory!.id);

      gridCategories.addAll(first7);

      if (isSelectedInFirst7 ||
          selectedCategory == null ||
          selectedCategory!.id == otherCat.id) {
        gridCategories.add(otherCat);
      } else {
        gridCategories.add(selectedCategory!);
      }
    } else {
      gridCategories.addAll(categories);
    }
    return gridCategories;
  }

  @override
  Widget build(BuildContext context) {
    final gridCategories = _buildGridCategories();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    size: 14,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'KATEGORI PENGELUARAN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppTheme.darkSlateVariant,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CategoriesScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.tune_rounded, size: 13),
              label: const Text(
                'Kelola',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
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
          itemCount: gridCategories.length,
          itemBuilder: (context, index) {
            final cat = gridCategories[index];
            final isSelected = selectedCategory?.id == cat.id;
            final color = AppTheme.parseHexColor(cat.color);
            final isOther = cat.name.toLowerCase() == 'other' ||
                cat.name.toLowerCase() == 'lainnya';
            final displayName = isOther ? 'Lainnya' : cat.name;

            return GestureDetector(
              onTap: () {
                if (isOther) {
                  ExpenseCategoryPickerSheet.show(
                    context: context,
                    categories: categories,
                    selectedCategory: selectedCategory,
                    onCategorySelected: onCategorySelected,
                  );
                } else {
                  onCategorySelected(cat);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isSelected ? color.withAlpha(25) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? AppTheme.interactiveShadow
                      : AppTheme.softShadow,
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFFF1F5F9),
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
                            displayName,
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
      ],
    );
  }
}
