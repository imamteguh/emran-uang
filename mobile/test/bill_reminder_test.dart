import 'package:flutter_test/flutter_test.dart';
import 'package:emran_uang/features/expenses/domain/entities/bill_reminder.dart';

void main() {
  group('BillReminderEntity Logic Tests', () {
    test('Monthly reminder calculates effective due date in current month', () {
      final reminder = BillReminderEntity(
        id: 'bill_1',
        title: 'Wifi Indihome',
        amount: 350000,
        dueDate: DateTime(2026, 1, 15), // Created in January 15
        periodicity: Periodicity.monthly,
        status: ReminderStatus.active,
        userId: 'u1',
        walletId: 'w1',
        notifyDaysBefore: 3,
        autoLogExpense: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        expenses: [],
      );

      // Given current date is March 10, 2026
      final marchNow = DateTime(2026, 3, 10);
      final effectiveDue = reminder.getEffectiveDueDate(marchNow);

      expect(effectiveDue.year, equals(2026));
      expect(effectiveDue.month, equals(3));
      expect(effectiveDue.day, equals(15));

      final daysUntilDue = reminder.getDaysUntilDue(marchNow);
      expect(daysUntilDue, equals(5));
      expect(reminder.isDueSoon(5, marchNow), isTrue);
      expect(reminder.isOverdueFor(marchNow), isFalse);
      expect(reminder.isDueTodayFor(marchNow), isFalse);
    });

    test('Monthly reminder clamps day on months with fewer days (e.g. Feb 28)', () {
      final reminder = BillReminderEntity(
        id: 'bill_2',
        title: 'End of Month Sub',
        amount: 100000,
        dueDate: DateTime(2026, 1, 31), // 31st of month
        periodicity: Periodicity.monthly,
        status: ReminderStatus.active,
        userId: 'u1',
        walletId: 'w1',
        notifyDaysBefore: 3,
        autoLogExpense: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        expenses: [],
      );

      // In February 2026 (non-leap year, 28 days)
      final febNow = DateTime(2026, 2, 10);
      final effectiveDue = reminder.getEffectiveDueDate(febNow);

      expect(effectiveDue.year, equals(2026));
      expect(effectiveDue.month, equals(2));
      expect(effectiveDue.day, equals(28));
    });

    test('Monthly reminder advances to next month when paid for current month', () {
      final now = DateTime(2026, 3, 16);
      final reminder = BillReminderEntity(
        id: 'bill_3',
        title: 'Electricity',
        amount: 500000,
        dueDate: DateTime(2026, 1, 15),
        periodicity: Periodicity.monthly,
        status: ReminderStatus.active,
        userId: 'u1',
        walletId: 'w1',
        notifyDaysBefore: 3,
        autoLogExpense: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        expenses: [
          BillReminderExpense(
            id: 'exp_1',
            amount: 500000,
            date: DateTime(2026, 3, 14), // Paid in March
          ),
        ],
      );

      expect(reminder.isPaidForPeriod(now), isTrue);
      expect(reminder.isOverdueFor(now), isFalse);
      expect(reminder.isDueTodayFor(now), isFalse);
      expect(reminder.needsAlertFor(now), isFalse);

      final nextDue = reminder.getEffectiveDueDate(now);
      expect(nextDue.year, equals(2026));
      expect(nextDue.month, equals(4)); // April 15
      expect(nextDue.day, equals(15));
    });

    test('Overdue logic works accurately when past due date without payment', () {
      // Due date was 10th, current date is 14th
      final now = DateTime(2026, 3, 14);
      final reminder = BillReminderEntity(
        id: 'bill_4',
        title: 'Netflix',
        amount: 186000,
        dueDate: DateTime(2026, 1, 10),
        periodicity: Periodicity.monthly,
        status: ReminderStatus.active,
        userId: 'u1',
        walletId: 'w1',
        notifyDaysBefore: 3,
        autoLogExpense: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        expenses: [],
      );

      final daysUntilDue = reminder.getDaysUntilDue(now);
      expect(daysUntilDue, equals(-4));
      expect(reminder.isOverdueFor(now), isTrue);
      expect(reminder.needsAlertFor(now), isTrue);
    });

    test('Due today logic works accurately', () {
      final now = DateTime.now();
      final reminder = BillReminderEntity(
        id: 'bill_5',
        title: 'Gym Membership',
        amount: 250000,
        dueDate: DateTime(2026, 1, now.day),
        periodicity: Periodicity.monthly,
        status: ReminderStatus.active,
        userId: 'u1',
        walletId: 'w1',
        notifyDaysBefore: 3,
        autoLogExpense: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        expenses: [],
      );

      expect(reminder.isDueToday, isTrue);
      expect(reminder.isOverdue, isFalse);
      expect(reminder.needsAlert, isTrue);
    });

    test('Yearly reminder advances to next year when paid', () {
      final now = DateTime(2026, 5, 20);
      final reminder = BillReminderEntity(
        id: 'bill_6',
        title: 'Vehicle Tax',
        amount: 2500000,
        dueDate: DateTime(2026, 6, 1),
        periodicity: Periodicity.yearly,
        status: ReminderStatus.active,
        userId: 'u1',
        walletId: 'w1',
        notifyDaysBefore: 7,
        autoLogExpense: false,
        createdAt: DateTime(2025, 6, 1),
        updatedAt: DateTime(2025, 6, 1),
        expenses: [
          BillReminderExpense(
            id: 'exp_tax_2026',
            amount: 2500000,
            date: DateTime(2026, 5, 10),
          ),
        ],
      );

      expect(reminder.isPaidForPeriod(now), isTrue);
      final effectiveDue = reminder.getEffectiveDueDate(now);
      expect(effectiveDue.year, equals(2027));
      expect(effectiveDue.month, equals(6));
      expect(effectiveDue.day, equals(1));
    });
  });
}
