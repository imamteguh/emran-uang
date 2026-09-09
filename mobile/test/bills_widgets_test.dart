import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:emran_uang/core/utils/responsive_helper.dart';
import 'package:emran_uang/features/expenses/domain/entities/bill_reminder.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/bills/bills.dart';

void main() {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('Bills Sub-widgets Tests', () {
    testWidgets('BillsAlertBanner displays correct banner for overdue bills', (tester) async {
      final overdueBill = BillReminderEntity(
        id: 'b1',
        title: 'Overdue Wifi',
        amount: 300000,
        dueDate: DateTime.now().subtract(const Duration(days: 3)),
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

      await tester.pumpWidget(
        wrapWithMaterial(
          Builder(
            builder: (context) => BillsAlertBanner(
              overdueBills: [overdueBill],
              dueTodayBills: const [],
              dueSoonBills: const [],
              currencyFormatter: currencyFormatter,
              responsive: ResponsiveHelper(context),
            ),
          ),
        ),
      );

      expect(find.text('Perhatian: 1 Tagihan Lewat Jatuh Tempo!'), findsOneWidget);
      expect(find.textContaining('Total tertunggak: Rp300.000'), findsOneWidget);
    });

    testWidgets('BillsAlertBanner displays all clear when no urgent bills', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          Builder(
            builder: (context) => BillsAlertBanner(
              overdueBills: const [],
              dueTodayBills: const [],
              dueSoonBills: const [],
              currencyFormatter: currencyFormatter,
              responsive: ResponsiveHelper(context),
            ),
          ),
        ),
      );

      expect(find.text('Semua Tagihan Terkendali'), findsOneWidget);
    });

    testWidgets('BillsOutflowCard displays formatted total amount', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          Builder(
            builder: (context) => BillsOutflowCard(
              totalMonthlyOutflow: 1500000,
              currencyFormatter: currencyFormatter,
              responsive: ResponsiveHelper(context),
            ),
          ),
        ),
      );

      expect(find.text('ESTIMATED MONTHLY OUTFLOW'), findsOneWidget);
      expect(find.text('Rp1.500.000'), findsOneWidget);
    });

    testWidgets('BillsPaidPendingCard displays paid and pending values', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          BillsPaidPendingCard(
            paidThisMonth: 500000,
            pendingThisMonth: 1000000,
            currencyFormatter: currencyFormatter,
          ),
        ),
      );

      expect(find.text('PAID'), findsOneWidget);
      expect(find.text('Rp500.000'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('Rp1.000.000'), findsOneWidget);
    });

    testWidgets('BillCardItem displays bill info and triggers onTap', (tester) async {
      bool tapped = false;
      final bill = BillReminderEntity(
        id: 'b1',
        title: 'Indihome Fiber',
        amount: 385000,
        dueDate: DateTime.now().add(const Duration(days: 10)),
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

      await tester.pumpWidget(
        wrapWithMaterial(
          BillCardItem(
            reminder: bill,
            formatter: currencyFormatter,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      expect(find.text('Indihome Fiber'), findsOneWidget);
      expect(find.text('Rp385.000'), findsOneWidget);
      expect(find.text('Bulanan'), findsOneWidget);

      await tester.tap(find.byType(BillCardItem));
      expect(tapped, isTrue);
    });

    testWidgets('BillsSectionHeader renders title and add action', (tester) async {
      bool addPressed = false;
      await tester.pumpWidget(
        wrapWithMaterial(
          Builder(
            builder: (context) => BillsSectionHeader(
              title: 'Tagihan Bulanan',
              responsive: ResponsiveHelper(context),
              onAdd: () {
                addPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Tagihan Bulanan'), findsOneWidget);
      expect(find.text('Tambah'), findsOneWidget);

      await tester.tap(find.text('Tambah'));
      expect(addPressed, isTrue);
    });

    testWidgets('BillsEmptyState displays icon, title, and description', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          const BillsEmptyState(
            icon: Icons.calendar_today_outlined,
            title: 'Belum ada tagihan tahunan',
            description: 'Tagihan tahunan akan muncul di sini.',
          ),
        ),
      );

      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.text('Belum ada tagihan tahunan'), findsOneWidget);
      expect(find.text('Tagihan tahunan akan muncul di sini.'), findsOneWidget);
    });
  });
}
