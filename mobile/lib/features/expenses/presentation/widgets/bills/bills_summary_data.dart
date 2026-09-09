import '../../../domain/entities/bill_reminder.dart';

class BillsSummaryData {
  final List<BillReminderEntity> activeReminders;
  final double totalMonthlyOutflow;
  final double paidThisMonth;
  final double pendingThisMonth;
  final List<BillReminderEntity> regularBills;
  final List<BillReminderEntity> annualRenewals;
  final List<BillReminderEntity> overdueBills;
  final List<BillReminderEntity> dueTodayBills;
  final List<BillReminderEntity> dueSoonBills;

  const BillsSummaryData({
    required this.activeReminders,
    required this.totalMonthlyOutflow,
    required this.paidThisMonth,
    required this.pendingThisMonth,
    required this.regularBills,
    required this.annualRenewals,
    required this.overdueBills,
    required this.dueTodayBills,
    required this.dueSoonBills,
  });

  factory BillsSummaryData.fromReminders(
    List<BillReminderEntity> reminders, [
    DateTime? nowRef,
  ]) {
    final active = reminders
        .where((r) => r.status == ReminderStatus.active)
        .toList();

    double totalMonthlyOutflow = 0;
    double paidThisMonth = 0;
    double pendingThisMonth = 0;

    for (final r in active) {
      final monthlyAmt = r.periodicity == Periodicity.yearly
          ? r.amount / 12.0
          : r.amount;

      totalMonthlyOutflow += monthlyAmt;
      if (r.isPaidForPeriod(nowRef)) {
        paidThisMonth += monthlyAmt;
      } else {
        pendingThisMonth += monthlyAmt;
      }
    }

    final regularBills = active
        .where((r) => r.periodicity != Periodicity.yearly)
        .toList();
    final annualRenewals = active
        .where((r) => r.periodicity == Periodicity.yearly)
        .toList();

    final overdueBills = active.where((r) => r.isOverdueFor(nowRef)).toList();
    final dueTodayBills = active.where((r) => r.isDueTodayFor(nowRef)).toList();
    final dueSoonBills = active.where((r) => r.isDueSoon(5, nowRef)).toList();

    return BillsSummaryData(
      activeReminders: active,
      totalMonthlyOutflow: totalMonthlyOutflow,
      paidThisMonth: paidThisMonth,
      pendingThisMonth: pendingThisMonth,
      regularBills: regularBills,
      annualRenewals: annualRenewals,
      overdueBills: overdueBills,
      dueTodayBills: dueTodayBills,
      dueSoonBills: dueSoonBills,
    );
  }
}
