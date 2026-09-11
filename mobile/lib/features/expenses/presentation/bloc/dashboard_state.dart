import '../../domain/entities/expense.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/bill_reminder.dart';

enum DashboardStatus { initial, loading, success, failure }

class DashboardState {
  final String activeTimeframe;
  final bool isLoading;
  final bool isInitialLoad;

  final List<WalletEntity> personalWallets;
  final List<WalletEntity> sharedWallets;
  final WalletEntity? selectedWallet;

  final List<ExpenseEntity> expenses;
  final List<ExpenseCategory> categories;
  final List<dynamic> sharedGroups;
  final List<dynamic> pendingInvites;
  final List<BillReminderEntity> reminders;

  final Map<String, dynamic>? compareData;
  final Map<String, dynamic>? breakdownData;
  final bool isLoadingAnalytics;

  final String? errorMessage;
  final String? successMessage;
  final DashboardStatus status;

  const DashboardState({
    this.activeTimeframe = 'monthly',
    this.isLoading = false,
    this.isInitialLoad = true,
    this.personalWallets = const [],
    this.sharedWallets = const [],
    this.selectedWallet,
    this.expenses = const [],
    this.categories = const [],
    this.sharedGroups = const [],
    this.pendingInvites = const [],
    this.reminders = const [],
    this.compareData,
    this.breakdownData,
    this.isLoadingAnalytics = false,
    this.errorMessage,
    this.successMessage,
    this.status = DashboardStatus.initial,
  });

  bool get isSharedMode => selectedWallet?.type == WalletType.shared;

  List<ExpenseEntity> get todayExpenses {
    final now = DateTime.now();
    return expenses
        .where(
          (item) =>
              item.date.year == now.year &&
              item.date.month == now.month &&
              item.date.day == now.day,
        )
        .toList();
  }

  List<WalletEntity> get allWallets => [...personalWallets, ...sharedWallets];

  WalletEntity? get activeWallet => selectedWallet;

