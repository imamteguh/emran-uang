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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Hapus Kategori',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: AppTheme.darkSlate,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus kategori "${category.name}"? Transaksi sebelumnya yang menggunakan kategori ini akan tetap tersimpan.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: AppTheme.darkSlateVariant,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Batal',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Hapus',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
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
                  ? 'Kategori "${category.name}" berhasil dihapus'
                  : 'Gagal menghapus kategori',
            ),
            backgroundColor: success ? Colors.green : AppTheme.error,
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.darkSlate),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Kelola Kategori',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.darkSlate,
            fontWeight: FontWeight.w700,
            fontSize: responsive.scaleFont(18),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 26),
            tooltip: 'Tambah Kategori',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF1D4ED8),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kategori kustom memudahkan Anda memilah pengeluaran dan memantau anggaran dengan lebih spesifik.',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: const Color(0xFF1E40AF),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: dashboardState.isLoading && categories.isEmpty
                    ? const CategoryShimmerList()
                    : categories.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryFixed,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.category_outlined,
                                    color: AppTheme.primary,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum Ada Kategori',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tekan tombol (+) di atas untuk menambahkan kategori pengeluaran baru.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 13,
                                    color: AppTheme.darkSlateVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              return CategoryItemTile(
                                category: cat,
                                onEdit: () => CategoryFormDialog.show(
                                  context,
                                  category: cat,
                                ),
                                onDelete: () => _handleDeleteCategory(cat),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CategoryFormDialog.show(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Kategori Baru',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
