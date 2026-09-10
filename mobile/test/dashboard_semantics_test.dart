import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emran_uang/core/theme/app_theme.dart';
import 'package:emran_uang/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:emran_uang/features/auth/presentation/bloc/auth_state.dart';
import 'package:emran_uang/features/auth/presentation/bloc/auth_user.dart';
import 'package:emran_uang/features/expenses/domain/entities/wallet.dart';
import 'package:emran_uang/features/expenses/presentation/bloc/dashboard_bloc.dart';
import 'package:emran_uang/features/expenses/presentation/screens/dashboard_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:emran_uang/features/expenses/presentation/bloc/notification_bloc.dart';

void main() {
  setUpAll(() async {
    dotenv.loadFromString(envString: 'API_URL=https://dummy.api\n');
  });

  testWidgets('DashboardScreen renders with semantics enabled without crashing',
      (tester) async {
    final handle = tester.ensureSemantics();

    final user = AuthUser(
      id: 'u1',
      email: 'test@example.com',
      displayName: 'Test User',
    );

    final wallet = WalletEntity(
      id: 'w1',
      name: 'Personal Wallet',
      type: WalletType.personal,
      currency: 'IDR',
      dailyBudget: 100000,
      monthlyBudget: 3000000,
    );

    final dashboardBloc = DashboardBloc();
    dashboardBloc.emit(dashboardBloc.state.copyWith(
      isInitialLoad: false,
      personalWallets: [wallet],
      selectedWallet: wallet,
      expenses: [],
    ));

    final authBloc = AuthBloc();
    authBloc.emit(AuthState(currentUser: user));

    final notificationBloc = NotificationBloc();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<DashboardBloc>.value(value: dashboardBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<NotificationBloc>.value(value: notificationBloc),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    handle.dispose();
  });

  testWidgets('DashboardScreen renders with empty monthly budget (empty state) without crashing',
      (tester) async {
    final handle = tester.ensureSemantics();

    final user = AuthUser(
      id: 'u1',
      email: 'test@example.com',
      displayName: 'Test User',
    );

    final wallet = WalletEntity(
      id: 'w1',
      name: 'Personal Wallet',
      type: WalletType.personal,
      currency: 'IDR',
      dailyBudget: null,
      monthlyBudget: null,
    );

    final dashboardBloc = DashboardBloc();
    dashboardBloc.emit(dashboardBloc.state.copyWith(
      isInitialLoad: false,
      personalWallets: [wallet],
      selectedWallet: wallet,
      expenses: [],
    ));

    final authBloc = AuthBloc();
    authBloc.emit(AuthState(currentUser: user));

    final notificationBloc = NotificationBloc();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<DashboardBloc>.value(value: dashboardBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<NotificationBloc>.value(value: notificationBloc),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Atur Anggaran Bulanan'), findsOneWidget);
    handle.dispose();
  });
}
