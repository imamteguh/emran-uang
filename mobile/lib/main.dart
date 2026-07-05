import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/expenses/presentation/bloc/dashboard_bloc.dart';
import 'features/expenses/presentation/bloc/dashboard_event.dart';
import 'features/expenses/presentation/bloc/notification_bloc.dart';
import 'features/expenses/presentation/bloc/notification_event.dart';
import 'features/expenses/presentation/screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const EmranUangApp());
}

class EmranUangApp extends StatelessWidget {
  const EmranUangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc()..add(const AuthAutoLoginRequested()),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final userId = authState.currentUser?.id;
          return MultiBlocProvider(
            key: ValueKey(userId),
            providers: [
              BlocProvider(
                create: (_) => DashboardBloc()..add(const DashboardInitializeRequested()),
              ),
              BlocProvider(
                create: (_) => NotificationBloc()..add(const NotificationFetchUnreadCountRequested()),
              ),
            ],
            child: MaterialApp(
              title: 'Wallet Share',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              home: const AuthWrapper(),
            ),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.initial || state.status == AuthStatus.loading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        if (state.isAuthenticated) {
          return const MainShellScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
