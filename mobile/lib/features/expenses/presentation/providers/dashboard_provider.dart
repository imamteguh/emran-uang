import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/bill_reminder.dart';

class DashboardProvider extends ChangeNotifier {
  final DioClient _client = DioClient();

  String _activeTimeframe = 'monthly'; // 'daily' | 'monthly' | 'yearly'
  bool _isLoading = false;
  bool _isInitialLoad = true; // true until first data arrives

  // Wallets
  List<WalletEntity> _personalWallets = [];
  List<WalletEntity> _sharedWallets = [];
  WalletEntity? _selectedWallet;

  // Data lists
  List<ExpenseEntity> _expenses = [];
  List<ExpenseCategory> _categories = [];
  List<dynamic> _sharedGroups = [];
  List<dynamic> _pendingInvites = [];
  List<BillReminderEntity> _reminders = [];

  // Analytics
  Map<String, dynamic>? _compareData;
  Map<String, dynamic>? _breakdownData;

  // Getters
  bool get isSharedMode => _selectedWallet?.type == WalletType.shared;
  String get activeTimeframe => _activeTimeframe;
  bool get isLoading => _isLoading;
  bool get isInitialLoad => _isInitialLoad;
  List<ExpenseEntity> get expenses => _expenses;
  List<ExpenseCategory> get categories => _categories;
  List<dynamic> get sharedGroups => _sharedGroups;
  List<dynamic> get pendingInvites => _pendingInvites;
  List<BillReminderEntity> get reminders => _reminders;
  Map<String, dynamic>? get compareData => _compareData;
  Map<String, dynamic>? get breakdownData => _breakdownData;

  List<WalletEntity> get personalWallets => _personalWallets;
  List<WalletEntity> get sharedWallets => _sharedWallets;
  List<WalletEntity> get allWallets => [..._personalWallets, ..._sharedWallets];

  WalletEntity? get activeWallet => _selectedWallet;

  DashboardProvider() {
    _initializeData();
  }

  /// Initial data load — fetches wallets first, then everything else in parallel
  Future<void> _initializeData() async {
    _isLoading = true;
    _isInitialLoad = true;
    notifyListeners();

    try {
      // Step 1: Fetch wallets first (we need walletId for other requests)
      await _fetchWallets();

      // Step 2: Fetch everything else in parallel
      final wallet = _selectedWallet;
      if (wallet != null) {
        await Future.wait([
          _fetchExpensesData(wallet.id),
          _fetchCompareData(wallet.id),
          _fetchBreakdownData(wallet.id),
          _fetchRemindersData(wallet.id),
          fetchCategories(),
          fetchSharedGroups(),
        ]);
      } else {
        // No wallet — still fetch categories and shared groups
        await Future.wait([
          fetchCategories(),
          fetchSharedGroups(),
        ]);
      }
    } catch (e) {
      debugPrint('DashboardProvider: Initialize failed ($e)');
    } finally {
      _isLoading = false;
      _isInitialLoad = false;
      notifyListeners();
    }
  }

  /// Toggle between Personal Wallet and Shared (Data Bersama) Wallet (compatibility wrapper)
  void toggleSharedMode(bool value) {
    if (value) {
      if (_sharedWallets.isNotEmpty) {
        selectWallet(_sharedWallets[0]);
      }
    } else {
      if (_personalWallets.isNotEmpty) {
        selectWallet(_personalWallets[0]);
      }
    }
  }

  /// Select active wallet and fetch its expenses
  void selectWallet(WalletEntity wallet) {
    _selectedWallet = wallet;
    notifyListeners();
    _fetchWalletData();
  }

  /// Change active timeframe ('daily' | 'monthly' | 'yearly')
  void setTimeframe(String timeframe) {
    _activeTimeframe = timeframe;
    notifyListeners();
    _fetchWalletData();
  }

