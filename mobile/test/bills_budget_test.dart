import 'package:flutter_test/flutter_test.dart';
import 'package:emran_uang/features/expenses/domain/entities/bill_reminder.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/bills/bills_summary_data.dart';

void main() {
  group('Bills Budget & Summary Calculations', () {
    test('Calculates total monthly outflow accurately across monthly and yearly bills', () {
      final reminders = [
        BillReminderEntity(
          id: 'b1',
          title: 'Internet Bulanan',
          amount: 300000,
          dueDate: DateTime(2026, 3, 10),
          periodicity: Periodicity.monthly,
          status: ReminderStatus.active,
          userId: 'u1',
          walletId: 'w1',
          notifyDaysBefore: 3,
          autoLogExpense: false,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          expenses: [],
        ),
        BillReminderEntity(
          id: 'b2',
          title: 'Hosting Tahunan',
          amount: 1200000, // 100.000 per month
          dueDate: DateTime(2026, 6, 1),
          periodicity: Periodicity.yearly,
          status: ReminderStatus.active,
          userId: 'u1',
          walletId: 'w1',
          notifyDaysBefore: 7,
          autoLogExpense: false,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          expenses: [],
        ),
      ];

      final summary = BillsSummaryData.fromReminders(reminders, DateTime(2026, 3, 5));

      // 300.000 (monthly) + 100.000 (yearly/12) = 400.000
      expect(summary.totalMonthlyOutflow, equals(400000.0));
      expect(summary.pendingThisMonth, equals(400000.0));
      expect(summary.paidThisMonth, equals(0.0));

      // Test budget allocation ratio
      const double budgetLimit = 1000000.0;
      final double ratio = summary.totalMonthlyOutflow / budgetLimit;
      expect(ratio, equals(0.4)); // 40% allocation
      expect(budgetLimit - summary.totalMonthlyOutflow, equals(600000.0)); // Remaining
    });

    test('Over-budget scenario is detected when total bills exceed monthly budget limit', () {
      final reminders = [
        BillReminderEntity(
          id: 'b1',
          title: 'Sewa Apartemen',
          amount: 3500000,
          dueDate: DateTime(2026, 3, 1),
          periodicity: Periodicity.monthly,
          status: ReminderStatus.active,
          userId: 'u1',
          walletId: 'w1',
          notifyDaysBefore: 3,
          autoLogExpense: false,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          expenses: [],
        ),
      ];

      final summary = BillsSummaryData.fromReminders(reminders, DateTime(2026, 3, 5));
      const double budgetLimit = 3000000.0;

      final bool isOverBudget = summary.totalMonthlyOutflow > budgetLimit;
      expect(isOverBudget, isTrue);

      final double deficit = summary.totalMonthlyOutflow - budgetLimit;
      expect(deficit, equals(500000.0));
    });
  });
}
