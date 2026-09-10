import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/bill_reminder.dart';
import '../../domain/entities/category_budget.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DioClient _client = DioClient();

  DashboardBloc() : super(const DashboardState()) {
    on<DashboardInitializeRequested>(_onInitializeRequested);
    on<DashboardSelectWalletRequested>(_onSelectWalletRequested);
    on<DashboardSetTimeframeRequested>(_onSetTimeframeRequested);
    on<DashboardToggleSharedModeRequested>(_onToggleSharedModeRequested);
    on<DashboardRefreshRequested>(_onRefreshRequested);
    on<DashboardFetchAnalyticsRequested>(_onFetchAnalyticsRequested);
    on<DashboardFetchRemindersRequested>(_onFetchRemindersRequested);
    on<DashboardFetchCategoriesRequested>(_onFetchCategoriesRequested);
    on<DashboardAddCategoryRequested>(_onAddCategoryRequested);
    on<DashboardUpdateCategoryRequested>(_onUpdateCategoryRequested);
    on<DashboardDeleteCategoryRequested>(_onDeleteCategoryRequested);
    on<DashboardAddExpenseRequested>(_onAddExpenseRequested);
    on<DashboardDeleteExpenseRequested>(_onDeleteExpenseRequested);
    on<DashboardUpdateDailyBudgetRequested>(_onUpdateDailyBudgetRequested);
    on<DashboardUpdateMonthlyBudgetRequested>(_onUpdateMonthlyBudgetRequested);
    on<DashboardSetCategoryBudgetRequested>(_onSetCategoryBudgetRequested);
    on<DashboardDeleteCategoryBudgetRequested>(_onDeleteCategoryBudgetRequested);
    on<DashboardUpdateWalletCurrencyRequested>(
      _onUpdateWalletCurrencyRequested,
    );
    on<DashboardFetchSharedGroupsRequested>(_onFetchSharedGroupsRequested);
    on<DashboardSendInviteRequested>(_onSendInviteRequested);
    on<DashboardAcceptInviteRequested>(_onAcceptInviteRequested);
    on<DashboardRejectInviteRequested>(_onRejectInviteRequested);
    on<DashboardLeaveGroupRequested>(_onLeaveGroupRequested);
    on<DashboardDeleteGroupRequested>(_onDeleteGroupRequested);
    on<DashboardAddReminderRequested>(_onAddReminderRequested);
    on<DashboardUpdateReminderRequested>(_onUpdateReminderRequested);
    on<DashboardDeleteReminderRequested>(_onDeleteReminderRequested);
    on<DashboardPayBillRequested>(_onPayBillRequested);
    on<_DashboardBackgroundDataLoaded>(_onBackgroundDataLoaded);
    on<_DashboardSecondaryDataLoaded>(_onSecondaryDataLoaded);
  }

  Future<void> _onInitializeRequested(
    DashboardInitializeRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        isInitialLoad: true,
        status: DashboardStatus.loading,
      ),
    );

    try {
      final walletsResult = await _fetchWalletsHelper(state.selectedWallet);
      var selectedWallet = walletsResult.selected;

      if (selectedWallet != null) {
        // Load primary critical data in parallel: Expenses & Reminders
        final results = await Future.wait([
          _fetchExpensesDataHelper(selectedWallet.id),
          _fetchRemindersDataHelper(selectedWallet.id),
        ]);

        emit(
          state.copyWith(
            personalWallets: walletsResult.personal,
            sharedWallets: walletsResult.shared,
            selectedWallet: selectedWallet,
            expenses: results[0] as List<ExpenseEntity>,
            reminders: results[1] as List<BillReminderEntity>,
            isLoading: false,
            isInitialLoad: false,
            isLoadingAnalytics: true,
            status: DashboardStatus.success,
          ),
        );

        // Trigger secondary data fetch in background
        _loadSecondaryData(selectedWallet.id);
      } else {
        // No wallet available
        emit(
          state.copyWith(
            personalWallets: walletsResult.personal,
            sharedWallets: walletsResult.shared,
            selectedWallet: null,
            isLoading: false,
            isInitialLoad: false,
            isLoadingAnalytics: true,
            status: DashboardStatus.success,
          ),
        );

        // Trigger secondary data fetch in background
        _loadSecondaryData(null);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Initialize failed ($e)');
      emit(
        state.copyWith(
          isLoading: false,
          isInitialLoad: false,
          status: DashboardStatus.failure,
        ),
      );
    }
  }

  Future<void> _onSelectWalletRequested(
    DashboardSelectWalletRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedWallet: event.wallet,
        isLoading: true,
        status: DashboardStatus.loading,
      ),
    );
    await _fetchWalletDataHelper(event.wallet, emit);
  }

  Future<void> _onSetTimeframeRequested(
    DashboardSetTimeframeRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        activeTimeframe: event.timeframe,
        isLoading: true,
        status: DashboardStatus.loading,
      ),
    );
    await _fetchWalletDataHelper(state.selectedWallet, emit);
  }

  Future<void> _onToggleSharedModeRequested(
    DashboardToggleSharedModeRequested event,
    Emitter<DashboardState> emit,
  ) async {
    if (event.isShared) {
      if (state.sharedWallets.isNotEmpty) {
        emit(
          state.copyWith(
            selectedWallet: state.sharedWallets[0],
            isLoading: true,
            status: DashboardStatus.loading,
          ),
        );
        await _fetchWalletDataHelper(state.sharedWallets[0], emit);
      }
    } else {
      if (state.personalWallets.isNotEmpty) {
        emit(
          state.copyWith(
            selectedWallet: state.personalWallets[0],
            isLoading: true,
            status: DashboardStatus.loading,
          ),
        );
        await _fetchWalletDataHelper(state.personalWallets[0], emit);
      }
    }
  }

  Future<void> _onRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, status: DashboardStatus.loading));

    try {
      final walletsResult = await _fetchWalletsHelper(state.selectedWallet);
      final wallet = walletsResult.selected;

      if (wallet != null) {
        // Load primary critical data in parallel: Expenses & Reminders
        final results = await Future.wait([
          _fetchExpensesDataHelper(wallet.id),
          _fetchRemindersDataHelper(wallet.id),
        ]);

        emit(
          state.copyWith(
            personalWallets: walletsResult.personal,
            sharedWallets: walletsResult.shared,
            selectedWallet: wallet,
            expenses: results[0] as List<ExpenseEntity>,
            reminders: results[1] as List<BillReminderEntity>,
            isLoading: false,
            isLoadingAnalytics: true,
            status: DashboardStatus.success,
          ),
        );

        // Trigger secondary data fetch in background
        _loadSecondaryData(wallet.id);
      } else {
        emit(
          state.copyWith(
            personalWallets: walletsResult.personal,
            sharedWallets: walletsResult.shared,
            selectedWallet: null,
            isLoading: false,
            isLoadingAnalytics: true,
            status: DashboardStatus.success,
          ),
        );

        // Trigger secondary data fetch in background
        _loadSecondaryData(null);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Refresh failed ($e)');
      emit(state.copyWith(isLoading: false, status: DashboardStatus.failure));
    }
  }

  Future<void> _onFetchAnalyticsRequested(
    DashboardFetchAnalyticsRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final wallet = state.selectedWallet;
    if (wallet == null) return;

    emit(state.copyWith(isLoading: true, status: DashboardStatus.loading));

    try {
      final results = await Future.wait([
        _fetchCompareDataHelper(wallet.id),
        _fetchBreakdownDataHelper(wallet.id),
      ]);

      emit(
        state.copyWith(
          compareData: results[0],
          breakdownData: results[1],
          isLoading: false,
          status: DashboardStatus.success,
        ),
      );
    } catch (e) {
      debugPrint('DashboardBloc: Fetch analytics failed ($e)');
      emit(state.copyWith(isLoading: false, status: DashboardStatus.failure));
    }
  }

  Future<void> _onFetchRemindersRequested(
    DashboardFetchRemindersRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final wallet = state.selectedWallet;
    if (wallet == null) return;

    try {
      final reminders = await _fetchRemindersDataHelper(wallet.id);
      emit(state.copyWith(reminders: reminders));
    } catch (e) {
      debugPrint('DashboardBloc: Fetch reminders failed ($e)');
    }
  }

  Future<void> _onFetchCategoriesRequested(
    DashboardFetchCategoriesRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final categories = await _fetchCategoriesHelper();
      emit(state.copyWith(categories: categories));
    } catch (e) {
      debugPrint('DashboardBloc: Fetch categories failed ($e)');
    }
  }

  Future<void> _onAddCategoryRequested(
    DashboardAddCategoryRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final tempId = 'temp_cat_${DateTime.now().millisecondsSinceEpoch}';
    final newCategory = ExpenseCategory(
      id: tempId,
      name: event.name,
      icon: event.icon,
      color: event.color,
      isDefault: false,
    );

    // Optimistic insert
    final updatedCategories = List<ExpenseCategory>.from(state.categories)
      ..add(newCategory);
    emit(state.copyWith(categories: updatedCategories));

    try {
      final response = await _client.dio.post(
        '/categories',
        data: {'name': event.name, 'icon': event.icon, 'color': event.color},
      );

      if (response.data != null && response.data['success'] == true) {
        final categories = await _fetchCategoriesHelper();
        emit(state.copyWith(categories: categories));
        event.completer.complete(true);
      } else {
        // Rollback
        final rolledBack = List<ExpenseCategory>.from(state.categories)
          ..removeWhere((c) => c.id == tempId);
        emit(state.copyWith(categories: rolledBack));
        event.completer.complete(false);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Failed to add category ($e)');
      final rolledBack = List<ExpenseCategory>.from(state.categories)
        ..removeWhere((c) => c.id == tempId);
      emit(state.copyWith(categories: rolledBack));
      event.completer.complete(false);
    }
  }

  Future<void> _onUpdateCategoryRequested(
    DashboardUpdateCategoryRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final index = state.categories.indexWhere((c) => c.id == event.id);
    if (index == -1) {
      event.completer.complete(false);
      return;
    }
    final backup = state.categories[index];

    // Optimistic update
    final updatedCategories = List<ExpenseCategory>.from(state.categories);
    updatedCategories[index] = ExpenseCategory(
      id: event.id,
      name: event.name,
      icon: event.icon,
      color: event.color,
      isDefault: backup.isDefault,
      userId: backup.userId,
    );
    emit(state.copyWith(categories: updatedCategories));

    try {
      final response = await _client.dio.put(
        '/categories/${event.id}',
        data: {'name': event.name, 'icon': event.icon, 'color': event.color},
      );

      if (response.data != null && response.data['success'] == true) {
        final categories = await _fetchCategoriesHelper();
        emit(state.copyWith(categories: categories));
        event.completer.complete(true);
      } else {
        // Rollback
        final rolledBack = List<ExpenseCategory>.from(state.categories);
        rolledBack[index] = backup;
        emit(state.copyWith(categories: rolledBack));
        event.completer.complete(false);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Failed to update category ($e)');
      final rolledBack = List<ExpenseCategory>.from(state.categories);
      rolledBack[index] = backup;
      emit(state.copyWith(categories: rolledBack));
      event.completer.complete(false);
    }
  }

  Future<void> _onDeleteCategoryRequested(
    DashboardDeleteCategoryRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final index = state.categories.indexWhere((c) => c.id == event.id);
    if (index == -1) {
      event.completer.complete(false);
      return;
    }
    final backup = state.categories[index];

    // Optimistic delete
    final updatedCategories = List<ExpenseCategory>.from(state.categories)
      ..removeAt(index);
    emit(state.copyWith(categories: updatedCategories));

    try {
      final response = await _client.dio.delete('/categories/${event.id}');

      if (response.data != null && response.data['success'] == true) {
        final categories = await _fetchCategoriesHelper();
        emit(state.copyWith(categories: categories));
        event.completer.complete(true);
      } else {
        // Rollback
        final rolledBack = List<ExpenseCategory>.from(state.categories)
          ..insert(index, backup);
        emit(state.copyWith(categories: rolledBack));
        event.completer.complete(false);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Failed to delete category ($e)');
      final rolledBack = List<ExpenseCategory>.from(state.categories)
        ..insert(index, backup);
      emit(state.copyWith(categories: rolledBack));
      event.completer.complete(false);
    }
  }

  Future<void> _onAddExpenseRequested(
    DashboardAddExpenseRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final wallet = state.selectedWallet;
    if (wallet == null) {
      event.completer.complete(false);
      return;
    }

    // Optimistic insert
    final updatedExpenses = List<ExpenseEntity>.from(state.expenses)
      ..insert(0, event.expense);
    emit(state.copyWith(expenses: updatedExpenses));

    try {
      final body = {
        'amount': event.expense.amount,
        'description': event.expense.description,
        'type': event.expense.type == ExpenseType.routine
            ? 'ROUTINE'
            : 'NON_ROUTINE',
        'categoryId': event.expense.category.id,
        'walletId': wallet.id,
        'date': event.expense.date.toUtc().toIso8601String(),
      };

      final response = await _client.dio.post('/expenses', data: body);

      if (response.data != null && response.data['success'] == true) {
        final serverExpense = ExpenseEntity.fromJson(
          response.data['data'] as Map,
        );
        final currentExpenses = List<ExpenseEntity>.from(state.expenses);
        final idx = currentExpenses.indexWhere((e) => e.id == event.expense.id);
        if (idx >= 0) {
          currentExpenses[idx] = serverExpense;
        }

        emit(state.copyWith(expenses: currentExpenses));
        _backgroundRefreshAfterMutation(emit);
        event.completer.complete(true);
      } else {
        // Rollback
        final rolledBack = List<ExpenseEntity>.from(state.expenses)
          ..removeWhere((e) => e.id == event.expense.id);
        emit(state.copyWith(expenses: rolledBack));
        event.completer.complete(false);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Failed to add expense ($e)');
      final rolledBack = List<ExpenseEntity>.from(state.expenses)
        ..removeWhere((e) => e.id == event.expense.id);
      emit(state.copyWith(expenses: rolledBack));
      event.completer.complete(false);
    }
  }

  Future<void> _onDeleteExpenseRequested(
    DashboardDeleteExpenseRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final wallet = state.selectedWallet;
    if (wallet == null) {
      event.completer.complete(false);
      return;
    }

    final index = state.expenses.indexWhere((e) => e.id == event.id);
    if (index == -1) {
      event.completer.complete(false);
      return;
    }
    final backup = state.expenses[index];

    // Optimistic delete
    final updatedExpenses = List<ExpenseEntity>.from(state.expenses)
      ..removeAt(index);
    emit(state.copyWith(expenses: updatedExpenses));

    try {
      final response = await _client.dio.delete(
        '/expenses/${event.id}',
        queryParameters: {'walletId': wallet.id},
      );

      if (response.data != null && response.data['success'] == true) {
        _backgroundRefreshAfterMutation(emit);
        event.completer.complete(true);
      } else {
        // Rollback
        final rolledBack = List<ExpenseEntity>.from(state.expenses)
          ..insert(index, backup);
        emit(state.copyWith(expenses: rolledBack));
        event.completer.complete(false);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Failed to delete expense ($e)');
      final rolledBack = List<ExpenseEntity>.from(state.expenses)
        ..insert(index, backup);
      emit(state.copyWith(expenses: rolledBack));
      event.completer.complete(false);
    }
  }

  Future<void> _onUpdateDailyBudgetRequested(
    DashboardUpdateDailyBudgetRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final wallet = state.selectedWallet;
    if (wallet == null) {
      event.completer.complete(false);
      return;
    }
    final backup = wallet;

    // Optimistic update
    final updated = _copyWallet(wallet, dailyBudget: event.budget);
    _updateLocalWalletInState(updated, emit);

    try {
      final response = await _client.dio.patch(
        '/wallets/${wallet.id}',
        data: {'dailyBudget': event.budget},
      );

      if (response.data != null && response.data['success'] == true) {
        final walletsResult = await _fetchWalletsHelper(state.selectedWallet);
        emit(
          state.copyWith(
            personalWallets: walletsResult.personal,
            sharedWallets: walletsResult.shared,
            selectedWallet: walletsResult.selected,
          ),
        );
        event.completer.complete(true);
      } else {
        _updateLocalWalletInState(backup, emit);
        event.completer.complete(false);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Failed to update budget ($e)');
      _updateLocalWalletInState(backup, emit);
      event.completer.complete(false);
    }
  }

  Future<void> _onUpdateMonthlyBudgetRequested(
    DashboardUpdateMonthlyBudgetRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final wallet = state.selectedWallet;
    if (wallet == null) {
      event.completer.complete(false);
      return;
    }
    final backup = wallet;

    double? computedDaily;
    if (event.syncDailyBudget) {
      final daysInMonth = state.daysInCurrentMonth;
      computedDaily = (event.budget / daysInMonth).roundToDouble();
    }

    // Optimistic update
    final updated = _copyWallet(
      wallet,
      monthlyBudget: event.budget,
      dailyBudget: computedDaily,
    );
    _updateLocalWalletInState(updated, emit);

    try {
      final payload = <String, dynamic>{
        'monthlyBudget': event.budget,
      };
      if (computedDaily != null) {
        payload['dailyBudget'] = computedDaily;
      }

      final response = await _client.dio.patch(
        '/wallets/${wallet.id}',
        data: payload,
      );

      if (response.data != null && response.data['success'] == true) {
        final walletsResult = await _fetchWalletsHelper(state.selectedWallet);
        emit(
          state.copyWith(
            personalWallets: walletsResult.personal,
            sharedWallets: walletsResult.shared,
            selectedWallet: walletsResult.selected,
          ),
        );
        event.completer.complete(true);
      } else {
        _updateLocalWalletInState(backup, emit);
        event.completer.complete(false);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Failed to update monthly budget ($e)');
      _updateLocalWalletInState(backup, emit);
      event.completer.complete(false);
    }
  }

  Future<void> _onSetCategoryBudgetRequested(
    DashboardSetCategoryBudgetRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final wallet = state.selectedWallet;
    if (wallet == null) {
      event.completer.complete(false);
      return;
    }
    final backup = wallet;

    // Optimistic update
    final currentList = List<CategoryBudgetEntity>.from(wallet.categoryBudgets);
    final idx = currentList.indexWhere(
      (cb) => cb.categoryId == event.categoryId,
    );

    if (event.amount <= 0) {
      if (idx != -1) currentList.removeAt(idx);
    } else {
      final updatedItem = CategoryBudgetEntity(
        id: idx != -1
            ? currentList[idx].id
            : 'temp_cb_${DateTime.now().millisecondsSinceEpoch}',
        categoryId: event.categoryId,
        walletId: wallet.id,
        amount: event.amount,
      );
      if (idx != -1) {
        currentList[idx] = updatedItem;
      } else {
        currentList.add(updatedItem);
      }
    }

    final updatedWallet = _copyWallet(wallet, categoryBudgets: currentList);
    _updateLocalWalletInState(updatedWallet, emit);

    try {
      final response = await _client.dio.put(
        '/wallets/${wallet.id}/category-budgets',
        data: {
          'categoryId': event.categoryId,
          'amount': event.amount,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final walletsResult = await _fetchWalletsHelper(state.selectedWallet);
        emit(
          state.copyWith(
            personalWallets: walletsResult.personal,
            sharedWallets: walletsResult.shared,
            selectedWallet: walletsResult.selected,
          ),
        );
        event.completer.complete(true);
      } else {
        _updateLocalWalletInState(backup, emit);
        event.completer.complete(false);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Failed to set category budget ($e)');
      _updateLocalWalletInState(backup, emit);
      event.completer.complete(false);
    }
  }

  Future<void> _onDeleteCategoryBudgetRequested(
    DashboardDeleteCategoryBudgetRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final wallet = state.selectedWallet;
    if (wallet == null) {
      event.completer.complete(false);
      return;
    }
    final backup = wallet;

    // Optimistic delete
    final currentList = List<CategoryBudgetEntity>.from(wallet.categoryBudgets)
      ..removeWhere((cb) => cb.categoryId == event.categoryId);
    final updatedWallet = _copyWallet(wallet, categoryBudgets: currentList);
    _updateLocalWalletInState(updatedWallet, emit);

    try {
      final response = await _client.dio.delete(
        '/wallets/${wallet.id}/category-budgets/${event.categoryId}',
      );

      if (response.data != null && response.data['success'] == true) {
        final walletsResult = await _fetchWalletsHelper(state.selectedWallet);
        emit(
          state.copyWith(
            personalWallets: walletsResult.personal,
            sharedWallets: walletsResult.shared,
            selectedWallet: walletsResult.selected,
          ),
        );
        event.completer.complete(true);
      } else {
        _updateLocalWalletInState(backup, emit);
        event.completer.complete(false);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Failed to delete category budget ($e)');
      _updateLocalWalletInState(backup, emit);
      event.completer.complete(false);
    }
  }

  Future<void> _onUpdateWalletCurrencyRequested(
    DashboardUpdateWalletCurrencyRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final wallet = state.selectedWallet;
    if (wallet == null) {
      event.completer.complete(false);
      return;
    }
    final backup = wallet;

    // Optimistic update
    final updated = _copyWallet(wallet, currency: event.currency);
    _updateLocalWalletInState(updated, emit);

    try {
      final response = await _client.dio.patch(
        '/wallets/${wallet.id}',
        data: {'currency': event.currency},
      );

      if (response.data != null && response.data['success'] == true) {
        final walletsResult = await _fetchWalletsHelper(state.selectedWallet);
        emit(
          state.copyWith(
            personalWallets: walletsResult.personal,
            sharedWallets: walletsResult.shared,
            selectedWallet: walletsResult.selected,
          ),
        );
        event.completer.complete(true);
      } else {
        _updateLocalWalletInState(backup, emit);
        event.completer.complete(false);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Failed to update currency ($e)');
      _updateLocalWalletInState(backup, emit);
      event.completer.complete(false);
    }
  }

  Future<void> _onFetchSharedGroupsRequested(
    DashboardFetchSharedGroupsRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final sharedMap = await _fetchSharedGroupsHelper();
      emit(
        state.copyWith(
          sharedGroups: sharedMap['groups'] as List,
          pendingInvites: sharedMap['pendingInvites'] as List,
        ),
      );
    } catch (e) {
      debugPrint('DashboardBloc: Failed to fetch shared groups ($e)');
    }
  }

  Future<void> _onSendInviteRequested(
    DashboardSendInviteRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final response = await _client.dio.post(
        '/sharing/invite',
        data: {'email': event.email, 'groupName': event.groupName},
      );

      if (response.data != null && response.data['success'] == true) {
        final results = await Future.wait([
          _fetchSharedGroupsHelper(),
          _fetchWalletsHelper(state.selectedWallet),
        ]);

        final sharedMap = results[0] as Map;
        final walletsResult = results[1] as _WalletsResult;

        emit(
          state.copyWith(
            sharedGroups: sharedMap['groups'] as List,
            pendingInvites: sharedMap['pendingInvites'] as List,
            personalWallets: walletsResult.personal,
            sharedWallets: walletsResult.shared,
            selectedWallet: walletsResult.selected,
          ),
        );
        event.completer.complete(null);
      } else {
        event.completer.complete(
          response.data?['message'] ?? 'Failed to send invite',
        );
      }
    } catch (e) {
      debugPrint('DashboardBloc: Failed to send invite ($e)');
      if (e is DioException && e.response?.data != null) {
        event.completer.complete(
          e.response?.data['message'] ?? 'Failed to send invite',
        );
      } else {
        event.completer.complete('Connection error. Please try again.');
      }
    }
  }

  Future<void> _onAcceptInviteRequested(
    DashboardAcceptInviteRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final response = await _client.dio.post(
        '/sharing/invite/${event.inviteId}/accept',
      );

      if (response.data != null && response.data['success'] == true) {
        final results = await Future.wait([
          _fetchSharedGroupsHelper(),
          _fetchWalletsHelper(state.selectedWallet),
        ]);

        final sharedMap = results[0] as Map;
        final walletsResult = results[1] as _WalletsResult;

        emit(
          state.copyWith(
            sharedGroups: sharedMap['groups'] as List,
            pendingInvites: sharedMap['pendingInvites'] as List,
            personalWallets: walletsResult.personal,
            sharedWallets: walletsResult.shared,
            selectedWallet: walletsResult.selected,
          ),
        );
        event.completer.complete(true);
      } else {
        event.completer.complete(false);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Failed to accept invite ($e)');
      event.completer.complete(false);
    }
  }

  Future<void> _onRejectInviteRequested(
    DashboardRejectInviteRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final response = await _client.dio.post(
        '/sharing/invite/${event.inviteId}/reject',
      );

      if (response.data != null && response.data['success'] == true) {
        final results = await Future.wait([
          _fetchSharedGroupsHelper(),
          _fetchWalletsHelper(state.selectedWallet),
        ]);

        final sharedMap = results[0] as Map;
        final walletsResult = results[1] as _WalletsResult;

        emit(
          state.copyWith(
            sharedGroups: sharedMap['groups'] as List,
            pendingInvites: sharedMap['pendingInvites'] as List,
            personalWallets: walletsResult.personal,
            sharedWallets: walletsResult.shared,
            selectedWallet: walletsResult.selected,
          ),
        );
        event.completer.complete(true);
      } else {
        event.completer.complete(false);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Failed to reject invite ($e)');
      event.completer.complete(false);
    }
  }

  Future<void> _onLeaveGroupRequested(
    DashboardLeaveGroupRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final response = await _client.dio.post(
        '/sharing/groups/${event.groupId}/leave',
      );

      if (response.data != null && response.data['success'] == true) {
        final results = await Future.wait([
          _fetchSharedGroupsHelper(),
          _fetchWalletsHelper(state.selectedWallet),
        ]);

        final sharedMap = results[0] as Map;
        final walletsResult = results[1] as _WalletsResult;

        emit(
          state.copyWith(
            sharedGroups: sharedMap['groups'] as List,
            pendingInvites: sharedMap['pendingInvites'] as List,
            personalWallets: walletsResult.personal,
            sharedWallets: walletsResult.shared,
            selectedWallet: walletsResult.selected,
          ),
        );
        event.completer.complete(true);
      } else {
        event.completer.complete(false);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Failed to leave group ($e)');
      event.completer.complete(false);
    }
  }

  Future<void> _onDeleteGroupRequested(
    DashboardDeleteGroupRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final response = await _client.dio.delete(
        '/sharing/groups/${event.groupId}',
      );

      if (response.data != null && response.data['success'] == true) {
        final results = await Future.wait([
          _fetchSharedGroupsHelper(),
          _fetchWalletsHelper(state.selectedWallet),
        ]);

        final sharedMap = results[0] as Map;
        final walletsResult = results[1] as _WalletsResult;

        emit(
          state.copyWith(
            sharedGroups: sharedMap['groups'] as List,
            pendingInvites: sharedMap['pendingInvites'] as List,
            personalWallets: walletsResult.personal,
            sharedWallets: walletsResult.shared,
            selectedWallet: walletsResult.selected,
          ),
        );
        event.completer.complete(true);
      } else {
        event.completer.complete(false);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Failed to delete group ($e)');
      event.completer.complete(false);
    }
  }

  Future<void> _onAddReminderRequested(
    DashboardAddReminderRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final wallet = state.selectedWallet;
    if (wallet == null) {
      event.completer.complete(false);
      return;
    }

    Periodicity parsedPeriodicity = Periodicity.monthly;
    switch (event.periodicity.toUpperCase()) {
      case 'DAILY':
        parsedPeriodicity = Periodicity.daily;
        break;
      case 'WEEKLY':
        parsedPeriodicity = Periodicity.weekly;
        break;
      case 'MONTHLY':
        parsedPeriodicity = Periodicity.monthly;
        break;
      case 'YEARLY':
        parsedPeriodicity = Periodicity.yearly;
        break;
    }

    final tempId = 'temp_rem_${DateTime.now().millisecondsSinceEpoch}';
    final categoryMatch = state.categories.firstWhere(
      (c) => c.id == event.categoryId,
      orElse: () => state.categories.isNotEmpty
          ? state.categories.first
          : ExpenseCategory(
              id: 'temp',
              name: 'Other',
              icon: '💰',
              color: '#4F46E5',
            ),
    );

    final reminderCategory = BillReminderCategory(
      id: categoryMatch.id,
      name: categoryMatch.name,
      icon: categoryMatch.icon,
      color: categoryMatch.color,
    );

    final newReminder = BillReminderEntity(
      id: tempId,
      title: event.title,
      amount: event.amount,
      dueDate: event.dueDate,
      periodicity: parsedPeriodicity,
      status: ReminderStatus.active,
      userId: 'user_1',
      walletId: wallet.id,
      categoryId: event.categoryId,
      category: reminderCategory,
      notifyDaysBefore: event.notifyDaysBefore,
      autoLogExpense: event.autoLogExpense,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      expenses: [],
    );

    // Optimistic insert
    final updatedReminders = List<BillReminderEntity>.from(state.reminders)
      ..add(newReminder);
    emit(state.copyWith(reminders: updatedReminders));

    try {
      final response = await _client.dio.post(
        '/reminders',
        data: {
          'title': event.title,
          'amount': event.amount,
          'dueDate': event.dueDate.toUtc().toIso8601String(),
          'periodicity': event.periodicity.toUpperCase(),
          'categoryId': event.categoryId,
          'walletId': wallet.id,
          'notifyDaysBefore': event.notifyDaysBefore,
          'autoLogExpense': event.autoLogExpense,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final reminders = await _fetchRemindersDataHelper(wallet.id);
        emit(state.copyWith(reminders: reminders));
        event.completer.complete(true);
      } else {
        // Rollback
        final rolledBack = List<BillReminderEntity>.from(state.reminders)
          ..removeWhere((r) => r.id == tempId);
        emit(state.copyWith(reminders: rolledBack));
        event.completer.complete(false);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Failed to add reminder ($e)');
      final rolledBack = List<BillReminderEntity>.from(state.reminders)
        ..removeWhere((r) => r.id == tempId);
      emit(state.copyWith(reminders: rolledBack));
      event.completer.complete(false);
    }
  }

  Future<void> _onUpdateReminderRequested(
    DashboardUpdateReminderRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final wallet = state.selectedWallet;
    if (wallet == null) {
      event.completer.complete(false);
      return;
    }

    final index = state.reminders.indexWhere((r) => r.id == event.id);
    if (index == -1) {
      event.completer.complete(false);
      return;
    }
    final backup = state.reminders[index];

    Periodicity parsedPeriodicity = backup.periodicity;
    if (event.periodicity != null) {
      switch (event.periodicity!.toUpperCase()) {
        case 'DAILY':
          parsedPeriodicity = Periodicity.daily;
          break;
        case 'WEEKLY':
          parsedPeriodicity = Periodicity.weekly;
          break;
        case 'MONTHLY':
          parsedPeriodicity = Periodicity.monthly;
          break;
        case 'YEARLY':
          parsedPeriodicity = Periodicity.yearly;
          break;
      }
    }

    ReminderStatus parsedStatus = backup.status;
    if (event.status != null) {
      switch (event.status!.toUpperCase()) {
        case 'ACTIVE':
          parsedStatus = ReminderStatus.active;
          break;
        case 'SNOOZED':
          parsedStatus = ReminderStatus.snoozed;
          break;
        case 'COMPLETED':
          parsedStatus = ReminderStatus.completed;
          break;
        case 'CANCELLED':
          parsedStatus = ReminderStatus.cancelled;
          break;
      }
    }

    BillReminderCategory? reminderCategory = backup.category;
    if (event.categoryId != null) {
      final categoryMatch = state.categories.firstWhere(
        (c) => c.id == event.categoryId,
        orElse: () => state.categories.first,
      );
      reminderCategory = BillReminderCategory(
        id: categoryMatch.id,
        name: categoryMatch.name,
        icon: categoryMatch.icon,
        color: categoryMatch.color,
      );
    }

    final updated = BillReminderEntity(
      id: event.id,
      title: event.title ?? backup.title,
      amount: event.amount ?? backup.amount,
      dueDate: event.dueDate ?? backup.dueDate,
      periodicity: parsedPeriodicity,
      status: parsedStatus,
      userId: backup.userId,
      walletId: backup.walletId,
      categoryId: event.categoryId ?? backup.categoryId,
      category: reminderCategory,
      notifyDaysBefore: event.notifyDaysBefore ?? backup.notifyDaysBefore,
      autoLogExpense: event.autoLogExpense ?? backup.autoLogExpense,
      createdAt: backup.createdAt,
      updatedAt: DateTime.now(),
      expenses: backup.expenses,
      lastNotifiedAt: backup.lastNotifiedAt,
      lastTriggeredAt: backup.lastTriggeredAt,
    );

    // Optimistic update
    final updatedReminders = List<BillReminderEntity>.from(state.reminders);
    updatedReminders[index] = updated;
    emit(state.copyWith(reminders: updatedReminders));

    try {
      final response = await _client.dio.put(
        '/reminders/${event.id}',
        data: {
          'walletId': wallet.id,
          if (event.title != null) 'title': event.title,
          if (event.amount != null) 'amount': event.amount,
          if (event.dueDate != null)
            'dueDate': event.dueDate!.toUtc().toIso8601String(),
          if (event.periodicity != null)
            'periodicity': event.periodicity!.toUpperCase(),
          if (event.status != null) 'status': event.status!.toUpperCase(),
          'categoryId': event.categoryId,
          if (event.notifyDaysBefore != null)
            'notifyDaysBefore': event.notifyDaysBefore,
          if (event.autoLogExpense != null)
            'autoLogExpense': event.autoLogExpense,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final reminders = await _fetchRemindersDataHelper(wallet.id);
        emit(state.copyWith(reminders: reminders));
        event.completer.complete(true);
      } else {
        // Rollback
        final rolledBack = List<BillReminderEntity>.from(state.reminders);
        rolledBack[index] = backup;
        emit(state.copyWith(reminders: rolledBack));
        event.completer.complete(false);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Failed to update reminder ($e)');
      final rolledBack = List<BillReminderEntity>.from(state.reminders);
      rolledBack[index] = backup;
      emit(state.copyWith(reminders: rolledBack));
      event.completer.complete(false);
    }
  }

  Future<void> _onDeleteReminderRequested(
    DashboardDeleteReminderRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final wallet = state.selectedWallet;
    if (wallet == null) {
      if (!event.completer.isCompleted) event.completer.complete(false);
      return;
    }

    final index = state.reminders.indexWhere((r) => r.id == event.id);
    if (index == -1) {
      if (!event.completer.isCompleted) event.completer.complete(false);
      return;
    }
    final backup = state.reminders[index];
    final targetWalletId = backup.walletId.isNotEmpty
        ? backup.walletId
        : wallet.id;

    // Optimistic delete
    final updatedReminders = List<BillReminderEntity>.from(state.reminders)
      ..removeAt(index);
    emit(state.copyWith(reminders: updatedReminders));

    try {
      final response = await _client.dio.delete(
        '/reminders/${event.id}',
        queryParameters: {'walletId': targetWalletId},
      );

      if (response.data != null && response.data['success'] == true) {
        final reminders = await _fetchRemindersDataHelper(wallet.id);
        emit(state.copyWith(reminders: reminders));
        if (!event.completer.isCompleted) event.completer.complete(true);
      } else {
        // Rollback
        final rolledBack = List<BillReminderEntity>.from(state.reminders)
          ..insert(index, backup);
        emit(state.copyWith(reminders: rolledBack));
        if (!event.completer.isCompleted) event.completer.complete(false);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Failed to delete reminder ($e)');
      final rolledBack = List<BillReminderEntity>.from(state.reminders)
        ..insert(index, backup);
      emit(state.copyWith(reminders: rolledBack));
      if (!event.completer.isCompleted) event.completer.complete(false);
    }
  }

  Future<void> _onPayBillRequested(
    DashboardPayBillRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final wallet = state.selectedWallet;
    if (wallet == null) {
      event.completer.complete(false);
      return;
    }

    final targetWalletId = event.reminder.walletId.isNotEmpty
        ? event.reminder.walletId
        : wallet.id;

    // Ensure categories are loaded
    List<ExpenseCategory> availableCategories = state.categories;
    if (availableCategories.isEmpty) {
      try {
        availableCategories = await _fetchCategoriesHelper();
        emit(state.copyWith(categories: availableCategories));
      } catch (_) {}
    }

    ExpenseCategory? categoryMatch;
    String? resolvedCategoryId =
        event.reminder.categoryId ?? event.reminder.category?.id;
    if (resolvedCategoryId != null && resolvedCategoryId.isNotEmpty) {
      for (final c in availableCategories) {
        if (c.id == resolvedCategoryId) {
          categoryMatch = c;
          break;
        }
      }
    }
    if (categoryMatch == null && availableCategories.isNotEmpty) {
      categoryMatch = availableCategories.firstWhere(
        (c) =>
            c.name.toLowerCase().contains('util') ||
            c.name.toLowerCase().contains('sub') ||
            c.name.toLowerCase().contains('tagihan'),
        orElse: () => availableCategories.first,
      );
      resolvedCategoryId = categoryMatch.id;
    }
    categoryMatch ??= ExpenseCategory(
      id: 'temp',
      name: 'Other',
      icon: '💰',
      color: '#4F46E5',
    );

    final optimisticExpense = ExpenseEntity(
      id: 'temp_pay_${DateTime.now().millisecondsSinceEpoch}',
      amount: event.reminder.amount,
      description: 'Pembayaran: ${event.reminder.title}',
      date: DateTime.now(),
      type: ExpenseType.routine,
      userId: 'user_1',
      walletId: targetWalletId,
      category: categoryMatch,
      creatorName: 'Me',
    );

    // Create optimistic BillReminderExpense
    final optBillExpense = BillReminderExpense(
      id: 'temp_bre_${DateTime.now().millisecondsSinceEpoch}',
      amount: event.reminder.amount,
      date: DateTime.now(),
    );

    final index = state.reminders.indexWhere((r) => r.id == event.reminder.id);
    BillReminderEntity? reminderBackup;
    if (index != -1) {
      reminderBackup = state.reminders[index];
      final updatedExpenses = List<BillReminderExpense>.from(
        event.reminder.expenses,
      )..add(optBillExpense);
      final updatedReminders = List<BillReminderEntity>.from(state.reminders);
      updatedReminders[index] = BillReminderEntity(
        id: event.reminder.id,
        title: event.reminder.title,
        amount: event.reminder.amount,
        dueDate: event.reminder.dueDate,
        periodicity: event.reminder.periodicity,
        status: event.reminder.status,
        userId: event.reminder.userId,
        walletId: event.reminder.walletId,
        categoryId: event.reminder.categoryId,
        category: event.reminder.category,
        notifyDaysBefore: event.reminder.notifyDaysBefore,
        autoLogExpense: event.reminder.autoLogExpense,
        createdAt: event.reminder.createdAt,
        updatedAt: event.reminder.updatedAt,
        expenses: updatedExpenses,
        lastNotifiedAt: event.reminder.lastNotifiedAt,
        lastTriggeredAt: event.reminder.lastTriggeredAt,
      );

      final updatedExpensesList = List<ExpenseEntity>.from(state.expenses)
        ..insert(0, optimisticExpense);
      emit(
        state.copyWith(
          reminders: updatedReminders,
          expenses: updatedExpensesList,
        ),
      );
    }

    try {
      bool isPaidSuccess = false;

      // 1. Try dedicated pay endpoint first
      try {
        final payResponse = await _client.dio.post(
          '/reminders/${event.reminder.id}/pay',
          data: {'walletId': targetWalletId, 'categoryId': ?resolvedCategoryId},
        );
        if (payResponse.data != null && payResponse.data['success'] == true) {
          isPaidSuccess = true;
        }
      } catch (payErr) {
        debugPrint(
          'DashboardBloc: /reminders/:id/pay fallback to /expenses ($payErr)',
        );
      }

      // 2. Fallback to POST /expenses if needed
      if (!isPaidSuccess) {
        final body = {
          'amount': event.reminder.amount,
          'description': 'Pembayaran: ${event.reminder.title}',
          'type': 'ROUTINE',
          'categoryId': ?resolvedCategoryId,
          'walletId': targetWalletId,
          'date': DateTime.now().toUtc().toIso8601String(),
          'billReminderId': event.reminder.id,
        };

        final response = await _client.dio.post('/expenses', data: body);
        if (response.data != null && response.data['success'] == true) {
          isPaidSuccess = true;
        }
      }

      if (isPaidSuccess) {
        _backgroundRefreshAfterMutation(emit);
        final reminders = await _fetchRemindersDataHelper(wallet.id);
        emit(state.copyWith(reminders: reminders));
        event.completer.complete(true);
      } else {
        // Rollback
        final rolledBackExpenses = List<ExpenseEntity>.from(state.expenses)
          ..removeWhere((e) => e.id == optimisticExpense.id);
        final rolledBackReminders = List<BillReminderEntity>.from(
          state.reminders,
        );
        if (index != -1 && reminderBackup != null) {
          rolledBackReminders[index] = reminderBackup;
        }
        emit(
          state.copyWith(
            expenses: rolledBackExpenses,
            reminders: rolledBackReminders,
          ),
        );
        event.completer.complete(false);
      }
    } catch (e) {
      debugPrint('DashboardBloc: Failed to pay bill ($e)');
      final rolledBackExpenses = List<ExpenseEntity>.from(state.expenses)
        ..removeWhere((e) => e.id == optimisticExpense.id);
      final rolledBackReminders = List<BillReminderEntity>.from(
        state.reminders,
      );
      if (index != -1 && reminderBackup != null) {
        rolledBackReminders[index] = reminderBackup;
      }
      emit(
        state.copyWith(
          expenses: rolledBackExpenses,
          reminders: rolledBackReminders,
        ),
      );
      event.completer.complete(false);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Future<void> _fetchWalletDataHelper(
    WalletEntity? wallet,
    Emitter<DashboardState> emit,
  ) async {
    if (wallet == null) {
      emit(
        state.copyWith(
          expenses: const [],
          compareData: null,
          breakdownData: null,
          reminders: const [],
          isLoading: false,
          status: DashboardStatus.success,
        ),
      );
      return;
    }

    try {
      final results = await Future.wait([
        _fetchExpensesDataHelper(wallet.id),
        _fetchRemindersDataHelper(wallet.id),
      ]);

      emit(
        state.copyWith(
          expenses: results[0] as List<ExpenseEntity>,
          reminders: results[1] as List<BillReminderEntity>,
          isLoading: false,
          isLoadingAnalytics: true,
          status: DashboardStatus.success,
        ),
      );

      _loadSecondaryWalletData(wallet.id);
    } catch (e) {
      debugPrint('DashboardBloc: Fetch wallet data failed ($e)');
      emit(state.copyWith(isLoading: false, status: DashboardStatus.failure));
    }
  }

  Future<_WalletsResult> _fetchWalletsHelper(
    WalletEntity? currentSelected,
  ) async {
    final response = await _client.dio.get('/wallets');
    if (response.data != null && response.data['success'] == true) {
      final data = response.data['data'];
      final personalList = data['personal'] as List;
      final personal = personalList
          .map((item) => WalletEntity.fromJson(item as Map))
          .toList();

      final sharedList = data['shared'] as List;
      final shared = sharedList
          .map((item) => WalletEntity.fromJson(item as Map))
          .toList();

      WalletEntity? selected = currentSelected;
      if (selected == null) {
        if (personal.isNotEmpty) {
          selected = personal[0];
        } else if (shared.isNotEmpty) {
          selected = shared[0];
        }
      } else {
        final idxP = personal.indexWhere((w) => w.id == selected!.id);
        if (idxP != -1) {
          selected = personal[idxP];
        } else {
          final idxS = shared.indexWhere((w) => w.id == selected!.id);
          if (idxS != -1) {
            selected = shared[idxS];
          } else {
            if (personal.isNotEmpty) {
              selected = personal[0];
            } else if (shared.isNotEmpty) {
              selected = shared[0];
            } else {
              selected = null;
            }
          }
        }
      }
      return _WalletsResult(
        personal: personal,
        shared: shared,
        selected: selected,
      );
    }
    return _WalletsResult(personal: const [], shared: const [], selected: null);
  }

  Future<List<ExpenseEntity>> _fetchExpensesDataHelper(String walletId) async {
    final response = await _client.dio.get(
      '/expenses',
      queryParameters: {'walletId': walletId, 'timeframe': 'all', 'limit': 500},
    );
    if (response.data != null && response.data['success'] == true) {
      final list = response.data['data'] as List;
      return list.map((item) => ExpenseEntity.fromJson(item as Map)).toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>?> _fetchCompareDataHelper(String walletId) async {
    final response = await _client.dio.get(
      '/analytics/compare',
      queryParameters: {'walletId': walletId, 'months': 4},
    );
    if (response.data != null && response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchBreakdownDataHelper(
    String walletId,
  ) async {
    final response = await _client.dio.get(
      '/analytics/breakdown',
      queryParameters: {'walletId': walletId, 'timeframe': 'monthly'},
    );
    if (response.data != null && response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    }
    return null;
  }

  Future<List<BillReminderEntity>> _fetchRemindersDataHelper(
    String walletId,
  ) async {
    final response = await _client.dio.get(
      '/reminders',
      queryParameters: {'walletId': walletId},
    );
    if (response.data != null && response.data['success'] == true) {
      final list = response.data['data'] as List;
      return list
          .map((item) => BillReminderEntity.fromJson(item as Map))
          .toList();
    }
    return const [];
  }

  Future<List<ExpenseCategory>> _fetchCategoriesHelper() async {
    final response = await _client.dio.get('/categories');
    if (response.data != null && response.data['success'] == true) {
      final list = response.data['data'] as List;
      return list.map((item) => ExpenseCategory.fromJson(item as Map)).toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> _fetchSharedGroupsHelper() async {
    final response = await _client.dio.get('/sharing/groups');
    if (response.data != null && response.data['success'] == true) {
      final data = response.data['data'];
      return {
        'groups': data['groups'] as List? ?? [],
        'pendingInvites': data['pendingInvites'] as List? ?? [],
      };
    }
    return const {'groups': [], 'pendingInvites': []};
  }

  void _backgroundRefreshAfterMutation(Emitter<DashboardState> emit) {
    final wallet = state.selectedWallet;
    if (wallet == null) return;

    Future.wait([
          _fetchCompareDataHelper(wallet.id),
          _fetchBreakdownDataHelper(wallet.id),
          _fetchWalletsHelper(wallet),
        ])
        .then((results) {
          final compare = results[0] as Map<String, dynamic>?;
          final breakdown = results[1] as Map<String, dynamic>?;
          final walletsResult = results[2] as _WalletsResult;

          add(
            _DashboardBackgroundDataLoaded(
              compare: compare,
              breakdown: breakdown,
              personal: walletsResult.personal,
              shared: walletsResult.shared,
              selected: walletsResult.selected,
            ),
          );
        })
        .catchError((e) {
          debugPrint('DashboardBloc: Background refresh failed ($e)');
        });
  }

  // Internal event handler for background loading to bypass on/emit limitations
  void _onBackgroundDataLoaded(
    _DashboardBackgroundDataLoaded event,
    Emitter<DashboardState> emit,
  ) {
    emit(
      state.copyWith(
        compareData: event.compare,
        breakdownData: event.breakdown,
        personalWallets: event.personal,
        sharedWallets: event.shared,
        selectedWallet: event.selected,
      ),
    );
  }

  void _onSecondaryDataLoaded(
    _DashboardSecondaryDataLoaded event,
    Emitter<DashboardState> emit,
  ) {
    emit(
      state.copyWith(
        compareData: event.compare,
        breakdownData: event.breakdown,
        categories: event.categories,
        sharedGroups: event.sharedGroups,
        pendingInvites: event.pendingInvites,
        isLoadingAnalytics: false,
      ),
    );
  }

  void _loadSecondaryData(String? walletId) {
    if (walletId != null) {
      Future.wait([
            _fetchCompareDataHelper(walletId),
            _fetchBreakdownDataHelper(walletId),
            _fetchCategoriesHelper(),
            _fetchSharedGroupsHelper(),
          ])
          .then((results) {
            if (state.selectedWallet?.id == walletId) {
              add(
                _DashboardSecondaryDataLoaded(
                  compare: results[0] as Map<String, dynamic>?,
                  breakdown: results[1] as Map<String, dynamic>?,
                  categories: results[2] as List<ExpenseCategory>,
                  sharedGroups: (results[3] as Map)['groups'] as List,
                  pendingInvites: (results[3] as Map)['pendingInvites'] as List,
                ),
              );
            }
          })
          .catchError((e) {
            debugPrint('DashboardBloc: Secondary background fetch failed ($e)');
          });
    } else {
      Future.wait([_fetchCategoriesHelper(), _fetchSharedGroupsHelper()])
          .then((results) {
            if (state.selectedWallet == null) {
              add(
                _DashboardSecondaryDataLoaded(
                  compare: null,
                  breakdown: null,
                  categories: results[0] as List<ExpenseCategory>,
                  sharedGroups: (results[1] as Map)['groups'] as List,
                  pendingInvites: (results[1] as Map)['pendingInvites'] as List,
                ),
              );
            }
          })
          .catchError((e) {
            debugPrint('DashboardBloc: Secondary background fetch failed ($e)');
          });
    }
  }

  void _loadSecondaryWalletData(String walletId) {
    Future.wait([
          _fetchCompareDataHelper(walletId),
          _fetchBreakdownDataHelper(walletId),
        ])
        .then((results) {
          if (state.selectedWallet?.id == walletId) {
            add(
              _DashboardSecondaryDataLoaded(
                compare: results[0],
                breakdown: results[1],
                categories: state.categories,
                sharedGroups: state.sharedGroups,
                pendingInvites: state.pendingInvites,
              ),
            );
          }
        })
        .catchError((e) {
          debugPrint('DashboardBloc: Secondary wallet fetch failed ($e)');
        });
  }

  WalletEntity _copyWallet(
    WalletEntity w, {
    double? dailyBudget,
    double? monthlyBudget,
    String? currency,
    List<CategoryBudgetEntity>? categoryBudgets,
  }) {
    return WalletEntity(
      id: w.id,
      name: w.name,
      type: w.type,
      currency: currency ?? w.currency,
      dailyBudget: dailyBudget ?? w.dailyBudget,
      monthlyBudget: monthlyBudget ?? w.monthlyBudget,
      groupMembers: w.groupMembers,
      categoryBudgets: categoryBudgets ?? w.categoryBudgets,
    );
  }

  void _updateLocalWalletInState(
    WalletEntity updated,
    Emitter<DashboardState> emit,
  ) {
    WalletEntity? selected = state.selectedWallet;
    if (selected?.id == updated.id) {
      selected = updated;
    }

    final personal = List<WalletEntity>.from(state.personalWallets);
    final idxP = personal.indexWhere((w) => w.id == updated.id);
    if (idxP != -1) {
      personal[idxP] = updated;
    }

    final shared = List<WalletEntity>.from(state.sharedWallets);
    final idxS = shared.indexWhere((w) => w.id == updated.id);
    if (idxS != -1) {
      shared[idxS] = updated;
    }

    emit(
      state.copyWith(
        personalWallets: personal,
        sharedWallets: shared,
        selectedWallet: selected,
      ),
    );
  }
}

class _WalletsResult {
  final List<WalletEntity> personal;
  final List<WalletEntity> shared;
  final WalletEntity? selected;

  const _WalletsResult({
    required this.personal,
    required this.shared,
    required this.selected,
  });
}

// Internal event to handle asynchronous background loads without violating BLoC guidelines
class _DashboardBackgroundDataLoaded extends DashboardEvent {
  final Map<String, dynamic>? compare;
  final Map<String, dynamic>? breakdown;
  final List<WalletEntity> personal;
  final List<WalletEntity> shared;
  final WalletEntity? selected;

  const _DashboardBackgroundDataLoaded({
    this.compare,
    this.breakdown,
    required this.personal,
    required this.shared,
    this.selected,
  });
}

class _DashboardSecondaryDataLoaded extends DashboardEvent {
  final Map<String, dynamic>? compare;
  final Map<String, dynamic>? breakdown;
  final List<ExpenseCategory> categories;
  final List<dynamic> sharedGroups;
  final List<dynamic> pendingInvites;

  const _DashboardSecondaryDataLoaded({
    this.compare,
    this.breakdown,
    required this.categories,
    required this.sharedGroups,
    required this.pendingInvites,
  });
}