  /// Fetch all data for the currently selected wallet — IN PARALLEL
  Future<void> _fetchWalletData() async {
    final wallet = _selectedWallet;
    if (wallet == null) {
      _expenses = [];
      _compareData = null;
      _breakdownData = null;
      _reminders = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _fetchExpensesData(wallet.id),
        _fetchCompareData(wallet.id),
        _fetchBreakdownData(wallet.id),
        _fetchRemindersData(wallet.id),
      ]);
    } catch (e) {
      debugPrint('DashboardProvider: Fetch wallet data failed ($e)');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Individual Data Fetchers (no loading state, no notifyListeners) ──────

  /// Fetch wallets and determine selected wallet
  Future<void> _fetchWallets() async {
    try {
      final walletsRes = await _client.dio.get('/wallets');
      if (walletsRes.data != null && walletsRes.data['success'] == true) {
        final data = walletsRes.data['data'];
        final personalList = data['personal'] as List;
        _personalWallets = personalList
            .map((item) => WalletEntity.fromJson(item as Map))
            .toList();

        final sharedList = data['shared'] as List;
        _sharedWallets = sharedList
            .map((item) => WalletEntity.fromJson(item as Map))
            .toList();

        // Initialize or update selected wallet
        if (_selectedWallet == null) {
          if (_personalWallets.isNotEmpty) {
            _selectedWallet = _personalWallets[0];
          } else if (_sharedWallets.isNotEmpty) {
            _selectedWallet = _sharedWallets[0];
          }
        } else {
          final idxP = _personalWallets.indexWhere((w) => w.id == _selectedWallet!.id);
          if (idxP != -1) {
            _selectedWallet = _personalWallets[idxP];
          } else {
            final idxS = _sharedWallets.indexWhere((w) => w.id == _selectedWallet!.id);
            if (idxS != -1) {
              _selectedWallet = _sharedWallets[idxS];
            } else {
              if (_personalWallets.isNotEmpty) {
                _selectedWallet = _personalWallets[0];
              } else if (_sharedWallets.isNotEmpty) {
                _selectedWallet = _sharedWallets[0];
              } else {
                _selectedWallet = null;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('DashboardProvider: Fetch wallets failed ($e)');
    }
  }

  /// Fetch expenses for a specific wallet (no loading state management)
  Future<void> _fetchExpensesData(String walletId) async {
    try {
      final response = await _client.dio.get(
        '/expenses',
        queryParameters: {'walletId': walletId},
      );
      if (response.data != null && response.data['success'] == true) {
        final list = response.data['data'] as List;
        _expenses = list
            .map((item) => ExpenseEntity.fromJson(item as Map))
            .toList();
      } else {
        _expenses = [];
      }
    } catch (e) {
      debugPrint('DashboardProvider: Fetch expenses failed ($e)');
      _expenses = [];
    }
  }

  /// Fetch compare analytics for a specific wallet
  Future<void> _fetchCompareData(String walletId) async {
    try {
      final compareRes = await _client.dio.get(
        '/analytics/compare',
        queryParameters: {
          'walletId': walletId,
          'months': 4,
        },
      );
      if (compareRes.data != null && compareRes.data['success'] == true) {
        _compareData = compareRes.data['data'] as Map<String, dynamic>;
      } else {
        _compareData = null;
      }
    } catch (e) {
      debugPrint('DashboardProvider: Fetch compare failed ($e)');
      _compareData = null;
    }
  }

  /// Fetch breakdown analytics for a specific wallet
  Future<void> _fetchBreakdownData(String walletId) async {
    try {
      final breakdownRes = await _client.dio.get(
        '/analytics/breakdown',
        queryParameters: {
          'walletId': walletId,
          'timeframe': 'monthly',
        },
      );
      if (breakdownRes.data != null && breakdownRes.data['success'] == true) {
        _breakdownData = breakdownRes.data['data'] as Map<String, dynamic>;
      } else {
        _breakdownData = null;
      }
    } catch (e) {
      debugPrint('DashboardProvider: Fetch breakdown failed ($e)');
      _breakdownData = null;
    }
  }

  /// Fetch reminders for a specific wallet
  Future<void> _fetchRemindersData(String walletId) async {
    try {
      final response = await _client.dio.get(
        '/reminders',
        queryParameters: {'walletId': walletId},
      );
      if (response.data != null && response.data['success'] == true) {
        final list = response.data['data'] as List;
        _reminders = list
            .map((item) => BillReminderEntity.fromJson(item as Map))
            .toList();
      } else {
        _reminders = [];
      }
    } catch (e) {
      debugPrint('DashboardProvider: Fetch reminders failed ($e)');
      _reminders = [];
    }
  }

  // ─── Public Refresh Methods ───────────────────────────────────────────────

  /// Public refresh method for UI pull-to-refresh
  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _fetchWallets();
      final wallet = _selectedWallet;
      if (wallet != null) {
        await Future.wait([
          _fetchExpensesData(wallet.id),
          _fetchCompareData(wallet.id),
          _fetchBreakdownData(wallet.id),
          _fetchRemindersData(wallet.id),
          fetchSharedGroups(),
          fetchCategories(),
        ]);
      } else {
        await Future.wait([
          fetchSharedGroups(),
          fetchCategories(),
        ]);
      }
    } catch (e) {
      debugPrint('DashboardProvider: Refresh failed ($e)');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Public method to manually fetch/refresh analytics
  Future<void> fetchAnalytics() async {
    final wallet = _selectedWallet;
    if (wallet == null) return;

    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _fetchCompareData(wallet.id),
      _fetchBreakdownData(wallet.id),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch reminders (public wrapper)
  Future<void> fetchReminders() async {
    final wallet = _selectedWallet;
    if (wallet == null) return;
    await _fetchRemindersData(wallet.id);
    notifyListeners();
  }

  // ─── Categories ───────────────────────────────────────────────────────────

  /// Fetch categories from the backend.
  Future<void> fetchCategories() async {
    try {
      final response = await _client.dio.get('/categories');
      if (response.data != null && response.data['success'] == true) {
        final list = response.data['data'] as List;
        _categories = list
            .map((item) => ExpenseCategory.fromJson(item as Map))
            .toList();
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to fetch categories ($e)');
      _categories = [];
    }
  }

  /// Add a new custom category.
  Future<bool> addCategory(String name, String icon, String color) async {
    final tempId = 'temp_cat_${DateTime.now().millisecondsSinceEpoch}';
    final newCategory = ExpenseCategory(
      id: tempId,
      name: name,
      icon: icon,
      color: color,
      isDefault: false,
    );

    // 1. Optimistic insert
    _categories.add(newCategory);
    notifyListeners();

    try {
      final response = await _client.dio.post(
        '/categories',
        data: {
          'name': name,
          'icon': icon,
          'color': color,
        },
      );
      if (response.data != null && response.data['success'] == true) {
        // 2. Fetch fresh categories in background to get real ID
        await fetchCategories();
        notifyListeners();
        return true;
      } else {
        // 3. Rollback
        _categories.removeWhere((c) => c.id == tempId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to add category ($e)');
      // Rollback
      _categories.removeWhere((c) => c.id == tempId);
      notifyListeners();
    }
    return false;
  }

  /// Update an existing custom category.
  Future<bool> updateCategory(String id, String name, String icon, String color) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) return false;
    final backup = _categories[index];

    // 1. Optimistic update
    _categories[index] = ExpenseCategory(
      id: id,
      name: name,
      icon: icon,
      color: color,
      isDefault: backup.isDefault,
      userId: backup.userId,
    );
    notifyListeners();

    try {
      final response = await _client.dio.put(
        '/categories/$id',
        data: {
          'name': name,
          'icon': icon,
          'color': color,
        },
      );
      if (response.data != null && response.data['success'] == true) {
        // Fetch fresh in background
        await fetchCategories();
        notifyListeners();
        return true;
      } else {
        // Rollback
        _categories[index] = backup;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to update category ($e)');
      _categories[index] = backup;
      notifyListeners();
    }
    return false;
  }

  /// Delete a custom category.
  Future<bool> deleteCategory(String id) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) return false;
    final backup = _categories[index];

    // 1. Optimistic delete
    _categories.removeAt(index);
    notifyListeners();

    try {
      final response = await _client.dio.delete('/categories/$id');
      if (response.data != null && response.data['success'] == true) {
        // Fetch fresh in background
        await fetchCategories();
        notifyListeners();
        return true;
      } else {
        // Rollback
        _categories.insert(index, backup);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to delete category ($e)');
      _categories.insert(index, backup);
      notifyListeners();
    }
    return false;
  }

  // ─── Expenses (Optimistic Updates) ────────────────────────────────────────

  /// Add a new expense with optimistic update.
  Future<bool> addExpense(ExpenseEntity expense) async {
    try {
      final wallet = activeWallet;
      if (wallet == null) return false;

      // 1. Optimistic: insert into local list immediately
      _expenses.insert(0, expense);
      notifyListeners(); // UI updates instantly

      // 2. Send to server
      final body = {
        'amount': expense.amount,
        'description': expense.description,
        'type': expense.type == ExpenseType.routine
            ? 'ROUTINE'
            : 'NON_ROUTINE',
        'categoryId': expense.category.id,
        'walletId': wallet.id,
        'date': expense.date.toUtc().toIso8601String(),
      };

      final response = await _client.dio.post('/expenses', data: body);
      if (response.data != null && response.data['success'] == true) {
        // 3. Replace optimistic entry with real server data
        final serverExpense = ExpenseEntity.fromJson(
          response.data['data'] as Map,
        );
        final optimisticIndex = _expenses.indexWhere((e) => e.id == expense.id);
        if (optimisticIndex >= 0) {
          _expenses[optimisticIndex] = serverExpense;
        }
        notifyListeners();

        // 4. Background refresh: update analytics & wallet balances
        _backgroundRefreshAfterMutation();
        return true;
      } else {
        // Server rejected — rollback
        _expenses.removeWhere((e) => e.id == expense.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to add expense ($e)');
      // Rollback on error
      _expenses.removeWhere((e) => e.id == expense.id);
      notifyListeners();
    }
    return false;
  }

  /// Delete an expense with optimistic update.
  Future<bool> deleteExpense(String id) async {
    try {
      final wallet = activeWallet;
      if (wallet == null) return false;

      // 1. Optimistic: remove from local list immediately
      final index = _expenses.indexWhere((e) => e.id == id);
      final ExpenseEntity? backup = index >= 0 ? _expenses[index] : null;
      if (index >= 0) {
        _expenses.removeAt(index);
        notifyListeners(); // UI updates instantly
      }

      // 2. Send delete to server
      final response = await _client.dio.delete(
        '/expenses/$id',
        queryParameters: {'walletId': wallet.id},
      );

      if (response.data != null && response.data['success'] == true) {
        // 3. Background refresh: update analytics & wallet balances
        _backgroundRefreshAfterMutation();
        return true;
      } else {
        // Server rejected — rollback
        if (backup != null && index >= 0) {
          _expenses.insert(index.clamp(0, _expenses.length), backup);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to delete expense ($e)');
    }
    return false;
  }

  /// Background refresh of analytics and wallet data after add/delete
  void _backgroundRefreshAfterMutation() {
    final wallet = _selectedWallet;
    if (wallet == null) return;

    // Fire-and-forget: refresh analytics + wallets in background
    Future.wait([
      _fetchCompareData(wallet.id),
      _fetchBreakdownData(wallet.id),
      _fetchWallets(),
    ]).then((_) {
      notifyListeners();
    }).catchError((e) {
      debugPrint('DashboardProvider: Background refresh failed ($e)');
    });
  }

  WalletEntity _copyWallet(WalletEntity w, {double? dailyBudget, String? currency}) {
    return WalletEntity(
      id: w.id,
      name: w.name,
      type: w.type,
      currency: currency ?? w.currency,
      dailyBudget: dailyBudget ?? w.dailyBudget,
      groupMembers: w.groupMembers,
    );
  }

  void _updateLocalWallet(WalletEntity updated) {
    if (_selectedWallet?.id == updated.id) {
      _selectedWallet = updated;
    }
    final idxP = _personalWallets.indexWhere((w) => w.id == updated.id);
    if (idxP != -1) {
      _personalWallets[idxP] = updated;
    }
    final idxS = _sharedWallets.indexWhere((w) => w.id == updated.id);
    if (idxS != -1) {
      _sharedWallets[idxS] = updated;
    }
  }

  /// Update daily budget for the active wallet
  Future<bool> updateDailyBudget(double budget) async {
    final wallet = activeWallet;
    if (wallet == null) return false;
    final backup = wallet;

    // 1. Optimistic update
    final updated = _copyWallet(wallet, dailyBudget: budget);
    _updateLocalWallet(updated);
    notifyListeners();

    try {
      final response = await _client.dio.patch(
        '/wallets/${wallet.id}',
        data: {'dailyBudget': budget},
      );
      if (response.data != null && response.data['success'] == true) {
        await _fetchWallets();
        notifyListeners();
        return true;
      } else {
        // Rollback
        _updateLocalWallet(backup);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to update daily budget ($e)');
      _updateLocalWallet(backup);
      notifyListeners();
    }
    return false;
  }

  /// Update currency for the active wallet
  Future<bool> updateWalletCurrency(String currency) async {
    final wallet = activeWallet;
    if (wallet == null) return false;
    final backup = wallet;

    // 1. Optimistic update
    final updated = _copyWallet(wallet, currency: currency);
    _updateLocalWallet(updated);
    notifyListeners();

    try {
      final response = await _client.dio.patch(
        '/wallets/${wallet.id}',
        data: {'currency': currency},
      );
      if (response.data != null && response.data['success'] == true) {
        await _fetchWallets();
        notifyListeners();
        return true;
      } else {
        // Rollback
        _updateLocalWallet(backup);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to update wallet currency ($e)');
      _updateLocalWallet(backup);
      notifyListeners();
    }
    return false;
  }

  // ─── Shared Groups ────────────────────────────────────────────────────────

  /// Fetch active shared groups and pending invitations
  Future<void> fetchSharedGroups() async {
    try {
      final response = await _client.dio.get('/sharing/groups');
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        _sharedGroups = data['groups'] as List? ?? [];
        _pendingInvites = data['pendingInvites'] as List? ?? [];
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to fetch shared groups ($e)');
      _sharedGroups = [];
      _pendingInvites = [];
    }
  }

  /// Send sharing invite to target email
  Future<bool> sendInvite(String email, {String? groupName}) async {
    try {
      final response = await _client.dio.post(
        '/sharing/invite',
        data: {'email': email, 'groupName': groupName},
      );
      if (response.data != null && response.data['success'] == true) {
        await Future.wait([
          fetchSharedGroups(),
          _fetchWallets(),
        ]);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to send invite ($e)');
    }
    return false;
  }

  /// Accept an invitation
  Future<bool> acceptGroupInvite(String inviteId) async {
    try {
      final response = await _client.dio.post('/sharing/invite/$inviteId/accept');
      if (response.data != null && response.data['success'] == true) {
        await Future.wait([
          fetchSharedGroups(),
          _fetchWallets(),
        ]);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to accept invite ($e)');
    }
    return false;
  }

  /// Reject an invitation
  Future<bool> rejectGroupInvite(String inviteId) async {
    try {
      final response = await _client.dio.post('/sharing/invite/$inviteId/reject');
      if (response.data != null && response.data['success'] == true) {
        await Future.wait([
          fetchSharedGroups(),
          _fetchWallets(),
        ]);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to reject invite ($e)');
    }
    return false;
  }

  /// Leave a group
  Future<bool> leaveGroup(String groupId) async {
    try {
      final response = await _client.dio.post('/sharing/groups/$groupId/leave');
      if (response.data != null && response.data['success'] == true) {
        await Future.wait([
          fetchSharedGroups(),
          _fetchWallets(),
        ]);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to leave group ($e)');
    }
    return false;
  }

  /// Archive a group
  Future<bool> archiveGroup(String groupId) async {
    try {
      final response = await _client.dio.post('/sharing/groups/$groupId/archive');
      if (response.data != null && response.data['success'] == true) {
        await Future.wait([
          fetchSharedGroups(),
          _fetchWallets(),
        ]);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to archive group ($e)');
    }
    return false;
  }

  // ─── Computed Properties ──────────────────────────────────────────────────

  double get totalSpend {
    return _expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get routineSpend {
    return _expenses
        .where((item) => item.type == ExpenseType.routine)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get nonRoutineSpend {
    return _expenses
        .where((item) => item.type == ExpenseType.nonRoutine)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Dynamic calculations for summaries depending on timeframe
  double get todaySpend {
    final now = DateTime.now();
    return _expenses
        .where(
          (item) =>
              item.date.year == now.year &&
              item.date.month == now.month &&
              item.date.day == now.day,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get monthlySpend {
    final now = DateTime.now();
    return _expenses
        .where(
          (item) => item.date.year == now.year && item.date.month == now.month,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get yearlySpend {
    final now = DateTime.now();
    return _expenses
        .where((item) => item.date.year == now.year)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  String get topCategory {
    if (_expenses.isEmpty) return 'None';
    final Map<String, double> categorySums = {};
    for (var expense in _expenses) {
      final catName = expense.category.name;
      categorySums[catName] = (categorySums[catName] ?? 0.0) + expense.amount;
    }
    String topCat = 'None';
    double maxAmount = -1.0;
    categorySums.forEach((cat, amount) {
      if (amount > maxAmount) {
        maxAmount = amount;
        topCat = cat;
      }
    });
    return topCat;
  }

  String get topCategoryIcon {
    if (_expenses.isEmpty) return 'category';
    try {
      final topCat = topCategory;
      final match = _expenses.firstWhere((e) => e.category.name == topCat);
      return match.category.icon;
    } catch (_) {
      return 'category';
    }
  }

  // ─── Bill Reminders (Tagihan) ──────────────────────────────────────────────

  /// Add a new bill reminder
  Future<bool> addReminder({
    required String title,
    required double amount,
    required DateTime dueDate,
    required String periodicity,
    String? categoryId,
    required int notifyDaysBefore,
    required bool autoLogExpense,
  }) async {
    final wallet = activeWallet;
    if (wallet == null) return false;

    // Convert inputs to parsed types
    Periodicity parsedPeriodicity = Periodicity.monthly;
    switch (periodicity.toUpperCase()) {
      case 'DAILY': parsedPeriodicity = Periodicity.daily; break;
      case 'WEEKLY': parsedPeriodicity = Periodicity.weekly; break;
      case 'MONTHLY': parsedPeriodicity = Periodicity.monthly; break;
      case 'YEARLY': parsedPeriodicity = Periodicity.yearly; break;
    }

    final tempId = 'temp_rem_${DateTime.now().millisecondsSinceEpoch}';
    final categoryMatch = _categories.firstWhere((c) => c.id == categoryId, orElse: () => _categories.isNotEmpty ? _categories.first : ExpenseCategory(id: 'temp', name: 'Other', icon: '💰', color: '#4F46E5'));
    final reminderCategory = BillReminderCategory(
      id: categoryMatch.id,
      name: categoryMatch.name,
      icon: categoryMatch.icon,
      color: categoryMatch.color,
    );

    final newReminder = BillReminderEntity(
      id: tempId,
      title: title,
      amount: amount,
      dueDate: dueDate,
      periodicity: parsedPeriodicity,
      status: ReminderStatus.active,
      userId: 'user_1',
      walletId: wallet.id,
      categoryId: categoryId,
      category: reminderCategory,
      notifyDaysBefore: notifyDaysBefore,
      autoLogExpense: autoLogExpense,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      expenses: [],
    );

    // 1. Optimistic insert
    _reminders.add(newReminder);
    notifyListeners();

    try {
      final response = await _client.dio.post(
        '/reminders',
        data: {
          'title': title,
          'amount': amount,
          'dueDate': dueDate.toUtc().toIso8601String(),
          'periodicity': periodicity.toUpperCase(),
          'categoryId': categoryId,
          'walletId': wallet.id,
          'notifyDaysBefore': notifyDaysBefore,
          'autoLogExpense': autoLogExpense,
        },
      );
      if (response.data != null && response.data['success'] == true) {
        // Fetch fresh reminders in background to get real server IDs/timestamps
        await _fetchRemindersData(wallet.id);
        notifyListeners();
        return true;
      } else {
        // Rollback
        _reminders.removeWhere((r) => r.id == tempId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to add reminder ($e)');
      _reminders.removeWhere((r) => r.id == tempId);
      notifyListeners();
    }
    return false;
  }

  /// Update an existing bill reminder
  Future<bool> updateReminder({
    required String id,
    String? title,
    double? amount,
    DateTime? dueDate,
    String? periodicity,
    String? status,
    String? categoryId,
    int? notifyDaysBefore,
    bool? autoLogExpense,
  }) async {
    final wallet = activeWallet;
    if (wallet == null) return false;

    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return false;
    final backup = _reminders[index];

    // parse updated enum values
    Periodicity parsedPeriodicity = backup.periodicity;
    if (periodicity != null) {
      switch (periodicity.toUpperCase()) {
        case 'DAILY': parsedPeriodicity = Periodicity.daily; break;
        case 'WEEKLY': parsedPeriodicity = Periodicity.weekly; break;
        case 'MONTHLY': parsedPeriodicity = Periodicity.monthly; break;
        case 'YEARLY': parsedPeriodicity = Periodicity.yearly; break;
      }
    }

    ReminderStatus parsedStatus = backup.status;
    if (status != null) {
      switch (status.toUpperCase()) {
        case 'ACTIVE': parsedStatus = ReminderStatus.active; break;
        case 'SNOOZED': parsedStatus = ReminderStatus.snoozed; break;
        case 'COMPLETED': parsedStatus = ReminderStatus.completed; break;
        case 'CANCELLED': parsedStatus = ReminderStatus.cancelled; break;
      }
    }

    BillReminderCategory? reminderCategory = backup.category;
    if (categoryId != null) {
      final categoryMatch = _categories.firstWhere((c) => c.id == categoryId, orElse: () => _categories.first);
      reminderCategory = BillReminderCategory(
        id: categoryMatch.id,
        name: categoryMatch.name,
        icon: categoryMatch.icon,
        color: categoryMatch.color,
      );
    }

    final updated = BillReminderEntity(
      id: id,
      title: title ?? backup.title,
      amount: amount ?? backup.amount,
      dueDate: dueDate ?? backup.dueDate,
      periodicity: parsedPeriodicity,
      status: parsedStatus,
      userId: backup.userId,
      walletId: backup.walletId,
      categoryId: categoryId ?? backup.categoryId,
      category: reminderCategory,
      notifyDaysBefore: notifyDaysBefore ?? backup.notifyDaysBefore,
      autoLogExpense: autoLogExpense ?? backup.autoLogExpense,
      createdAt: backup.createdAt,
      updatedAt: DateTime.now(),
      expenses: backup.expenses,
      lastNotifiedAt: backup.lastNotifiedAt,
      lastTriggeredAt: backup.lastTriggeredAt,
    );

    // 1. Optimistic update
    _reminders[index] = updated;
    notifyListeners();

    try {
      final response = await _client.dio.put(
        '/reminders/$id',
        data: {
          'walletId': wallet.id,
          'title': ?title,
          'amount': ?amount,
          'dueDate': ?dueDate?.toUtc().toIso8601String(),
          'periodicity': ?periodicity?.toUpperCase(),
          'status': ?status?.toUpperCase(),
          'categoryId': categoryId,
          'notifyDaysBefore': ?notifyDaysBefore,
          'autoLogExpense': ?autoLogExpense,
        },
      );
      if (response.data != null && response.data['success'] == true) {
        await _fetchRemindersData(wallet.id);
        notifyListeners();
        return true;
      } else {
        // Rollback
        _reminders[index] = backup;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to update reminder ($e)');
      _reminders[index] = backup;
      notifyListeners();
    }
    return false;
  }

  /// Delete (cancel) a bill reminder
  Future<bool> deleteReminder(String id) async {
    final wallet = activeWallet;
    if (wallet == null) return false;

    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return false;
    final backup = _reminders[index];

    // 1. Optimistic delete
    _reminders.removeAt(index);
    notifyListeners();

    try {
      final response = await _client.dio.delete(
        '/reminders/$id',
        queryParameters: {'walletId': wallet.id},
      );
      if (response.data != null && response.data['success'] == true) {
        await _fetchRemindersData(wallet.id);
        notifyListeners();
        return true;
      } else {
        // Rollback
        _reminders.insert(index, backup);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to delete reminder ($e)');
      _reminders.insert(index, backup);
      notifyListeners();
    }
    return false;
  }

  /// Pay a bill (logs an Expense under this bill reminder and refreshes data)
  Future<bool> payBill(BillReminderEntity reminder) async {
    final wallet = activeWallet;
    if (wallet == null) return false;

    // 1. Create optimistic Expense
    final categoryMatch = _categories.firstWhere((c) => c.id == (reminder.categoryId ?? ''), orElse: () => _categories.isNotEmpty ? _categories.first : ExpenseCategory(id: 'temp', name: 'Other', icon: '💰', color: '#4F46E5'));
    final optimisticExpense = ExpenseEntity(
      id: 'temp_pay_${DateTime.now().millisecondsSinceEpoch}',
      amount: reminder.amount,
      description: 'Pembayaran: ${reminder.title}',
      date: DateTime.now(),
      type: ExpenseType.routine,
      userId: 'user_1',
      walletId: wallet.id,
      category: categoryMatch,
      creatorName: 'Me',
    );

    // 2. Create optimistic BillReminderExpense and add to the reminder
    final optBillExpense = BillReminderExpense(
      id: 'temp_bre_${DateTime.now().millisecondsSinceEpoch}',
      amount: reminder.amount,
      date: DateTime.now(),
    );

    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    BillReminderEntity? reminderBackup;
    if (index != -1) {
      reminderBackup = _reminders[index];
      final updatedExpenses = List<BillReminderExpense>.from(reminder.expenses)..add(optBillExpense);
      _reminders[index] = BillReminderEntity(
        id: reminder.id,
        title: reminder.title,
        amount: reminder.amount,
        dueDate: reminder.dueDate,
        periodicity: reminder.periodicity,
        status: reminder.status,
        userId: reminder.userId,
        walletId: reminder.walletId,
        categoryId: reminder.categoryId,
        category: reminder.category,
        notifyDaysBefore: reminder.notifyDaysBefore,
        autoLogExpense: reminder.autoLogExpense,
        createdAt: reminder.createdAt,
        updatedAt: reminder.updatedAt,
        expenses: updatedExpenses,
        lastNotifiedAt: reminder.lastNotifiedAt,
        lastTriggeredAt: reminder.lastTriggeredAt,
      );
    }

    // Insert optimistic expense
    _expenses.insert(0, optimisticExpense);
    notifyListeners();

    try {
      final body = {
        'amount': reminder.amount,
        'description': 'Pembayaran: ${reminder.title}',
        'type': 'ROUTINE',
        'categoryId': reminder.categoryId ?? (categories.isNotEmpty ? categories[0].id : null),
        'walletId': wallet.id,
        'date': DateTime.now().toUtc().toIso8601String(),
        'billReminderId': reminder.id,
      };

      final response = await _client.dio.post('/expenses', data: body);
      if (response.data != null && response.data['success'] == true) {
        // Background refresh to get exact server state
        _backgroundRefreshAfterMutation();
        await _fetchRemindersData(wallet.id);
        notifyListeners();
        return true;
      } else {
        // Rollback
        _expenses.removeWhere((e) => e.id == optimisticExpense.id);
        if (index != -1 && reminderBackup != null) {
          _reminders[index] = reminderBackup;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to pay bill ($e)');
      _expenses.removeWhere((e) => e.id == optimisticExpense.id);
      if (index != -1 && reminderBackup != null) {
        _reminders[index] = reminderBackup;
      }
      notifyListeners();
    }
    return false;
  }
}
