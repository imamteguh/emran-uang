import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/utils/currency_helper.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/ocr_scan_result.dart';
import '../../../domain/entities/wallet.dart';
import '../dashboard_bloc.dart';
import '../dashboard_event.dart';
import 'expense_entry_state.dart';

class ExpenseEntryCubit extends Cubit<ExpenseEntryState> {
  ExpenseEntryCubit({
    DateTime? initialDate,
    ExpenseCategory? initialCategory,
    WalletEntity? initialWallet,
  }) : super(ExpenseEntryState(
          selectedDate: initialDate ?? DateTime.now(),
          selectedCategory: initialCategory,
          activeWallet: initialWallet,
        ));

  /// Initialize target wallet if not already set
  void initWallet(WalletEntity? wallet) {
    if (state.activeWallet == null && wallet != null) {
      emit(state.copyWith(activeWallet: wallet));
    }
  }

  /// Switch target wallet
  void switchWallet(WalletEntity wallet) {
    emit(state.copyWith(activeWallet: wallet));
  }

  /// Update selected category
  void updateCategory(ExpenseCategory category) {
    emit(state.copyWith(selectedCategory: category, clearError: true));
  }

  /// Sync default category from list if none selected
  void syncCategories(List<ExpenseCategory> categories) {
    if (categories.isEmpty) return;

    if (state.selectedCategory == null) {
      emit(state.copyWith(selectedCategory: categories.first));
    } else {
      final matched = categories.firstWhere(
        (c) => c.id == state.selectedCategory!.id,
        orElse: () => state.selectedCategory!,
      );
      emit(state.copyWith(selectedCategory: matched));
    }
  }

  /// Update date while preserving time
  void updateDate(DateTime date) {
    final updated = DateTime(
      date.year,
      date.month,
      date.day,
      state.selectedDate.hour,
      state.selectedDate.minute,
    );
    emit(state.copyWith(selectedDate: updated));
  }

  /// Update time while combining with base date
  void updateTime(TimeOfDay time, {DateTime? targetDate}) {
    final base = targetDate ?? state.selectedDate;
    final updated = DateTime(
      base.year,
      base.month,
      base.day,
      time.hour,
      time.minute,
    );
    emit(state.copyWith(selectedDate: updated));
  }

  /// Toggle routine expense
  void updateRoutine(bool isRoutine) {
    emit(state.copyWith(isRoutine: isRoutine));
  }

  /// Applies OCR scan result to the form state
  void applyOcrResult(
    OcrScanResult result,
    List<ExpenseCategory> availableCategories, {
    WalletEntity? currentActiveWallet,
  }) {
    final effectiveWallet = result.wallet ?? currentActiveWallet ?? state.activeWallet;
    final currencyCode = effectiveWallet?.currency ?? 'IDR';
    final formattedAmount = formatAmountForInput(result.amount, currencyCode);

    ExpenseCategory? matchedCategory;
    if (result.category != null && availableCategories.isNotEmpty) {
      matchedCategory = availableCategories.firstWhere(
        (c) => c.id == result.category!.id,
        orElse: () => availableCategories.firstWhere(
          (c) => c.name.toLowerCase() == result.category!.name.toLowerCase(),
          orElse: () => result.category!,
        ),
      );
    } else {
      matchedCategory = result.category;
    }

    emit(state.copyWith(
      activeWallet: effectiveWallet,
      formattedAmount: formattedAmount,
      initialDescription: result.description?.trim(),
      selectedDate: result.date ?? state.selectedDate,
      selectedCategory: matchedCategory ?? state.selectedCategory,
    ));
  }

  /// Parses raw user amount string according to wallet currency decimals
  static double? parseRawAmount(String amountText, String currencyCode) {
    final trimmed = amountText.trim();
    if (trimmed.isEmpty) return null;

    final decimalDigits = CurrencyHelper.getFormatter(currencyCode).decimalDigits ?? 0;
    String processed = trimmed;
    if (decimalDigits == 0) {
      // IDR/JPY: remove all formatting/thousand separators
      processed = processed.replaceAll(RegExp(r'[.,\s]'), '');
    } else {
      // USD/EUR: standard decimals
      if (processed.contains(',') && processed.contains('.')) {
        processed = processed.replaceAll(',', '');
      } else if (processed.contains(',')) {
        processed = processed.replaceAll(',', '.');
      }
    }

    final parsed = double.tryParse(processed);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  /// Formats amount for display inside input field
  static String formatAmountForInput(double amount, String currencyCode) {
    final formatter = CurrencyHelper.getFormatter(currencyCode);
    final formatted = formatter.format(amount);
    final symbol = formatter.currencySymbol;
    return formatted
        .replaceFirst(symbol.trim(), '')
        .replaceFirst(symbol, '')
        .trim();
  }

  /// Submits expense to DashboardBloc and returns true on success
  Future<bool> submitExpense({
    required DashboardBloc dashboardBloc,
    required String amountText,
    required String? descriptionText,
  }) async {
    if (state.isSubmitting) return false;

    final wallet = state.activeWallet ?? dashboardBloc.state.activeWallet;
    final currencyCode = wallet?.currency ?? 'IDR';
    final amount = parseRawAmount(amountText, currencyCode);

    if (amount == null) {
      emit(state.copyWith(
        status: ExpenseEntryStatus.failure,
        errorMessage: 'Please enter a valid positive amount',
      ));
      return false;
    }

    if (state.selectedCategory == null) {
      emit(state.copyWith(
        status: ExpenseEntryStatus.failure,
        errorMessage: 'Please select a category',
      ));
      return false;
    }

    emit(state.copyWith(
      status: ExpenseEntryStatus.submitting,
      clearError: true,
    ));

    try {
      final newExpense = ExpenseEntity(
        id: 'new_exp_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        description: descriptionText?.trim().isEmpty == true
            ? null
            : descriptionText?.trim(),
        date: state.selectedDate,
        type: state.isRoutine ? ExpenseType.routine : ExpenseType.nonRoutine,
        userId: 'user1',
        walletId: wallet?.id ?? 'personal_w1',
        category: state.selectedCategory!,
        creatorName: 'User',
      );

      final completer = Completer<bool>();
      dashboardBloc.add(DashboardAddExpenseRequested(newExpense, completer));
      final success = await completer.future;

      if (success) {
        emit(state.copyWith(
          status: ExpenseEntryStatus.success,
          clearError: true,
        ));
        return true;
      } else {
        emit(state.copyWith(
          status: ExpenseEntryStatus.failure,
          errorMessage: 'Failed to save transaction. Please try again.',
        ));
        return false;
      }
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseEntryStatus.failure,
        errorMessage: 'An error occurred: $e',
      ));
      return false;
    }
  }
}
