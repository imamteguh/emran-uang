enum Periodicity { monthly, yearly, daily, weekly }

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

  bool get isMonthly => periodicity == Periodicity.monthly;
  bool get isYearly => periodicity == Periodicity.yearly;

  /// Memeriksa apakah tagihan sudah dibayar untuk siklus aktif (atau siklus acuan).
  bool isPaidForPeriod([DateTime? nowRef]) {
    if (expenses.isEmpty) return false;
    final now = nowRef ?? DateTime.now();

    switch (periodicity) {
      case Periodicity.yearly:
        return expenses.any((e) => e.date.year == now.year);
      case Periodicity.monthly:
      case Periodicity.daily:
      case Periodicity.weekly:
        return expenses.any((e) =>
            e.date.year == now.year &&
            e.date.month == now.month);
    }
  }

  bool get isPaidForCurrentPeriod => isPaidForPeriod();

  /// Menghitung tanggal jatuh tempo efektif untuk siklus saat ini
  /// (atau siklus berikutnya jika periode saat ini sudah dibayar).
  DateTime getEffectiveDueDate([DateTime? nowRef]) {
    final now = nowRef ?? DateTime.now();
    final baseDueDate = dueDate;

    if (periodicity == Periodicity.yearly) {
      final candidateThisYear = DateTime(
        now.year,
        baseDueDate.month,
        baseDueDate.day,
      );

      if (baseDueDate.isAfter(candidateThisYear)) {
        return baseDueDate;
      }

      // Jika sudah dibayar tahun ini, tampilkan tanggal jatuh tempo tahun depan
      if (isPaidForPeriod(now)) {
        return DateTime(now.year + 1, baseDueDate.month, baseDueDate.day);
      }

      return candidateThisYear;
    }

    // Default: Bulanan (Monthly)
    final targetDay = baseDueDate.day;
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final clampedDay = targetDay > lastDayOfMonth ? lastDayOfMonth : targetDay;
    final candidateThisMonth = DateTime(now.year, now.month, clampedDay);

    if (baseDueDate.isAfter(candidateThisMonth)) {
      return baseDueDate;
    }

    // Jika sudah lunas bulan ini, tampilkan tanggal jatuh tempo bulan depan
    if (isPaidForPeriod(now)) {
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      final lastDayNext = DateTime(nextYear, nextMonth + 1, 0).day;
      final nextClamped = targetDay > lastDayNext ? lastDayNext : targetDay;
      return DateTime(nextYear, nextMonth, nextClamped);
    }

    return candidateThisMonth;
  }

  /// Menghitung selisih hari dari hari ini ke tanggal jatuh tempo efektif.
  /// Nilai negatif = terlambat (overdue), 0 = jatuh tempo hari ini, positif = sisa hari.
  int getDaysUntilDue([DateTime? nowRef]) {
    final now = nowRef ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final effectiveDue = getEffectiveDueDate(now);
    final dueDay = DateTime(effectiveDue.year, effectiveDue.month, effectiveDue.day);
    return dueDay.difference(today).inDays;
  }

  /// Tagihan sudah melewati tanggal jatuh tempo dan belum dibayar.
  bool get isOverdue => isOverdueFor();

  /// Tagihan jatuh tempo hari ini dan belum dibayar.
  bool get isDueToday => isDueTodayFor();

  /// Tagihan jatuh tempo dalam rentang hari pengingat (notifyDaysBefore) dan belum dibayar.
  bool isDueSoon([int? thresholdDays, DateTime? nowRef]) => isDueSoonFor(thresholdDays, nowRef);

  /// Tagihan memerlukan perhatian/alert pengguna segera (overdue, hari ini, atau segera).
  bool get needsAlert => needsAlertFor();

  /// Memeriksa status jatuh tempo terhadap waktu acuan (nowRef)
  bool isOverdueFor([DateTime? nowRef]) {
    if (isPaidForPeriod(nowRef)) return false;
    return getDaysUntilDue(nowRef) < 0;
  }

  bool isDueTodayFor([DateTime? nowRef]) {
    if (isPaidForPeriod(nowRef)) return false;
    return getDaysUntilDue(nowRef) == 0;
  }

  bool isDueSoonFor([int? thresholdDays, DateTime? nowRef]) {
    if (isPaidForPeriod(nowRef)) return false;
    final days = getDaysUntilDue(nowRef);
    final maxDays = thresholdDays ?? notifyDaysBefore;
    return days > 0 && days <= maxDays;
  }

  bool needsAlertFor([DateTime? nowRef]) {
    if (isPaidForPeriod(nowRef)) return false;
    return isOverdueFor(nowRef) || isDueTodayFor(nowRef) || isDueSoonFor(null, nowRef);
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
      case 'YEARLY':
        parsedPeriodicity = Periodicity.yearly;
        break;
      case 'DAILY':
        parsedPeriodicity = Periodicity.daily;
        break;
      case 'WEEKLY':
        parsedPeriodicity = Periodicity.weekly;
        break;
      case 'MONTHLY':
      default:
        parsedPeriodicity = Periodicity.monthly;
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