  // Computed Properties
  double get totalSpend {
    return expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get routineSpend {
    return expenses
        .where((item) => item.type == ExpenseType.routine)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get nonRoutineSpend {
    return expenses
        .where((item) => item.type == ExpenseType.nonRoutine)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get monthlyRoutineSpend {
    final now = DateTime.now();
    final fromExpenses = expenses
        .where(
          (item) =>
              item.type == ExpenseType.routine &&
              item.date.year == now.year &&
              item.date.month == now.month,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
    if (fromExpenses > 0 || expenses.isNotEmpty) return fromExpenses;

    final months = compareData?['months'] as List?;
    if (months != null && months.isNotEmpty) {
      final currentMonth = months[0] as Map<String, dynamic>?;
      final byType = currentMonth?['byType'] as List?;
      if (byType != null) {
        for (final t in byType) {
          if (t is Map && t['type'] == 'ROUTINE') {
            final val = t['total'];
            if (val is num) return val.toDouble();
            if (val is String) return double.tryParse(val) ?? 0.0;
          }
        }
      }
    }
    return 0.0;
  }

  double get monthlyNonRoutineSpend {
    final now = DateTime.now();
    final fromExpenses = expenses
        .where(
          (item) =>
              item.type == ExpenseType.nonRoutine &&
              item.date.year == now.year &&
              item.date.month == now.month,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
    if (fromExpenses > 0 || expenses.isNotEmpty) return fromExpenses;

    final months = compareData?['months'] as List?;
    if (months != null && months.isNotEmpty) {
      final currentMonth = months[0] as Map<String, dynamic>?;
      final byType = currentMonth?['byType'] as List?;
      if (byType != null) {
        for (final t in byType) {
          if (t is Map && t['type'] == 'NON_ROUTINE') {
            final val = t['total'];
            if (val is num) return val.toDouble();
            if (val is String) return double.tryParse(val) ?? 0.0;
          }
        }
      }
    }
    return 0.0;
  }

  int get monthlyRoutineCount {
    final now = DateTime.now();
    return expenses
        .where(
          (item) =>
              item.type == ExpenseType.routine &&
              item.date.year == now.year &&
              item.date.month == now.month,
        )
        .length;
  }

  int get monthlyNonRoutineCount {
    final now = DateTime.now();
    return expenses
        .where(
          (item) =>
              item.type == ExpenseType.nonRoutine &&
              item.date.year == now.year &&
              item.date.month == now.month,
        )
        .length;
  }

  double get monthlyRoutinePercent {
    final total = monthlyRoutineSpend + monthlyNonRoutineSpend;
    return total > 0 ? (monthlyRoutineSpend / total) : 0.0;
  }

  double get monthlyNonRoutinePercent {
    final total = monthlyRoutineSpend + monthlyNonRoutineSpend;
    return total > 0 ? (monthlyNonRoutineSpend / total) : 0.0;
  }

  double get todaySpend {
    final now = DateTime.now();
    return expenses
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
    return expenses
        .where(
          (item) => item.date.year == now.year && item.date.month == now.month,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get yearlySpend {
    final now = DateTime.now();
    return expenses
        .where((item) => item.date.year == now.year)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  int get daysInCurrentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0).day;
  }

  int get daysRemainingInMonth {
    final now = DateTime.now();
    final totalDays = DateTime(now.year, now.month + 1, 0).day;
    return (totalDays - now.day + 1).clamp(1, totalDays);
  }

  double get monthlyBudgetLimit {
    final direct = activeWallet?.monthlyBudget;
    if (direct != null && direct > 0) return direct;
    final daily = activeWallet?.dailyBudget;
    if (daily != null && daily > 0) return daily * daysInCurrentMonth;
    return 0.0;
  }

  double get monthlyBudgetPercent {
    if (monthlyBudgetLimit <= 0) return 0.0;
    return (monthlySpend / monthlyBudgetLimit).clamp(0.0, 1.0);
  }

  double get rawMonthlyBudgetPercent {
    if (monthlyBudgetLimit <= 0) return 0.0;
    return monthlySpend / monthlyBudgetLimit;
  }

  double get monthlyBudgetRemaining {
    if (monthlyBudgetLimit <= 0) return 0.0;
    return monthlyBudgetLimit - monthlySpend;
  }

  double get dailyRecommendedSpending {
    if (monthlyBudgetLimit <= 0) return 0.0;
    final remaining = monthlyBudgetRemaining;
    if (remaining <= 0) return 0.0;
    return remaining / daysRemainingInMonth;
  }

  bool get isOverMonthlyBudget =>
      monthlyBudgetLimit > 0 && monthlySpend > monthlyBudgetLimit;

  bool get isNearMonthlyBudget =>
      monthlyBudgetLimit > 0 &&
      (monthlySpend / monthlyBudgetLimit) >= 0.8 &&
      !isOverMonthlyBudget;

  // ── Category Monthly Budget Getters ───────────────────────────────────────

  /// Current month spending for a specific category in active wallet
  double categorySpendInCurrentMonth(String categoryId) {
    final now = DateTime.now();
    return expenses
        .where(
          (item) =>
              item.category.id == categoryId &&
              item.date.year == now.year &&
              item.date.month == now.month,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// List of category budget statuses for categories configured in the active wallet
  List<CategoryBudgetStatus> get categoryBudgetStatuses {
    final wallet = activeWallet;
    if (wallet == null || wallet.categoryBudgets.isEmpty) return const [];

    final list = <CategoryBudgetStatus>[];
    for (final cb in wallet.categoryBudgets) {
      if (cb.amount <= 0) continue;

      ExpenseCategory? cat = cb.category;
      if (cat == null) {
        final idx = categories.indexWhere((c) => c.id == cb.categoryId);
        if (idx != -1) {
          cat = categories[idx];
        }
      }
      cat ??= ExpenseCategory(
        id: cb.categoryId,
        name: 'Kategori',
        icon: 'category',
        color: '#4F46E5',
      );

      final spend = categorySpendInCurrentMonth(cb.categoryId);
      final limit = cb.amount;
      final rawPct = limit > 0 ? spend / limit : 0.0;
      final pct = rawPct.clamp(0.0, 1.0);
      final rem = limit - spend;
      final isOver = spend > limit;
      final isNear = rawPct >= 0.8 && !isOver;

      list.add(
        CategoryBudgetStatus(
          category: cat,
          budgetLimit: limit,
          monthlySpend: spend,
          remaining: rem,
          percent: pct,
          rawPercent: rawPct,
          isOver: isOver,
          isNear: isNear,
        ),
      );
    }
    return list;
  }

  double get totalCategoryBudgetLimit {
    return categoryBudgetStatuses.fold(
      0.0,
      (sum, item) => sum + item.budgetLimit,
    );
  }

  double get totalCategoryBudgetSpend {
    return categoryBudgetStatuses.fold(
      0.0,
      (sum, item) => sum + item.monthlySpend,
    );
  }

  double get totalCategoryBudgetRemaining {
    if (totalCategoryBudgetLimit <= 0) return 0.0;
    return totalCategoryBudgetLimit - totalCategoryBudgetSpend;
  }

  double get totalCategoryBudgetPercent {
    if (totalCategoryBudgetLimit <= 0) return 0.0;
    return (totalCategoryBudgetSpend / totalCategoryBudgetLimit).clamp(0.0, 1.0);
  }

  double get rawTotalCategoryBudgetPercent {
    if (totalCategoryBudgetLimit <= 0) return 0.0;
    return totalCategoryBudgetSpend / totalCategoryBudgetLimit;
  }

  bool get isOverTotalCategoryBudget =>
      totalCategoryBudgetLimit > 0 &&
      totalCategoryBudgetSpend > totalCategoryBudgetLimit;

  bool get isNearTotalCategoryBudget =>
      totalCategoryBudgetLimit > 0 &&
      (totalCategoryBudgetSpend / totalCategoryBudgetLimit) >= 0.8 &&
      !isOverTotalCategoryBudget;

  String get topCategory {
    if (expenses.isEmpty) return 'None';
    final Map<String, double> categorySums = {};
    for (var expense in expenses) {
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
    if (expenses.isEmpty) return 'category';
    try {
      final topCat = topCategory;
      final match = expenses.firstWhere((e) => e.category.name == topCat);
      return match.category.icon;
    } catch (_) {
      return 'category';
    }
  }

  DashboardState copyWith({
    String? activeTimeframe,
    bool? isLoading,
    bool? isInitialLoad,
    List<WalletEntity>? personalWallets,
    List<WalletEntity>? sharedWallets,
    WalletEntity? selectedWallet,
    List<ExpenseEntity>? expenses,
    List<ExpenseCategory>? categories,
    List<dynamic>? sharedGroups,
    List<dynamic>? pendingInvites,
    List<BillReminderEntity>? reminders,
    Map<String, dynamic>? compareData,
    Map<String, dynamic>? breakdownData,
    bool? isLoadingAnalytics,
    String? errorMessage,
    String? successMessage,
    DashboardStatus? status,
  }) {
    return DashboardState(
      activeTimeframe: activeTimeframe ?? this.activeTimeframe,
      isLoading: isLoading ?? this.isLoading,
      isInitialLoad: isInitialLoad ?? this.isInitialLoad,
      personalWallets: personalWallets ?? this.personalWallets,
      sharedWallets: sharedWallets ?? this.sharedWallets,
      selectedWallet: selectedWallet ?? this.selectedWallet,
      expenses: expenses ?? this.expenses,
      categories: categories ?? this.categories,
      sharedGroups: sharedGroups ?? this.sharedGroups,
      pendingInvites: pendingInvites ?? this.pendingInvites,
      reminders: reminders ?? this.reminders,
      compareData: compareData ?? this.compareData,
      breakdownData: breakdownData ?? this.breakdownData,
      isLoadingAnalytics: isLoadingAnalytics ?? this.isLoadingAnalytics,
      errorMessage: errorMessage,
      successMessage: successMessage,
      status: status ?? this.status,
    );
  }
}

class CategoryBudgetStatus {
  final ExpenseCategory category;
  final double budgetLimit;
  final double monthlySpend;
  final double remaining;
  final double percent;
  final double rawPercent;
  final bool isOver;
  final bool isNear;

  const CategoryBudgetStatus({
    required this.category,
    required this.budgetLimit,
    required this.monthlySpend,
    required this.remaining,
    required this.percent,
    required this.rawPercent,
    required this.isOver,
    required this.isNear,
  });
}

