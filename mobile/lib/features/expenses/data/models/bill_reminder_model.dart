import '../../domain/entities/bill_reminder.dart';

class BillReminderModel extends BillReminderEntity {
  BillReminderModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.dueDate,
    required super.periodicity,
    required super.status,
    required super.userId,
    required super.walletId,
    super.categoryId,
    super.category,
    required super.notifyDaysBefore,
    required super.autoLogExpense,
    super.lastNotifiedAt,
    super.lastTriggeredAt,
    required super.createdAt,
    required super.updatedAt,
    required super.expenses,
  });

  factory BillReminderModel.fromJson(Map<String, dynamic> json) {
    final entity = BillReminderEntity.fromJson(json);
    return BillReminderModel(
      id: entity.id,
      title: entity.title,
      amount: entity.amount,
      dueDate: entity.dueDate,
      periodicity: entity.periodicity,
      status: entity.status,
      userId: entity.userId,
      walletId: entity.walletId,
      categoryId: entity.categoryId,
      category: entity.category,
      notifyDaysBefore: entity.notifyDaysBefore,
      autoLogExpense: entity.autoLogExpense,
      lastNotifiedAt: entity.lastNotifiedAt,
      lastTriggeredAt: entity.lastTriggeredAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      expenses: entity.expenses,
    );
  }

  Map<String, dynamic> toJson() {
    String rawPeriodicity = 'MONTHLY';
    switch (periodicity) {
      case Periodicity.daily:
        rawPeriodicity = 'DAILY';
        break;
      case Periodicity.weekly:
        rawPeriodicity = 'WEEKLY';
        break;
      case Periodicity.monthly:
        rawPeriodicity = 'MONTHLY';
        break;
      case Periodicity.yearly:
        rawPeriodicity = 'YEARLY';
        break;
    }

    String rawStatus = 'ACTIVE';
    switch (status) {
      case ReminderStatus.active:
        rawStatus = 'ACTIVE';
        break;
      case ReminderStatus.snoozed:
        rawStatus = 'SNOOZED';
        break;
      case ReminderStatus.completed:
        rawStatus = 'COMPLETED';
        break;
      case ReminderStatus.cancelled:
        rawStatus = 'CANCELLED';
        break;
    }

    return {
      'title': title,
      'amount': amount,
      'dueDate': dueDate.toUtc().toIso8601String(),
      'periodicity': rawPeriodicity,
      'status': rawStatus,
      'categoryId': categoryId,
      'notifyDaysBefore': notifyDaysBefore,
      'autoLogExpense': autoLogExpense,
    };
  }
}
