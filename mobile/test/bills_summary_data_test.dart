import 'package:flutter_test/flutter_test.dart';
import 'package:emran_uang/features/expenses/domain/entities/bill_reminder.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/bills/bills_summary_data.dart';

void main() {
  group('BillsSummaryData Tests', () {
    final now = DateTime(2026, 3, 10);

    test('correctly calculates monthly outflow, paid, pending and partitions lists', () {
      final monthlyUnpaid = BillReminderEntity(
        id: 'b1',
        title: 'Internet',
        amount: 300000,
        dueDate: DateTime(2026, 3, 15),
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

      final monthlyPaid = BillReminderEntity(
        id: 'b2',
        title: 'Electricity',
        amount: 200000,
        dueDate: DateTime(2026, 3, 5),
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
            id: 'e1',
            amount: 200000,
            date: DateTime(2026, 3, 5),
          ),
        ],
      );

      final yearlyUnpaid = BillReminderEntity(
        id: 'b3',
        title: 'Car Tax',
        amount: 1200000, // 100,000 / month
        dueDate: DateTime(2026, 6, 20),
        periodicity: Periodicity.yearly,
        status: ReminderStatus.active,
        userId: 'u1',
        walletId: 'w1',
        notifyDaysBefore: 7,
        autoLogExpense: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        expenses: [],
      );

      final inactiveBill = BillReminderEntity(
        id: 'b4',
        title: 'Cancelled Subscription',
        amount: 50000,
        dueDate: DateTime(2026, 3, 12),
        periodicity: Periodicity.monthly,
        status: ReminderStatus.cancelled,
        userId: 'u1',
        walletId: 'w1',
        notifyDaysBefore: 1,
        autoLogExpense: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        expenses: [],
      );

      final reminders = [
        monthlyUnpaid,
        monthlyPaid,
        yearlyUnpaid,
        inactiveBill,
      ];

      final summary = BillsSummaryData.fromReminders(reminders, now);

      // Inactive bills are excluded from activeReminders
      expect(summary.activeReminders.length, equals(3));

      // totalMonthlyOutflow = 300000 + 200000 + (1200000 / 12) = 600000
      expect(summary.totalMonthlyOutflow, equals(600000));

      // paidThisMonth = 200000
      expect(summary.paidThisMonth, equals(200000));

      // pendingThisMonth = 300000 + 100000 = 400000
      expect(summary.pendingThisMonth, equals(400000));

      // regularBills = [monthlyUnpaid, monthlyPaid]
      expect(summary.regularBills.length, equals(2));
      expect(summary.regularBills.map((b) => b.id), containsAll(['b1', 'b2']));

      // annualRenewals = [yearlyUnpaid]
      expect(summary.annualRenewals.length, equals(1));
      expect(summary.annualRenewals.first.id, equals('b3'));
    });

    test('correctly identifies overdue, due today, and due soon bills', () {
      final overdueBill = BillReminderEntity(
        id: 'b_overdue',
        title: 'Past Due Bill',
        amount: 150000,
        dueDate: DateTime(2026, 3, 5), // now is March 10
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

      final dueTodayBill = BillReminderEntity(
        id: 'b_today',
        title: 'Today Bill',
        amount: 75000,
        dueDate: DateTime(2026, 3, 10), // now is March 10
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

      final dueSoonBill = BillReminderEntity(
        id: 'b_soon',
        title: 'Soon Bill',
        amount: 50000,
        dueDate: DateTime(2026, 3, 13), // 3 days away (within 5 days)
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

      final summary = BillsSummaryData.fromReminders(
        [overdueBill, dueTodayBill, dueSoonBill],
        now,
      );

      expect(summary.overdueBills.length, equals(1));
      expect(summary.overdueBills.first.id, equals('b_overdue'));

      expect(summary.dueTodayBills.length, equals(1));
      expect(summary.dueTodayBills.first.id, equals('b_today'));

      expect(summary.dueSoonBills.length, equals(1));
      expect(summary.dueSoonBills.first.id, equals('b_soon'));
    });
  });
}
