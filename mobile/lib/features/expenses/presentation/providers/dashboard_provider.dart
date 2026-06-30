import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/bill_reminder.dart';

class DashboardProvider extends ChangeNotifier {
  final DioClient _client = DioClient();

  String _activeTimeframe = 'monthly'; // 'daily' | 'monthly' | 'yearly'
  bool _isLoading = false;

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
    _fetchData();
    fetchSharedGroups();
    fetchCategories();
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
    _fetchExpensesOnly();
  }

  /// Change active timeframe ('daily' | 'monthly' | 'yearly')
  void setTimeframe(String timeframe) {
    _activeTimeframe = timeframe;
    notifyListeners();
    _fetchExpensesOnly();
  }

  /// Fetch expenses only for current selected wallet
  Future<void> _fetchExpensesOnly() async {
    _isLoading = true;
    notifyListeners();
    try {
      final wallet = _selectedWallet;
      if (wallet != null) {
        final response = await _client.dio.get(
          '/expenses',
          queryParameters: {'walletId': wallet.id},
        );

        if (response.data != null && response.data['success'] == true) {
          final list = response.data['data'] as List;
          _expenses = list
              .map((item) => ExpenseEntity.fromJson(item as Map))
              .toList();
        } else {
          _expenses = [];
        }

        // Also fetch analytics
        await _fetchAnalyticsOnly();
        // Also fetch reminders
        await fetchReminders();
      } else {
        _expenses = [];
        _compareData = null;
        _breakdownData = null;
        _reminders = [];
      }
    } catch (e) {
      debugPrint('DashboardProvider: Fetch expenses failed ($e)');
      _expenses = [];
      _compareData = null;
      _breakdownData = null;
      _reminders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Public refresh method for UI pull-to-refresh
  Future<void> refreshData() async {
    await _fetchData();
    await fetchSharedGroups();
  }

  /// Fetch wallets and expenses dynamically from the backend.
  Future<void> _fetchData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch Wallets
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

      // 2. Fetch Expenses for the active wallet
      final wallet = _selectedWallet;
      if (wallet != null) {
        final response = await _client.dio.get(
          '/expenses',
          queryParameters: {'walletId': wallet.id},
        );

        if (response.data != null && response.data['success'] == true) {
          final list = response.data['data'] as List;
          _expenses = list
              .map((item) => ExpenseEntity.fromJson(item as Map))
              .toList();
        } else {
          _expenses = [];
        }

        // Also fetch analytics
        await _fetchAnalyticsOnly();
        // Also fetch reminders
        await fetchReminders();
      } else {
        _expenses = [];
        _compareData = null;
        _breakdownData = null;
        _reminders = [];
      }
    } catch (e) {
      debugPrint('DashboardProvider: Live fetch failed ($e)');
      _expenses = [];
      _compareData = null;
      _breakdownData = null;
      _reminders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Private helper to fetch analytics data from backend
  Future<void> _fetchAnalyticsOnly() async {
    final wallet = _selectedWallet;
    if (wallet == null) return;

    try {
      // 1. Fetch monthly comparison (last 4 months)
      final compareRes = await _client.dio.get(
        '/analytics/compare',
        queryParameters: {
          'walletId': wallet.id,
          'months': 4,
        },
      );
      if (compareRes.data != null && compareRes.data['success'] == true) {
        _compareData = compareRes.data['data'] as Map<String, dynamic>;
      } else {
        _compareData = null;
      }

      // 2. Fetch category breakdown
      final breakdownRes = await _client.dio.get(
        '/analytics/breakdown',
        queryParameters: {
          'walletId': wallet.id,
          'timeframe': 'monthly',
        },
      );
      if (breakdownRes.data != null && breakdownRes.data['success'] == true) {
        _breakdownData = breakdownRes.data['data'] as Map<String, dynamic>;
      } else {
        _breakdownData = null;
      }
    } catch (e) {
      debugPrint('DashboardProvider: Fetch analytics failed ($e)');
      _compareData = null;
      _breakdownData = null;
    }
  }

  /// Public method to manually fetch/refresh analytics
  Future<void> fetchAnalytics() async {
    _isLoading = true;
    notifyListeners();
    await _fetchAnalyticsOnly();
    _isLoading = false;
    notifyListeners();
  }

  /// Fetch categories from the backend.
  Future<void> fetchCategories() async {
    try {
      final response = await _client.dio.get('/categories');
      if (response.data != null && response.data['success'] == true) {
        final list = response.data['data'] as List;
        _categories = list
            .map((item) => ExpenseCategory.fromJson(item as Map))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to fetch categories ($e)');
      _categories = [];
      notifyListeners();
    }
  }

  /// Add a new custom category.
  Future<bool> addCategory(String name, String icon, String color) async {
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
        await fetchCategories();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('DashboardProvider: Failed to add category ($e)');
      return false;
    }
  }

  /// Update an existing custom category.
  Future<bool> updateCategory(String id, String name, String icon, String color) async {
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
        await fetchCategories();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('DashboardProvider: Failed to update category ($e)');
      return false;
    }
  }

  /// Delete a custom category.
  Future<bool> deleteCategory(String id) async {
    try {
      final response = await _client.dio.delete('/categories/$id');
      if (response.data != null && response.data['success'] == true) {
        await fetchCategories();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('DashboardProvider: Failed to delete category ($e)');
      return false;
    }
  }

  /// Add a new expense.
  Future<bool> addExpense(ExpenseEntity expense) async {
    try {
      final wallet = activeWallet;
      if (wallet != null) {
        // Prepare request body
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
          await _fetchData(); // Refresh list to get accurate database data
          return true;
        }
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to add live expense ($e)');
    }
    return false;
  }

  /// Delete an expense.
  Future<bool> deleteExpense(String id) async {
    try {
      final wallet = activeWallet;
      if (wallet != null) {
        final response = await _client.dio.delete(
          '/expenses/$id',
          queryParameters: {'walletId': wallet.id},
        );

        if (response.data != null && response.data['success'] == true) {
          await _fetchData(); // Refresh list
          return true;
        }
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to delete live expense ($e)');
    }
    return false;
  }

  /// Update daily budget for the active wallet
  Future<bool> updateDailyBudget(double budget) async {
    try {
      final wallet = activeWallet;
      if (wallet != null) {
        final response = await _client.dio.patch(
          '/wallets/${wallet.id}',
          data: {'dailyBudget': budget},
        );
        if (response.data != null && response.data['success'] == true) {
          await _fetchData(); // Refresh wallets to get updated daily budget
          return true;
        }
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to update daily budget ($e)');
    }
    return false;
  }

  /// Update currency for the active wallet
  Future<bool> updateWalletCurrency(String currency) async {
    try {
      final wallet = activeWallet;
      if (wallet != null) {
        final response = await _client.dio.patch(
          '/wallets/${wallet.id}',
          data: {'currency': currency},
        );
        if (response.data != null && response.data['success'] == true) {
          await _fetchData(); // Refresh wallets to get updated currency
          return true;
        }
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to update wallet currency ($e)');
    }
    return false;
  }

  /// Fetch active shared groups and pending invitations
  Future<void> fetchSharedGroups() async {
    try {
      final response = await _client.dio.get('/sharing/groups');
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        _sharedGroups = data['groups'] as List? ?? [];
        _pendingInvites = data['pendingInvites'] as List? ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to fetch shared groups ($e)');
      _sharedGroups = [];
      _pendingInvites = [];
      notifyListeners();
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
        await fetchSharedGroups();
        await _fetchData(); // Refresh wallets/shared state
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
        await fetchSharedGroups();
        await _fetchData(); // Refresh wallets/shared state
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
        await fetchSharedGroups();
        await _fetchData();
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
        await fetchSharedGroups();
        await _fetchData();
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
        await fetchSharedGroups();
        await _fetchData();
        return true;
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to archive group ($e)');
    }
    return false;
  }

  // Helper properties to calculate totals
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

  /// Fetch reminders for the active wallet
  Future<void> fetchReminders() async {
    final wallet = _selectedWallet;
    if (wallet == null) return;
    try {
      final response = await _client.dio.get(
        '/reminders',
        queryParameters: {'walletId': wallet.id},
      );
      if (response.data != null && response.data['success'] == true) {
        final list = response.data['data'] as List;
        _reminders = list
            .map((item) => BillReminderEntity.fromJson(item as Map))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to fetch reminders ($e)');
      _reminders = [];
      notifyListeners();
    }
  }

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
    try {
      final wallet = activeWallet;
      if (wallet == null) return false;
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
        await fetchReminders();
        return true;
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to add reminder ($e)');
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
    try {
      final wallet = activeWallet;
      if (wallet == null) return false;
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
        await fetchReminders();
        return true;
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to update reminder ($e)');
    }
    return false;
  }

  /// Delete (cancel) a bill reminder
  Future<bool> deleteReminder(String id) async {
    try {
      final response = await _client.dio.delete('/reminders/$id');
      if (response.data != null && response.data['success'] == true) {
        await fetchReminders();
        return true;
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to delete reminder ($e)');
    }
    return false;
  }

  /// Pay a bill (logs an Expense under this bill reminder and refreshes data)
  Future<bool> payBill(BillReminderEntity reminder) async {
    try {
      final wallet = activeWallet;
      if (wallet == null) return false;

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
        await _fetchData();
        return true;
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to pay bill ($e)');
    }
    return false;
  }
}
