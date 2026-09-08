import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
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
  await initializeDateFormatting();

  // Global Flutter error handler to log errors rather than silently failing
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FLUTTER ERROR] ${details.exception}');
    debugPrint('[FLUTTER STACK] ${details.stack}');
  };

  // Custom ErrorWidget boundary to prevent blank white screens on widget crashes
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('[CRITICAL WIDGET ERROR] ${details.exception}');
    return Material(
      color: const Color(0xFFF7F9FB),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Tampilan Mengalami Kesalahan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${details.exception}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

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
