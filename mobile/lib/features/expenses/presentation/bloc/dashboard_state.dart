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
