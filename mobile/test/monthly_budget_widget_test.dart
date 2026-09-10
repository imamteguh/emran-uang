import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:emran_uang/core/utils/responsive_helper.dart';
import 'package:emran_uang/features/expenses/domain/entities/wallet.dart';
import 'package:emran_uang/features/expenses/domain/entities/expense.dart';
import 'package:emran_uang/features/expenses/presentation/bloc/dashboard_state.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/dashboard/monthly_budget_card.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/dashboard/set_monthly_budget_dialog.dart';

void main() {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  group('MonthlyBudgetCard Widget Tests', () {
    testWidgets('displays empty state when no monthly budget is set',
        (tester) async {
      final wallet = WalletEntity(
        id: 'w1',
        name: 'Dompet Utama',
        type: WalletType.personal,
        currency: 'IDR',
        monthlyBudget: null,
        dailyBudget: null,
      );

      final state = DashboardState(
        selectedWallet: wallet,
        expenses: const [],
      );

      await tester.pumpWidget(
        wrapWithMaterial(
          Builder(
            builder: (context) => MonthlyBudgetCard(
              provider: state,
              responsive: ResponsiveHelper(context),
              formatter: currencyFormatter,
            ),
          ),
        ),
      );

      expect(find.text('ANGGARAN BULANAN'), findsOneWidget);
      expect(find.text('Atur Anggaran Bulanan'), findsOneWidget);
      expect(find.text('Atur'), findsOneWidget);
    });

    testWidgets('displays budget stats when monthly budget is configured',
        (tester) async {
      final wallet = WalletEntity(
        id: 'w1',
        name: 'Dompet Utama',
        type: WalletType.personal,
        currency: 'IDR',
        monthlyBudget: 5000000,
      );

      final now = DateTime.now();
      final expense = ExpenseEntity(
        id: 'e1',
        amount: 1500000,
        description: 'Belanja Bulanan',
        date: DateTime(now.year, now.month, 5),
        type: ExpenseType.nonRoutine,
        userId: 'u1',
        walletId: 'w1',
        category: ExpenseCategory(
          id: 'c1',
          name: 'Belanja',
          icon: 'shopping_bag',
          color: '#4CAF50',
          isDefault: true,
        ),
        creatorName: 'Emran',
      );

      final state = DashboardState(
        selectedWallet: wallet,
        expenses: [expense],
      );

      await tester.pumpWidget(
        wrapWithMaterial(
          Builder(
            builder: (context) => MonthlyBudgetCard(
              provider: state,
              responsive: ResponsiveHelper(context),
              formatter: currencyFormatter,
            ),
          ),
        ),
      );

      expect(find.text('ANGGARAN BULANAN'), findsOneWidget);
      expect(find.text('Aman'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
      expect(find.text('Sisa Anggaran'), findsOneWidget);
      expect(find.text('Sisa Waktu'), findsOneWidget);
      expect(find.text('Batas Harian'), findsOneWidget);
    });

    testWidgets('SetMonthlyBudgetDialog preset chip updates text field',
        (tester) async {
      final wallet = WalletEntity(
        id: 'w1',
        name: 'Dompet Utama',
        type: WalletType.personal,
        currency: 'IDR',
        monthlyBudget: 2000000,
      );

      final state = DashboardState(
        selectedWallet: wallet,
        expenses: const [],
      );

      await tester.pumpWidget(
        wrapWithMaterial(
          SetMonthlyBudgetDialog(provider: state),
        ),
      );

      expect(find.text('Anggaran Bulanan'), findsOneWidget);
      expect(find.text('1 Jt'), findsOneWidget);
      expect(find.text('5 Jt'), findsOneWidget);
      expect(find.text('Simpan Anggaran'), findsOneWidget);

      // Tap preset chip "5 Jt"
      await tester.tap(find.text('5 Jt'));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, '5000000');
    });
  });
}
