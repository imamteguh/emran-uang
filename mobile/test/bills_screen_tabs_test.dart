import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:emran_uang/core/utils/responsive_helper.dart';
import 'package:emran_uang/features/expenses/domain/entities/wallet.dart';
import 'package:emran_uang/features/expenses/domain/entities/expense.dart';
import 'package:emran_uang/features/expenses/domain/entities/category_budget.dart';
import 'package:emran_uang/features/expenses/presentation/bloc/dashboard_state.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/bills/bills_summary_data.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/bills/budget_management_view.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/bills/budget_form_sheets.dart';

void main() {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('Bills and Budget Tabs & Widgets Tests', () {
    testWidgets('BudgetManagementView renders monthly budget and category empty state',
        (tester) async {
      final wallet = WalletEntity(
        id: 'w1',
        name: 'Dompet Utama',
        type: WalletType.personal,
        currency: 'IDR',
        monthlyBudget: 5000000.0,
        dailyBudget: 150000.0,
        categoryBudgets: const [],
      );

      final state = DashboardState(
        selectedWallet: wallet,
        expenses: const [],
        categories: [
          ExpenseCategory(
            id: 'c1',
            name: 'Makanan',
            icon: 'fastfood',
            color: '#FF5722',
          ),
        ],
      );

      final summary = BillsSummaryData.fromReminders(const []);

      await tester.pumpWidget(
        wrapWithMaterial(
          SingleChildScrollView(
            child: Builder(
              builder: (context) => BudgetManagementView(
                provider: state,
                summary: summary,
                currencyFormatter: currencyFormatter,
                responsive: ResponsiveHelper(context),
              ),
            ),
          ),
        ),
      );

      // Verify Monthly Budget Card is removed
      expect(find.text('Anggaran Bulanan Dompet'), findsNothing);

      // Verify Category Budget Section
      expect(find.text('Anggaran per Kategori'), findsOneWidget);
      expect(find.text('Belum Ada Anggaran Kategori'), findsOneWidget);
      expect(find.text('Tambah Anggaran Kategori'), findsOneWidget);
    });

    testWidgets('BudgetManagementView renders active category budgets list with progress',
        (tester) async {
      final cat = ExpenseCategory(
        id: 'c1',
        name: 'Makanan & Minuman',
        icon: 'restaurant',
        color: '#10B981',
      );

      final categoryBudget = CategoryBudgetEntity(
        id: 'cb1',
        categoryId: 'c1',
        walletId: 'w1',
        amount: 1500000.0,
        category: cat,
      );

      final wallet = WalletEntity(
        id: 'w1',
        name: 'Dompet Utama',
        type: WalletType.personal,
        currency: 'IDR',
        monthlyBudget: 5000000.0,
        dailyBudget: 150000.0,
        categoryBudgets: [categoryBudget],
      );

      final expense = ExpenseEntity(
        id: 'e1',
        amount: 300000.0,
        date: DateTime.now(),
        type: ExpenseType.routine,
        userId: 'u1',
        walletId: 'w1',
        category: cat,
        creatorName: 'User',
      );

      final state = DashboardState(
        selectedWallet: wallet,
        categories: [cat],
        expenses: [expense],
      );

      final summary = BillsSummaryData.fromReminders(const []);

      await tester.pumpWidget(
        wrapWithMaterial(
          SingleChildScrollView(
            child: Builder(
              builder: (context) => BudgetManagementView(
                provider: state,
                summary: summary,
                currencyFormatter: currencyFormatter,
                responsive: ResponsiveHelper(context),
              ),
            ),
          ),
        ),
      );

      // Category budget item should be present
      expect(find.text('Makanan & Minuman'), findsOneWidget);
      expect(find.text('Batas: Rp1.500.000'), findsOneWidget);
    });

    testWidgets('BudgetFormSheets shows bottom sheets for setting monthly & category budgets',
        (tester) async {
      final cat = ExpenseCategory(
        id: 'c1',
        name: 'Transportasi',
        icon: 'commute',
        color: '#3B82F6',
      );

      final wallet = WalletEntity(
        id: 'w1',
        name: 'Dompet Utama',
        type: WalletType.personal,
        currency: 'IDR',
        monthlyBudget: 5000000.0,
        dailyBudget: null,
      );

      final state = DashboardState(
        selectedWallet: wallet,
        categories: [cat],
      );

      // Test showConfirmDeleteCategoryBudgetSheet modal bottom sheet
      await tester.pumpWidget(
        wrapWithMaterial(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                BudgetFormSheets.showConfirmDeleteCategoryBudgetSheet(
                  context: context,
                  category: state.categories.first,
                  provider: state,
                );
              },
              child: const Text('Open Delete Sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Delete Sheet'));
      await tester.pumpAndSettle();

      // Verify bottom sheet content
      expect(find.text('Hapus Anggaran Kategori'), findsOneWidget);
      expect(
        find.text(
          'Apakah Anda yakin ingin menghapus batasan anggaran untuk kategori "Transportasi"?',
        ),
        findsOneWidget,
      );
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);

      // Dismiss bottom sheet
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus Anggaran Kategori'), findsNothing);
    });
  });
}
