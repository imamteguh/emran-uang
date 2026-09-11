import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emran_uang/core/theme/app_theme.dart';
import 'package:emran_uang/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:emran_uang/features/auth/presentation/bloc/auth_state.dart';
import 'package:emran_uang/features/auth/presentation/bloc/auth_user.dart';
import 'package:emran_uang/features/expenses/domain/entities/expense.dart';
import 'package:emran_uang/features/expenses/domain/entities/wallet.dart';
import 'package:emran_uang/features/expenses/domain/entities/category_budget.dart';
import 'package:emran_uang/features/expenses/domain/entities/bill_reminder.dart';
import 'package:emran_uang/features/expenses/presentation/bloc/dashboard_bloc.dart';
import 'package:emran_uang/features/expenses/presentation/bloc/notification_bloc.dart';
import 'package:emran_uang/features/expenses/presentation/screens/dashboard_screen.dart';
import 'package:emran_uang/features/expenses/presentation/screens/main_shell.dart';
import 'package:emran_uang/features/expenses/presentation/widgets/dashboard/dashboard.dart';

void main() {
  setUpAll(() async {
    dotenv.loadFromString(envString: 'API_URL=https://dummy.api\n');
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp({
    required DashboardBloc dashboardBloc,
    required AuthBloc authBloc,
    required NotificationBloc notificationBloc,
    Widget? home,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DashboardBloc>.value(value: dashboardBloc),
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<NotificationBloc>.value(value: notificationBloc),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: home ?? const DashboardScreen(),
      ),
    );
  }

  testWidgets('DashboardScreen renders redesigned topbar, hero line chart, top-6 donut chart, and category budget',
      (tester) async {
    final now = DateTime.now();
    final user = AuthUser(
      id: 'u1',
      email: 'user@test.com',
      displayName: 'Emran User',
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
    final catBills = ExpenseCategory(
      id: 'c3',
      name: 'Tagihan',
      icon: 'receipt',
      color: '#10B981',
    );

    final wallet = WalletEntity(
      id: 'w1',
      name: 'Dompet Utama',
      type: WalletType.personal,
      currency: 'IDR',
      dailyBudget: 100000,
      monthlyBudget: 3000000,
      categoryBudgets: [
        CategoryBudgetEntity(
          id: 'cb1',
          walletId: 'w1',
          categoryId: 'c1',
          amount: 1500000,
          category: catFood,
        ),
      ],
    );

    final List<ExpenseEntity> expenses = [
      ExpenseEntity(
        id: 'e1',
        amount: 50000,
        description: 'Makan Siang',
        date: now,
        type: ExpenseType.routine,
        userId: 'u1',
        walletId: 'w1',
        category: catFood,
        creatorName: 'User',
      ),
      ExpenseEntity(
        id: 'e2',
        amount: 30000,
        description: 'Bensin Motor',
        date: now,
        type: ExpenseType.routine,
        userId: 'u1',
        walletId: 'w1',
        category: catTransport,
        creatorName: 'User',
      ),
      ExpenseEntity(
        id: 'e3',
        amount: 150000,
        description: 'Listrik PLN',
        date: now,
        type: ExpenseType.nonRoutine,
        userId: 'u1',
        walletId: 'w1',
        category: catBills,
        creatorName: 'User',
      ),
    ];

    final reminder = BillReminderEntity(
      id: 'b1',
      title: 'Internet Indihome',
      amount: 350000,
      dueDate: now.add(const Duration(days: 1)),
      periodicity: Periodicity.monthly,
      walletId: 'w1',
      userId: 'u1',
      status: ReminderStatus.active,
      notifyDaysBefore: 3,
      autoLogExpense: false,
      createdAt: now,
      updatedAt: now,
      expenses: [],
    );

    final dashboardBloc = DashboardBloc();
    dashboardBloc.emit(dashboardBloc.state.copyWith(
      isInitialLoad: false,
      personalWallets: [wallet],
      selectedWallet: wallet,
      expenses: expenses,
      categories: [catFood, catTransport, catBills],
      reminders: [reminder],
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

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // 1. Verify Topbar: App name, Subtitle, Wallet Selector, and Notification
    expect(find.text('Emran Uang'), findsOneWidget);
    expect(find.text('WalletShare'), findsOneWidget);
    expect(find.text('Dompet Utama'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

    // 2. Verify Monthly Spending Line Chart Hero Card
    expect(find.text('TOTAL PENGELUARAN'), findsOneWidget);
    expect(find.byType(MonthlySpendingLineChartHero), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    // 3. Verify Bill Alert Banner
    expect(find.byType(DashboardBillAlertBanner), findsOneWidget);

    // 4. Verify Category Donut Chart Card (Top 5 Kategori)
    expect(find.text('Top 5 Kategori'), findsOneWidget);
    expect(find.byType(CategoryDonutChartCard), findsOneWidget);
    expect(find.text('Makanan'), findsWidgets);
    expect(find.text('Transportasi'), findsWidgets);
    expect(find.text('Tagihan'), findsWidgets);

    // 5. Verify Routine Spending Card (Pengeluaran Rutin & Non-Rutin)
    expect(find.text('Pengeluaran Rutin & Non-Rutin'), findsOneWidget);
    expect(find.byType(RoutineSpendingCard), findsOneWidget);

    // 6. Verify Category Monthly Budget Card (Anggaran)
    expect(find.text('Anggaran'), findsOneWidget);
    expect(find.byType(CategoryMonthlyBudgetCard), findsOneWidget);

    // 7. Verify Redesigned Today Activity Feed
    expect(find.text('Aktivitas Hari Ini'), findsOneWidget);
    expect(find.byType(DashboardActivityFeed), findsOneWidget);
    expect(find.text('Makan Siang'), findsOneWidget);
    expect(find.text('Bensin Motor'), findsOneWidget);
    expect(find.text('Listrik PLN'), findsOneWidget);
  });

  testWidgets('MainShellScreen renders central add transaction button and opens options sheet',
      (tester) async {
    final dashboardBloc = DashboardBloc();
    dashboardBloc.emit(dashboardBloc.state.copyWith(isInitialLoad: false));
    final authBloc = AuthBloc();
    final notificationBloc = NotificationBloc();

    await tester.pumpWidget(
      buildTestApp(
        dashboardBloc: dashboardBloc,
        authBloc: authBloc,
        notificationBloc: notificationBloc,
        home: const MainShellScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify bottom nav items
    expect(find.text('Dompet'), findsWidgets);
    expect(find.text('Analisis'), findsOneWidget);
    expect(find.text('Tagihan'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    // Verify center add button in bottom nav
    final addButton = find.byWidgetPredicate(
      (widget) =>
          widget is Icon &&
          widget.icon == Icons.add_rounded &&
          widget.size == 30,
    );
    expect(addButton, findsOneWidget);

    // Tap add button to open bottom sheet options
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.text('Tambah Transaksi'), findsOneWidget);
    expect(find.text('Catat Manual'), findsOneWidget);
    expect(find.text('Pindai Struk dengan AI'), findsOneWidget);
  });
}
