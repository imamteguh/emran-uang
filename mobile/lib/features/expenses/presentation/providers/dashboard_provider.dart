import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/wallet.dart';

class DashboardProvider extends ChangeNotifier {
  final DioClient _client = DioClient();

  bool _isSharedMode = false;
  String _activeTimeframe = 'monthly'; // 'daily' | 'monthly' | 'yearly'
  bool _isLoading = false;

  // Wallets
  WalletEntity? _personalWallet;
  WalletEntity? _sharedWallet;

  // Data lists
  List<ExpenseEntity> _expenses = [];
  List<ExpenseCategory> _categories = [];

  // Getters
  bool get isSharedMode => _isSharedMode;
  String get activeTimeframe => _activeTimeframe;
  bool get isLoading => _isLoading;
  List<ExpenseEntity> get expenses => _expenses;
  List<ExpenseCategory> get categories => _categories;

  WalletEntity? get activeWallet =>
      _isSharedMode ? _sharedWallet : _personalWallet;

  DashboardProvider() {
    _fetchData();
  }

  /// Toggle between Personal Wallet and Shared (Data Bersama) Wallet
  void toggleSharedMode(bool value) {
    _isSharedMode = value;
    notifyListeners();
    _fetchData();
  }

  /// Change active timeframe ('daily' | 'monthly' | 'yearly')
  void setTimeframe(String timeframe) {
    _activeTimeframe = timeframe;
    notifyListeners();
    _fetchData();
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
        if (personalList.isNotEmpty) {
          _personalWallet = WalletEntity.fromJson(personalList[0] as Map);
        } else {
          _personalWallet = null;
        }
        final sharedList = data['shared'] as List;
        if (sharedList.isNotEmpty) {
          _sharedWallet = WalletEntity.fromJson(sharedList[0] as Map);
        } else {
          _sharedWallet = null; // No active shared group wallet
        }
      }

      // 2. Fetch Expenses for the active wallet
      final wallet = activeWallet;
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
      } else {
        _expenses = [];
      }
    } catch (e) {
      debugPrint('DashboardProvider: Live fetch failed ($e)');
      _expenses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  /// Send sharing invite to target email
  Future<bool> sendInvite(String email, {String? groupName}) async {
    try {
      final response = await _client.dio.post(
        '/sharing/invite',
        data: {'email': email, 'groupName': ?groupName},
      );
      if (response.data != null && response.data['success'] == true) {
        await _fetchData(); // Refresh wallets/shared state
        return true;
      }
    } catch (e) {
      debugPrint('DashboardProvider: Failed to send invite ($e)');
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
    if (_expenses.isEmpty) return '❓';
    try {
      final topCat = topCategory;
      final match = _expenses.firstWhere((e) => e.category.name == topCat);
      return match.category.icon;
    } catch (_) {
      return '❓';
    }
  }
}
