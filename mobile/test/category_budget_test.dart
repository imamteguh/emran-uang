import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:emran_uang/core/utils/responsive_helper.dart';
import 'package:emran_uang/features/expenses/domain/entities/category_budget.dart';
import 'package:emran_uang/features/expenses/domain/entities/expense.dart';
import 'package:emran_uang/features/expenses/domain/entities/wallet.dart';
import 'package:emran_uang/features/expenses/presentation/bloc/dashboard_state.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/dashboard/category_monthly_budget_card.dart';

void main() {
  group('CategoryBudgetEntity Tests', () {
    test('parses from JSON correctly with numeric and string amounts', () {
      final json1 = {
        'id': 'cb_1',
        'categoryId': 'cat_food',
        'walletId': 'wal_1',
        'amount': 1500000.0,
        'category': {
          'id': 'cat_food',
          'name': 'Makanan & Minuman',
          'icon': 'food',
          'color': '#FF8A00',
        },
      };
      final entity1 = CategoryBudgetEntity.fromJson(json1);
      expect(entity1.id, 'cb_1');
      expect(entity1.categoryId, 'cat_food');
      expect(entity1.amount, 1500000.0);
      expect(entity1.category?.name, 'Makanan & Minuman');

      final json2 = {
        'id': 'cb_2',
        'categoryId': 'cat_transport',
        'walletId': 'wal_1',
        'amount': '750000',
      };
      final entity2 = CategoryBudgetEntity.fromJson(json2);
      expect(entity2.amount, 750000.0);
      expect(entity2.category, isNull);
    });

    test('toJson produces correct map', () {
      const entity = CategoryBudgetEntity(
        id: 'cb_3',
        categoryId: 'cat_shopping',
        walletId: 'wal_1',
        amount: 2000000,
      );
      final json = entity.toJson();
      expect(json['id'], 'cb_3');
      expect(json['categoryId'], 'cat_shopping');
      expect(json['amount'], 2000000.0);
    });
  });

  group('WalletEntity with CategoryBudgets Tests', () {
    test('parses categoryBudgets from wallet JSON', () {
      final walletJson = {
        'id': 'wal_1',
        'name': 'Dompet Utama',
        'type': 'PERSONAL',
        'currency': 'IDR',
        'categoryBudgets': [
          {
            'id': 'cb_1',
            'categoryId': 'cat_1',
            'walletId': 'wal_1',
            'amount': 1000000,
          },
          {
            'id': 'cb_2',
            'categoryId': 'cat_2',
            'walletId': 'wal_1',
            'amount': 500000,
          },
        ],
      };

      final wallet = WalletEntity.fromJson(walletJson);
      expect(wallet.categoryBudgets.length, 2);
      expect(wallet.categoryBudgets[0].amount, 1000000.0);
      expect(wallet.categoryBudgets[1].amount, 500000.0);
    });
  });

  group('DashboardState Category Budget Calculations', () {
    final foodCat = ExpenseCategory(
      id: 'cat_food',
      name: 'Makanan',
      icon: 'food',
      color: '#FF8A00',
    );
    final transportCat = ExpenseCategory(
      id: 'cat_trans',
      name: 'Transportasi',
      icon: 'transport',
      color: '#2463EB',
    );
    final billsCat = ExpenseCategory(
      id: 'cat_bills',
      name: 'Tagihan',
      icon: 'utilities',
      color: '#DC2626',
    );

    final now = DateTime.now();
    final thisMonthExpenses = [
      ExpenseEntity(
        id: 'e1',
        amount: 300000,
        date: DateTime(now.year, now.month, 5),
        type: ExpenseType.nonRoutine,
        userId: 'u1',
        walletId: 'w1',
        category: foodCat,
        creatorName: 'Me',
      ),
      ExpenseEntity(
        id: 'e2',
        amount: 200000,
        date: DateTime(now.year, now.month, 10),
        type: ExpenseType.nonRoutine,
        userId: 'u1',
        walletId: 'w1',
        category: foodCat,
        creatorName: 'Me',
      ),
      ExpenseEntity(
        id: 'e3',
        amount: 850000,
        date: DateTime(now.year, now.month, 12),
        type: ExpenseType.nonRoutine,
        userId: 'u1',
        walletId: 'w1',
        category: transportCat,
        creatorName: 'Me',
      ),
      ExpenseEntity(
        id: 'e4',
        amount: 1200000,
        date: DateTime(now.year, now.month, 15),
        type: ExpenseType.routine,
        userId: 'u1',
        walletId: 'w1',
        category: billsCat,
        creatorName: 'Me',
      ),
      // Previous month expense (should not be counted in this month's budget)
      ExpenseEntity(
        id: 'e5',
        amount: 999999,
        date: DateTime(now.year, now.month - 1, 15),
        type: ExpenseType.nonRoutine,
        userId: 'u1',
        walletId: 'w1',
        category: foodCat,
        creatorName: 'Me',
      ),
    ];

    test('categorySpendInCurrentMonth calculates only current month for category', () {
      final state = DashboardState(
        expenses: thisMonthExpenses,
        categories: [foodCat, transportCat, billsCat],
      );

      expect(state.categorySpendInCurrentMonth('cat_food'), 500000.0);
      expect(state.categorySpendInCurrentMonth('cat_trans'), 850000.0);
      expect(state.categorySpendInCurrentMonth('cat_bills'), 1200000.0);
      expect(state.categorySpendInCurrentMonth('non_existent'), 0.0);
    });

    test('categoryBudgetStatuses evaluates Aman, Mendekati Batas, and Overbudget', () {
      final wallet = WalletEntity(
        id: 'w1',
        name: 'Dompet',
        type: WalletType.personal,
        currency: 'IDR',
        categoryBudgets: const [
          CategoryBudgetEntity(
            id: 'cb1',
            categoryId: 'cat_food',
            walletId: 'w1',
            amount: 1000000, // Spend: 500k -> 50% (Aman)
          ),
          CategoryBudgetEntity(
            id: 'cb2',
            categoryId: 'cat_trans',
            walletId: 'w1',
            amount: 1000000, // Spend: 850k -> 85% (Mendekati Batas)
          ),
          CategoryBudgetEntity(
            id: 'cb3',
            categoryId: 'cat_bills',
            walletId: 'w1',
            amount: 1000000, // Spend: 1.2M -> 120% (Overbudget)
          ),
        ],
      );

      final state = DashboardState(
        selectedWallet: wallet,
        personalWallets: [wallet],
        expenses: thisMonthExpenses,
        categories: [foodCat, transportCat, billsCat],
      );

      final statuses = state.categoryBudgetStatuses;
      expect(statuses.length, 3);

      // 1. Food: 500k / 1M = 50%
      final foodStatus = statuses.firstWhere((s) => s.category.id == 'cat_food');
      expect(foodStatus.monthlySpend, 500000.0);
      expect(foodStatus.budgetLimit, 1000000.0);
      expect(foodStatus.remaining, 500000.0);
      expect(foodStatus.percent, 0.5);
      expect(foodStatus.isOver, false);
      expect(foodStatus.isNear, false);

      // 2. Transport: 850k / 1M = 85%
      final transStatus = statuses.firstWhere((s) => s.category.id == 'cat_trans');
      expect(transStatus.monthlySpend, 850000.0);
      expect(transStatus.remaining, 150000.0);
      expect(transStatus.percent, 0.85);
      expect(transStatus.isOver, false);
      expect(transStatus.isNear, true);

      // 3. Bills: 1.2M / 1M = 120%
      final billsStatus = statuses.firstWhere((s) => s.category.id == 'cat_bills');
      expect(billsStatus.monthlySpend, 1200000.0);
      expect(billsStatus.remaining, -200000.0);
      expect(billsStatus.percent, 1.0); // Clamped to 1.0 for progress bar
      expect(billsStatus.rawPercent, 1.2);
      expect(billsStatus.isOver, true);
      expect(billsStatus.isNear, false);

      // Totals
      expect(state.totalCategoryBudgetLimit, 3000000.0);
      expect(state.totalCategoryBudgetSpend, 2550000.0);
      expect(state.totalCategoryBudgetRemaining, 450000.0);
      expect(state.isOverTotalCategoryBudget, false);
      expect(state.isNearTotalCategoryBudget, true); // 2.55M / 3M = 85%
    });

    test('returns empty statuses when no wallet or no category budgets exist', () {
      const stateWithoutWallet = DashboardState();
      expect(stateWithoutWallet.categoryBudgetStatuses, isEmpty);
      expect(stateWithoutWallet.totalCategoryBudgetLimit, 0.0);
      expect(stateWithoutWallet.totalCategoryBudgetSpend, 0.0);
    });
  });

  group('CategoryMonthlyBudgetCard Widget Tests', () {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    testWidgets('renders empty state when no category budgets are configured',
        (tester) async {
      final wallet = WalletEntity(
        id: 'w1',
        name: 'Dompet Utama',
        type: WalletType.personal,
        currency: 'IDR',
        categoryBudgets: const [],
      );

      final state = DashboardState(
        selectedWallet: wallet,
        personalWallets: [wallet],
        categories: [
          ExpenseCategory(id: 'c1', name: 'Makanan', icon: 'food', color: '#FF8A00'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Builder(
                builder: (context) {
                  return CategoryMonthlyBudgetCard(
                    provider: state,
                    responsive: ResponsiveHelper(context),
                    formatter: formatter,
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Anggaran'), findsOneWidget);
      expect(find.text('Atur Anggaran per Kategori'), findsOneWidget);
      expect(find.text('Atur'), findsWidgets);
    });

    testWidgets('renders list of categories and status badges when budgets are set',
        (tester) async {
      final foodCat = ExpenseCategory(
        id: 'cat_food',
        name: 'Makanan',
        icon: 'food',
        color: '#FF8A00',
      );
      final wallet = WalletEntity(
        id: 'w1',
        name: 'Dompet Utama',
        type: WalletType.personal,
        currency: 'IDR',
        categoryBudgets: const [
          CategoryBudgetEntity(
            id: 'cb1',
            categoryId: 'cat_food',
            walletId: 'w1',
            amount: 2000000,
          ),
        ],
      );

      final now = DateTime.now();
      final state = DashboardState(
        selectedWallet: wallet,
        personalWallets: [wallet],
        categories: [foodCat],
        expenses: [
          ExpenseEntity(
            id: 'e1',
            amount: 500000,
            date: now,
            type: ExpenseType.nonRoutine,
            userId: 'u1',
            walletId: 'w1',
            category: foodCat,
            creatorName: 'Me',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Builder(
                builder: (context) {
                  return CategoryMonthlyBudgetCard(
                    provider: state,
                    responsive: ResponsiveHelper(context),
                    formatter: formatter,
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Anggaran'), findsOneWidget);
      expect(find.text('Makanan'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
    });
  });
}
