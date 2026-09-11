import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:emran_uang/core/utils/responsive_helper.dart';
import 'package:emran_uang/features/expenses/domain/entities/expense.dart';
import 'package:emran_uang/features/expenses/presentation/bloc/dashboard_state.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/dashboard/routine_spending_card.dart';

void main() {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  Widget buildTestWidget(DashboardState state) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            final responsive = ResponsiveHelper(context);
            return RoutineSpendingCard(
              provider: state,
              responsive: responsive,
              formatter: currencyFormatter,
            );
          },
        ),
      ),
    );
  }

  group('DashboardState Routine Getters Tests', () {
    test('calculates monthly routine and non-routine spend correctly', () {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 15);

      final cat = ExpenseCategory(
        id: 'cat_1',
        name: 'Umum',
        icon: 'category',
        color: '#4F46E5',
      );

      final expenses = [
        ExpenseEntity(
          id: 'e1',
          amount: 500000,
          date: now,
          type: ExpenseType.routine,
          userId: 'u1',
          walletId: 'w1',
          category: cat,
          creatorName: 'User',
        ),
        ExpenseEntity(
          id: 'e2',
          amount: 250000,
          date: now,
          type: ExpenseType.routine,
          userId: 'u1',
          walletId: 'w1',
          category: cat,
          creatorName: 'User',
        ),
        ExpenseEntity(
          id: 'e3',
          amount: 250000,
          date: now,
          type: ExpenseType.nonRoutine,
          userId: 'u1',
          walletId: 'w1',
          category: cat,
          creatorName: 'User',
        ),
        // Previous month expense should NOT be included in monthly getters
        ExpenseEntity(
          id: 'e4',
          amount: 1000000,
          date: lastMonth,
          type: ExpenseType.routine,
          userId: 'u1',
          walletId: 'w1',
          category: cat,
          creatorName: 'User',
        ),
      ];

      final state = DashboardState(expenses: expenses);

      expect(state.monthlyRoutineSpend, 750000);
      expect(state.monthlyNonRoutineSpend, 250000);
      expect(state.monthlyRoutineCount, 2);
      expect(state.monthlyNonRoutineCount, 1);
      expect(state.monthlyRoutinePercent, 0.75);
      expect(state.monthlyNonRoutinePercent, 0.25);
    });

    test('falls back to compareData when expenses list has no entries for current month', () {
      const compareData = {
        'months': [
          {
            'month': '2026-09',
            'total': 1000000,
            'byType': [
              {'type': 'ROUTINE', 'total': 600000, 'count': 3},
              {'type': 'NON_ROUTINE', 'total': 400000, 'count': 5},
            ],
          },
        ],
      };

      final state = DashboardState(
        expenses: const [],
        compareData: compareData,
      );

      expect(state.monthlyRoutineSpend, 600000);
      expect(state.monthlyNonRoutineSpend, 400000);
      expect(state.monthlyRoutinePercent, 0.6);
      expect(state.monthlyNonRoutinePercent, 0.4);
    });
  });

  group('RoutineSpendingCard Widget Tests', () {
    testWidgets('renders empty state when monthly spend is zero', (tester) async {
      const state = DashboardState(expenses: []);

      await tester.pumpWidget(buildTestWidget(state));
      await tester.pumpAndSettle();

      expect(find.text('Pengeluaran Rutin & Non-Rutin'), findsOneWidget);
      expect(find.text('Belum Ada Pengeluaran Bulan Ini'), findsOneWidget);
      expect(find.byIcon(Icons.donut_large_rounded), findsOneWidget);
    });

    testWidgets('renders routine and non-routine metrics with insight when data is present',
        (tester) async {
      final now = DateTime.now();
      final cat = ExpenseCategory(
        id: 'cat_1',
        name: 'Umum',
        icon: 'category',
        color: '#4F46E5',
      );

      final expenses = [
        ExpenseEntity(
          id: 'e1',
          amount: 800000,
          date: now,
          type: ExpenseType.routine,
          userId: 'u1',
          walletId: 'w1',
          category: cat,
          creatorName: 'User',
        ),
        ExpenseEntity(
          id: 'e2',
          amount: 200000,
          date: now,
          type: ExpenseType.nonRoutine,
          userId: 'u1',
          walletId: 'w1',
          category: cat,
          creatorName: 'User',
        ),
      ];

      final state = DashboardState(expenses: expenses);

      await tester.pumpWidget(buildTestWidget(state));
      await tester.pumpAndSettle();

      expect(find.text('Pengeluaran Rutin & Non-Rutin'), findsOneWidget);
      expect(find.text('Bulan Ini'), findsOneWidget);
      expect(find.text('RUTIN'), findsOneWidget);
      expect(find.text('NON-RUTIN'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);
      expect(find.text('1 transaksi'), findsNWidgets(2));
      expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
    });
  });
}
