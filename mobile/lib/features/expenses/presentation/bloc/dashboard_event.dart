import 'dart:async';
import '../../domain/entities/expense.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/bill_reminder.dart';

abstract class DashboardEvent {
  const DashboardEvent();
}

class DashboardInitializeRequested extends DashboardEvent {
  const DashboardInitializeRequested();
}

class DashboardSelectWalletRequested extends DashboardEvent {
  final WalletEntity wallet;
  const DashboardSelectWalletRequested(this.wallet);
}

class DashboardSetTimeframeRequested extends DashboardEvent {
  final String timeframe;
  const DashboardSetTimeframeRequested(this.timeframe);
}

class DashboardToggleSharedModeRequested extends DashboardEvent {
  final bool isShared;
  const DashboardToggleSharedModeRequested(this.isShared);
}

class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested();
}

class DashboardFetchAnalyticsRequested extends DashboardEvent {
  const DashboardFetchAnalyticsRequested();
}

class DashboardFetchRemindersRequested extends DashboardEvent {
  const DashboardFetchRemindersRequested();
}

class DashboardFetchCategoriesRequested extends DashboardEvent {
  const DashboardFetchCategoriesRequested();
}

class DashboardAddCategoryRequested extends DashboardEvent {
  final String name;
  final String icon;
  final String color;
  final Completer<bool> completer;

  const DashboardAddCategoryRequested({
    required this.name,
    required this.icon,
    required this.color,
    required this.completer,
  });
}

class DashboardUpdateCategoryRequested extends DashboardEvent {
  final String id;
  final String name;
  final String icon;
  final String color;
  final Completer<bool> completer;

  const DashboardUpdateCategoryRequested({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.completer,
  });
}

class DashboardDeleteCategoryRequested extends DashboardEvent {
  final String id;
  final Completer<bool> completer;

  const DashboardDeleteCategoryRequested(this.id, this.completer);
}

class DashboardAddExpenseRequested extends DashboardEvent {
  final ExpenseEntity expense;
  final Completer<bool> completer;

  const DashboardAddExpenseRequested(this.expense, this.completer);
}

class DashboardDeleteExpenseRequested extends DashboardEvent {
  final String id;
  final Completer<bool> completer;

  const DashboardDeleteExpenseRequested(this.id, this.completer);
}

class DashboardUpdateDailyBudgetRequested extends DashboardEvent {
  final double budget;
  final Completer<bool> completer;

  const DashboardUpdateDailyBudgetRequested(this.budget, this.completer);
}

class DashboardUpdateMonthlyBudgetRequested extends DashboardEvent {
  final double budget;
  final bool syncDailyBudget;
  final Completer<bool> completer;

  const DashboardUpdateMonthlyBudgetRequested(
    this.budget,
    this.completer, {
    this.syncDailyBudget = false,
  });
}

class DashboardUpdateWalletCurrencyRequested extends DashboardEvent {
  final String currency;
  final Completer<bool> completer;

  const DashboardUpdateWalletCurrencyRequested(this.currency, this.completer);
}

class DashboardFetchSharedGroupsRequested extends DashboardEvent {
  const DashboardFetchSharedGroupsRequested();
}

class DashboardSendInviteRequested extends DashboardEvent {
  final String email;
  final String? groupName;
  final Completer<String?> completer;

  const DashboardSendInviteRequested({
    required this.email,
    this.groupName,
    required this.completer,
  });
}

class DashboardAcceptInviteRequested extends DashboardEvent {
  final String inviteId;
  final Completer<bool> completer;

  const DashboardAcceptInviteRequested(this.inviteId, this.completer);
}

class DashboardRejectInviteRequested extends DashboardEvent {
  final String inviteId;
  final Completer<bool> completer;

  const DashboardRejectInviteRequested(this.inviteId, this.completer);
}

class DashboardLeaveGroupRequested extends DashboardEvent {
  final String groupId;
  final Completer<bool> completer;

  const DashboardLeaveGroupRequested(this.groupId, this.completer);
}

class DashboardDeleteGroupRequested extends DashboardEvent {
  final String groupId;
  final Completer<bool> completer;

  const DashboardDeleteGroupRequested(this.groupId, this.completer);
}

class DashboardAddReminderRequested extends DashboardEvent {
  final String title;
  final double amount;
  final DateTime dueDate;
  final String periodicity;
  final String? categoryId;
  final int notifyDaysBefore;
  final bool autoLogExpense;
  final Completer<bool> completer;

  const DashboardAddReminderRequested({
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.periodicity,
    this.categoryId,
    required this.notifyDaysBefore,
    required this.autoLogExpense,
    required this.completer,
  });
}

class DashboardUpdateReminderRequested extends DashboardEvent {
  final String id;
  final String? title;
  final double? amount;
  final DateTime? dueDate;
  final String? periodicity;
  final String? status;
  final String? categoryId;
  final int? notifyDaysBefore;
  final bool? autoLogExpense;
  final Completer<bool> completer;

  const DashboardUpdateReminderRequested({
    required this.id,
    this.title,
    this.amount,
    this.dueDate,
    this.periodicity,
    this.status,
    this.categoryId,
    this.notifyDaysBefore,
    this.autoLogExpense,
    required this.completer,
  });
}

class DashboardDeleteReminderRequested extends DashboardEvent {
  final String id;
  final Completer<bool> completer;

  const DashboardDeleteReminderRequested(this.id, this.completer);
}

class DashboardPayBillRequested extends DashboardEvent {
  final BillReminderEntity reminder;
  final Completer<bool> completer;

  const DashboardPayBillRequested(this.reminder, this.completer);
}
