import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/expense.dart';
import '../category_icon.dart';

class CategoryItemTile extends StatelessWidget {
  final ExpenseCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryItemTile({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isSystem = category.isDefault;
    final color = Color(
      int.parse(category.color.replaceFirst('#', '0xFF')),
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: CategoryIcon(
              icon: category.icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
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
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isSystem ? 'System Default' : 'Custom',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isSystem ? Colors.grey[700] : AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isSystem) ...[
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}
