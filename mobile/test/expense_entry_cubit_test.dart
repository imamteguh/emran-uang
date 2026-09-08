import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emran_uang/features/expenses/domain/entities/expense.dart';
import 'package:emran_uang/features/expenses/domain/entities/wallet.dart';
import 'package:emran_uang/features/expenses/domain/entities/ocr_scan_result.dart';
import 'package:emran_uang/features/expenses/presentation/bloc/expense_entry/expense_entry_cubit.dart';
import 'package:emran_uang/features/expenses/presentation/bloc/expense_entry/expense_entry_state.dart';

void main() {
  group('ExpenseEntryCubit & Parser Tests', () {
    final dummyCategory = ExpenseCategory(
      id: 'cat_food',
      name: 'Food & Dining',
      icon: 'restaurant',
      color: '#FF5722',
      isDefault: true,
    );

    final dummyCategory2 = ExpenseCategory(
      id: 'cat_transport',
      name: 'Transport',
      icon: 'directions_car',
      color: '#2196F3',
      isDefault: true,
    );

    final dummyWallet = WalletEntity(
      id: 'wallet_1',
      name: 'Main Wallet',
      currency: 'IDR',
      type: WalletType.personal,
    );

    test('Initial state is properly configured', () {
      final now = DateTime(2026, 9, 8, 14, 30);
      final cubit = ExpenseEntryCubit(
        initialDate: now,
        initialCategory: dummyCategory,
        initialWallet: dummyWallet,
      );

      expect(cubit.state.status, ExpenseEntryStatus.initial);
      expect(cubit.state.selectedCategory, dummyCategory);
      expect(cubit.state.activeWallet, dummyWallet);
      expect(cubit.state.selectedDate, now);
      expect(cubit.state.isRoutine, false);

      cubit.close();
    });

    test('parseRawAmount parses zero-decimal currencies (IDR, JPY) correctly', () {
      // Indonesian Rupiah: thousand separators (dots, spaces)
      expect(ExpenseEntryCubit.parseRawAmount('50.000', 'IDR'), 50000.0);
      expect(ExpenseEntryCubit.parseRawAmount('1.250.000', 'IDR'), 1250000.0);
      expect(ExpenseEntryCubit.parseRawAmount('75 000', 'IDR'), 75000.0);
      expect(ExpenseEntryCubit.parseRawAmount('0', 'IDR'), null);
      expect(ExpenseEntryCubit.parseRawAmount('', 'IDR'), null);
    });

    test('parseRawAmount parses decimal currencies (USD, EUR) correctly', () {
      expect(ExpenseEntryCubit.parseRawAmount('45.99', 'USD'), 45.99);
      expect(ExpenseEntryCubit.parseRawAmount('1,250.50', 'USD'), 1250.50);
      expect(ExpenseEntryCubit.parseRawAmount('0.00', 'USD'), null);
    });

    test('formatAmountForInput formats amounts cleanly without currency symbol', () {
      final idrFormatted = ExpenseEntryCubit.formatAmountForInput(50000.0, 'IDR');
      expect(idrFormatted, contains('50'));
      expect(idrFormatted.contains('Rp'), false);
    });

    test('updateCategory and updateRoutine update state', () {
      final cubit = ExpenseEntryCubit();
      expect(cubit.state.selectedCategory, isNull);
      expect(cubit.state.isRoutine, false);

      cubit.updateCategory(dummyCategory2);
      expect(cubit.state.selectedCategory, dummyCategory2);

      cubit.updateRoutine(true);
      expect(cubit.state.isRoutine, true);

      cubit.close();
    });

    test('updateDate preserves time, updateTime preserves date', () {
      final cubit = ExpenseEntryCubit(
        initialDate: DateTime(2026, 9, 8, 10, 15),
      );

      cubit.updateDate(DateTime(2026, 9, 1));
      expect(cubit.state.selectedDate.year, 2026);
      expect(cubit.state.selectedDate.month, 9);
      expect(cubit.state.selectedDate.day, 1);
      expect(cubit.state.selectedDate.hour, 10);
      expect(cubit.state.selectedDate.minute, 15);

      cubit.updateTime(const TimeOfDay(hour: 18, minute: 45));
      expect(cubit.state.selectedDate.day, 1);
      expect(cubit.state.selectedDate.hour, 18);
      expect(cubit.state.selectedDate.minute, 45);

      cubit.close();
    });

    test('applyOcrResult correctly parses receipt payload and matches category', () {
      final cubit = ExpenseEntryCubit(initialWallet: dummyWallet);
      final ocrDate = DateTime(2026, 9, 5, 12, 0);

      cubit.applyOcrResult(
        OcrScanResult(
          amount: 85000.0,
          description: 'Lunch at Cafe',
          date: ocrDate,
          category: ExpenseCategory(
            id: 'temp_cat',
            name: 'Food & Dining',
            icon: 'fastfood',
            color: '#FF0000',
          ),
          wallet: dummyWallet,
        ),
        [dummyCategory, dummyCategory2],
      );

      expect(cubit.state.formattedAmount, contains('85'));
      expect(cubit.state.initialDescription, 'Lunch at Cafe');
      expect(cubit.state.selectedDate, ocrDate);
      expect(cubit.state.selectedCategory?.id, dummyCategory.id);

      cubit.close();
    });

    test('switchWallet updates activeWallet', () {
      final cubit = ExpenseEntryCubit(initialWallet: dummyWallet);
      final newWallet = WalletEntity(
        id: 'wallet_2',
        name: 'Shared Family',
        currency: 'IDR',
        type: WalletType.shared,
      );

      cubit.switchWallet(newWallet);
      expect(cubit.state.activeWallet, newWallet);

      cubit.close();
    });
  });
}
