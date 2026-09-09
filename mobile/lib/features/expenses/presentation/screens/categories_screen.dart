import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../domain/entities/expense.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../widgets/categories/categories.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<DashboardBloc>()
          .add(const DashboardFetchCategoriesRequested());
    });
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
      final dashboardBloc = context.read<DashboardBloc>();
      final completer = Completer<bool>();
      dashboardBloc
          .add(DashboardDeleteCategoryRequested(category.id, completer));
      final success = await completer.future;
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
    final dashboardState = context.watch<DashboardBloc>().state;
    final categories = dashboardState.categories;

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
            onPressed: () => CategoryFormDialog.show(context),
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
                    ? const CategoryShimmerList()
                    : ListView.builder(
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          return CategoryItemTile(
                            category: cat,
                            onEdit: () =>
                                CategoryFormDialog.show(context, category: cat),
                            onDelete: () => _handleDeleteCategory(cat),
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
