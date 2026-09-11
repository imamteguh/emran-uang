import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:emran_uang/core/theme/app_theme.dart';
import 'package:emran_uang/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:emran_uang/features/auth/presentation/bloc/auth_state.dart';
import 'package:emran_uang/features/auth/presentation/bloc/auth_user.dart';
import 'package:emran_uang/features/expenses/domain/entities/expense.dart';
import 'package:emran_uang/features/expenses/domain/entities/wallet.dart';
import 'package:emran_uang/features/expenses/presentation/bloc/dashboard_bloc.dart';
import 'package:emran_uang/features/expenses/presentation/bloc/notification_bloc.dart';
import 'package:emran_uang/features/expenses/presentation/screens/transaction_history_screen.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/transaction_history/sticky_date_header_delegate.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/transaction_history/transaction_calendar_filter_sheet.dart';
import 'package:emran_uang/core/utils/currency_helper.dart';

void main() {
  setUpAll(() async {
    dotenv.loadFromString(envString: 'API_URL=https://dummy.api\n');
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('id_ID', null);
  });

  group('TransactionFilterCriteria (31 Days Limit Logic)', () {
    test('Calculates day count correctly', () {
      final start = DateTime(2026, 9, 1);
      final end = DateTime(2026, 9, 10);
      final criteria = TransactionFilterCriteria(startDate: start, endDate: end);
      expect(criteria.dayCount, 10);
    });

    test('31-day range is valid', () {
      final start = DateTime(2026, 8, 1);
      final end = DateTime(2026, 8, 31);
      final criteria = TransactionFilterCriteria(startDate: start, endDate: end);
      expect(criteria.dayCount, 31);
      expect(criteria.dayCount <= 31, isTrue);
    });

    test('Over 31 days can be detected and clamped', () {
      final start = DateTime(2026, 8, 1);
      final end = DateTime(2026, 9, 15);
      final criteria = TransactionFilterCriteria(startDate: start, endDate: end);
      expect(criteria.dayCount > 31, isTrue);

      // Clamping to 31 days
      final clampedEnd = start.add(const Duration(days: 30));
      final clampedCriteria = TransactionFilterCriteria(startDate: start, endDate: clampedEnd);
      expect(clampedCriteria.dayCount, 31);
    });
  });

  group('StickyDateHeaderDelegate', () {
    test('Delegate properties and extents', () {
      final formatter = CurrencyHelper.getFormatter('IDR');
      final delegate = StickyDateHeaderDelegate(
        date: DateTime.now(),
        count: 3,
        totalAmount: 75000,
        currencyFormatter: formatter,
      );

      expect(delegate.minExtent, 42.0);
      expect(delegate.maxExtent, 42.0);
    });
  });

  group('TransactionHistoryScreen UI & MyBCA UX', () {
    Widget buildTestApp({
      required DashboardBloc dashboardBloc,
      required AuthBloc authBloc,
      required NotificationBloc notificationBloc,
    }) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<DashboardBloc>.value(value: dashboardBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<NotificationBloc>.value(value: notificationBloc),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const TransactionHistoryScreen(),
        ),
      );
    }

    testWidgets('Renders MyBCA account header, filter bar, sticky headers, and transactions',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime.now();
      final user = AuthUser(
        id: 'u1',
        email: 'user@test.com',
        displayName: 'Budi Santoso',
      );

      final catFood = ExpenseCategory(
        id: 'c1',
        name: 'Makanan',
        icon: 'restaurant',
        color: '#EF4444',
      );
      final catTransport = ExpenseCategory(
        id: 'c2',
        name: 'Transportasi',
        icon: 'directions_car',
        color: '#3B82F6',
      );

      final wallet = WalletEntity(
        id: 'w101',
        name: 'Tahapan BCA',
        type: WalletType.personal,
        currency: 'IDR',
        dailyBudget: 200000,
        monthlyBudget: 5000000,
      );

      final List<ExpenseEntity> testExpenses = [
        ExpenseEntity(
          id: 'trx-001',
          amount: 50000,
          description: 'Kopi Kenangan',
          date: now,
          type: ExpenseType.routine,
          userId: 'u1',
          walletId: 'w101',
          category: catFood,
          creatorName: 'Budi Santoso',
        ),
        ExpenseEntity(
          id: 'trx-002',
          amount: 35000,
          description: 'Grab Car',
          date: now.subtract(const Duration(days: 1)),
          type: ExpenseType.nonRoutine,
          userId: 'u1',
          walletId: 'w101',
          category: catTransport,
          creatorName: 'Budi Santoso',
        ),
      ];

      final dashboardBloc = DashboardBloc();
      dashboardBloc.emit(dashboardBloc.state.copyWith(
        isInitialLoad: false,
        personalWallets: [wallet],
        selectedWallet: wallet,
        expenses: testExpenses,
        categories: [catFood, catTransport],
      ));

      final authBloc = AuthBloc();
      authBloc.emit(AuthState(currentUser: user));
      final notificationBloc = NotificationBloc();

      await tester.pumpWidget(
        buildTestApp(
          dashboardBloc: dashboardBloc,
          authBloc: authBloc,
          notificationBloc: notificationBloc,
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify AppBar and MyBCA Header Card
      expect(find.text('Mutasi Rekening'), findsOneWidget);
      expect(find.text('Tahapan BCA'), findsOneWidget);
      expect(find.text('TABUNGAN'), findsOneWidget);
      expect(find.text('TOTAL MUTASI (DEBIT)'), findsOneWidget);
      expect(find.text('2 Transaksi'), findsOneWidget);

      // 2. Verify Filter Bar Chips
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Rutin'), findsWidgets);
      expect(find.text('Non-Rutin'), findsOneWidget);

      // 3. Verify Transactions
      expect(find.text('Kopi Kenangan'), findsOneWidget);
      expect(find.text('Grab Car'), findsOneWidget);
      expect(find.text('DB'), findsWidgets);

      // 4. Test opening Transaction Detail Modal
      await tester.tap(find.text('Kopi Kenangan'));
      await tester.pumpAndSettle();

      expect(find.text('Detail Mutasi Rekening'), findsOneWidget);
      expect(find.text('Transaksi Berhasil'), findsOneWidget);
      expect(find.text('Pengeluaran Rutin'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();

      // 5. Test opening Calendar Filter Sheet
      await tester.tap(find.byIcon(Icons.calendar_month_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Filter Mutasi Rekening'), findsOneWidget);
      expect(find.text('Rentang mutasi maksimal 31 hari untuk melihat rincian transaksi.'), findsOneWidget);
      expect(find.text('Hari Ini'), findsOneWidget);
      expect(find.text('7 Hari'), findsOneWidget);
      expect(find.text('30 Hari'), findsOneWidget);
      expect(find.text('Bulan Ini'), findsOneWidget);

      // Select preset 'Hari Ini'
      await tester.tap(find.text('Hari Ini'));
      await tester.pumpAndSettle();

      expect(find.text('1 Hari dipilih'), findsOneWidget);

      // Apply filter
      await tester.tap(find.text('Tampilkan Mutasi (1 Hari)'));
      await tester.pumpAndSettle();

      // Filter is closed and applied
      expect(find.text('Filter Mutasi Rekening'), findsNothing);
    });
  });
}
