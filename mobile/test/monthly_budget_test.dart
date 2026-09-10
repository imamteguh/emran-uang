import 'package:flutter_test/flutter_test.dart';
import 'package:emran_uang/features/expenses/domain/entities/wallet.dart';
import 'package:emran_uang/features/expenses/domain/entities/expense.dart';
import 'package:emran_uang/features/expenses/presentation/bloc/dashboard_state.dart';

void main() {
  group('WalletEntity Monthly Budget Tests', () {
    test('parses monthlyBudget from num and String json', () {
      final wallet1 = WalletEntity.fromJson({
        'id': 'w1',
        'name': 'Dompet Pribadi',
        'type': 'PERSONAL',
        'currency': 'IDR',
        'dailyBudget': 100000,
        'monthlyBudget': 3000000,
      });

      expect(wallet1.dailyBudget, 100000.0);
      expect(wallet1.monthlyBudget, 3000000.0);

      final wallet2 = WalletEntity.fromJson({
        'id': 'w2',
        'name': 'Dompet Tabungan',
        'type': 'PERSONAL',
        'currency': 'IDR',
        'dailyBudget': '50000.00',
        'monthlyBudget': '1500000.50',
      });

      expect(wallet2.dailyBudget, 50000.0);
      expect(wallet2.monthlyBudget, 1500000.50);

      final wallet3 = WalletEntity.fromJson({
        'id': 'w3',
        'name': 'Dompet Null',
        'type': 'PERSONAL',
        'currency': 'IDR',
        'dailyBudget': null,
        'monthlyBudget': null,
      });

      expect(wallet3.dailyBudget, isNull);
      expect(wallet3.monthlyBudget, isNull);
    });
  });

  group('DashboardState Monthly Budget Computations', () {
    final now = DateTime.now();
    final daysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
    final dummyCategory = ExpenseCategory(
      id: 'cat-1',
      name: 'Makanan',
      icon: 'restaurant',
      color: '#FF5722',
      isDefault: true,
    );

    test('returns direct monthlyBudget when available', () {
      final wallet = WalletEntity(
        id: 'w-test',
        name: 'Test Wallet',
        type: WalletType.personal,
        currency: 'IDR',
        dailyBudget: 50000,
        monthlyBudget: 2500000,
      );

      final state = DashboardState(
        selectedWallet: wallet,
        expenses: const [],
      );

      expect(state.monthlyBudgetLimit, 2500000.0);
    });

    test('falls back to dailyBudget * daysInMonth when monthlyBudget is null', () {
      final wallet = WalletEntity(
        id: 'w-test',
        name: 'Test Wallet',
        type: WalletType.personal,
        currency: 'IDR',
        dailyBudget: 100000,
        monthlyBudget: null,
      );

      final state = DashboardState(
        selectedWallet: wallet,
        expenses: const [],
      );

      expect(state.monthlyBudgetLimit, 100000.0 * daysInCurrentMonth);
    });

    test('returns 0 when neither budget is set', () {
      final wallet = WalletEntity(
        id: 'w-test',
        name: 'Test Wallet',
        type: WalletType.personal,
        currency: 'IDR',
        dailyBudget: null,
        monthlyBudget: null,
      );

      final state = DashboardState(
        selectedWallet: wallet,
        expenses: const [],
      );

      expect(state.monthlyBudgetLimit, 0.0);
      expect(state.monthlyBudgetPercent, 0.0);
      expect(state.monthlyBudgetRemaining, 0.0);
      expect(state.dailyRecommendedSpending, 0.0);
      expect(state.isOverMonthlyBudget, isFalse);
      expect(state.isNearMonthlyBudget, isFalse);
    });

    test('computes budget percent, remaining, and status accurately', () {
      final wallet = WalletEntity(
        id: 'w-test',
        name: 'Test Wallet',
        type: WalletType.personal,
        currency: 'IDR',
        monthlyBudget: 2000000,
      );

      // 1. Safe state: spent 1,000,000 / 2,000,000 (50%)
      final expense1 = ExpenseEntity(
        id: 'exp-1',
        amount: 1000000,
        description: 'Belanja',
        date: DateTime(now.year, now.month, 1),
        type: ExpenseType.nonRoutine,
        userId: 'user-1',
        walletId: 'w-test',
        category: dummyCategory,
        creatorName: 'Emran',
      );

      final stateSafe = DashboardState(
        selectedWallet: wallet,
        expenses: [expense1],
      );

      expect(stateSafe.monthlySpend, 1000000.0);
      expect(stateSafe.monthlyBudgetLimit, 2000000.0);
      expect(stateSafe.monthlyBudgetRemaining, 1000000.0);
      expect(stateSafe.monthlyBudgetPercent, 0.5);
      expect(stateSafe.rawMonthlyBudgetPercent, 0.5);
      expect(stateSafe.isOverMonthlyBudget, isFalse);
      expect(stateSafe.isNearMonthlyBudget, isFalse);

      // 2. Near limit state: spent 1,700,000 / 2,000,000 (85%)
      final expense2 = ExpenseEntity(
        id: 'exp-2',
        amount: 700000,
        description: 'Makan',
        date: DateTime(now.year, now.month, 2),
        type: ExpenseType.nonRoutine,
        userId: 'user-1',
        walletId: 'w-test',
        category: dummyCategory,
        creatorName: 'Emran',
      );

      final stateNear = DashboardState(
        selectedWallet: wallet,
        expenses: [expense1, expense2],
      );

      expect(stateNear.monthlySpend, 1700000.0);
      expect(stateNear.monthlyBudgetPercent, 0.85);
      expect(stateNear.isNearMonthlyBudget, isTrue);
      expect(stateNear.isOverMonthlyBudget, isFalse);

      // 3. Over budget state: spent 2,400,000 / 2,000,000 (120%)
      final expense3 = ExpenseEntity(
        id: 'exp-3',
        amount: 700000,
        description: 'Elektronik',
        date: DateTime(now.year, now.month, 3),
        type: ExpenseType.nonRoutine,
        userId: 'user-1',
        walletId: 'w-test',
        category: dummyCategory,
        creatorName: 'Emran',
      );

      final stateOver = DashboardState(
        selectedWallet: wallet,
        expenses: [expense1, expense2, expense3],
      );

      expect(stateOver.monthlySpend, 2400000.0);
      expect(stateOver.monthlyBudgetPercent, 1.0); // clamped
      expect(stateOver.rawMonthlyBudgetPercent, 1.2);
      expect(stateOver.monthlyBudgetRemaining, -400000.0);
      expect(stateOver.isOverMonthlyBudget, isTrue);
      expect(stateOver.isNearMonthlyBudget, isFalse);
      expect(stateOver.dailyRecommendedSpending, 0.0);
    });

    test('dailyRecommendedSpending divides remaining budget by days left', () {
      final wallet = WalletEntity(
        id: 'w-test',
        name: 'Test Wallet',
        type: WalletType.personal,
        currency: 'IDR',
        monthlyBudget: 3000000,
      );

      final state = DashboardState(
        selectedWallet: wallet,
        expenses: const [],
      );

      final remainingDays = state.daysRemainingInMonth;
      expect(remainingDays, inInclusiveRange(1, daysInCurrentMonth));
      expect(
        state.dailyRecommendedSpending,
        closeTo(3000000.0 / remainingDays, 0.01),
      );
    });
  });
}
