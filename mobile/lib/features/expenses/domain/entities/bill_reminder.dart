enum Periodicity { daily, weekly, monthly, yearly }

enum ReminderStatus { active, snoozed, completed, cancelled }

class BillReminderExpense {
  final String id;
  final double amount;
  final DateTime date;

  BillReminderExpense({
    required this.id,
    required this.amount,
    required this.date,
  });

  factory BillReminderExpense.fromJson(Map<dynamic, dynamic> json) {
    double parsedAmount = 0.0;
    final rawAmount = json['amount'];
    if (rawAmount is num) {
      parsedAmount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      parsedAmount = double.tryParse(rawAmount) ?? 0.0;
    }

    return BillReminderExpense(
      id: json['id'] as String? ?? '',
      amount: parsedAmount,
      date: DateTime.parse(json['date'] as String).toLocal(),
    );
  }
}

class BillReminderCategory {
  final String id;
  final String name;
  final String icon;
  final String color;

  BillReminderCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  factory BillReminderCategory.fromJson(Map<dynamic, dynamic> json) {
    return BillReminderCategory(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '💰',
      color: json['color'] as String? ?? '#4F46E5',
    );
  }
}

class BillReminderEntity {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final Periodicity periodicity;
  final ReminderStatus status;
  final String userId;
  final String walletId;
  final String? categoryId;
  final BillReminderCategory? category;
  final int notifyDaysBefore;
  final bool autoLogExpense;
  final DateTime? lastNotifiedAt;
  final DateTime? lastTriggeredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<BillReminderExpense> expenses;

  BillReminderEntity({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.periodicity,
    required this.status,
    required this.userId,
    required this.walletId,
    this.categoryId,
    this.category,
    required this.notifyDaysBefore,
    required this.autoLogExpense,
    this.lastNotifiedAt,
    this.lastTriggeredAt,
    required this.createdAt,
    required this.updatedAt,
    required this.expenses,
  });

  bool get isPaidForCurrentPeriod {
    if (expenses.isEmpty) return false;
    final now = DateTime.now();

    switch (periodicity) {
      case Periodicity.daily:
        return expenses.any((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day);
      case Periodicity.weekly:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        return expenses.any((e) =>
            e.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
            e.date.isBefore(endOfWeek.add(const Duration(seconds: 1))));
      case Periodicity.monthly:
        return expenses.any((e) =>
            e.date.year == now.year &&
            e.date.month == now.month);
      case Periodicity.yearly:
        return expenses.any((e) => e.date.year == now.year);
    }
  }

  factory BillReminderEntity.fromJson(Map<dynamic, dynamic> json) {
    double parsedAmount = 0.0;
    final rawAmount = json['amount'];
    if (rawAmount is num) {
      parsedAmount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      parsedAmount = double.tryParse(rawAmount) ?? 0.0;
    }

    Periodicity parsedPeriodicity = Periodicity.monthly;
    final rawPeriodicity = json['periodicity'] as String? ?? 'MONTHLY';
    switch (rawPeriodicity.toUpperCase()) {
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

    ReminderStatus parsedStatus = ReminderStatus.active;
    final rawStatus = json['status'] as String? ?? 'ACTIVE';
    switch (rawStatus.toUpperCase()) {
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

    final categoryJson = json['category'];
    final expensesList = json['expenses'] as List? ?? [];

    return BillReminderEntity(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      amount: parsedAmount,
      dueDate: DateTime.parse(json['dueDate'] as String).toLocal(),
      periodicity: parsedPeriodicity,
      status: parsedStatus,
      userId: json['userId'] as String? ?? '',
      walletId: json['walletId'] as String? ?? '',
      categoryId: json['categoryId'] as String?,
      category: categoryJson != null ? BillReminderCategory.fromJson(categoryJson) : null,
      notifyDaysBefore: json['notifyDaysBefore'] as int? ?? 3,
      autoLogExpense: json['autoLogExpense'] as bool? ?? false,
      lastNotifiedAt: json['lastNotifiedAt'] != null ? DateTime.parse(json['lastNotifiedAt'] as String).toLocal() : null,
      lastTriggeredAt: json['lastTriggeredAt'] != null ? DateTime.parse(json['lastTriggeredAt'] as String).toLocal() : null,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
      expenses: expensesList.map((e) => BillReminderExpense.fromJson(e as Map)).toList(),
    );
  }
}
