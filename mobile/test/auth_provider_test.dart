import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:emran_uang/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:emran_uang/features/auth/presentation/bloc/auth_event.dart';
import 'package:emran_uang/features/auth/presentation/bloc/auth_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    dotenv.loadFromString(envString: 'API_URL=https://dummy.api\n');
  });

  group('AuthBloc Remember Me & Session Persistence Tests', () {
    setUp(() {
      // Initialize SharedPreferences with empty values before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('login with rememberMe = true should persist tokens and user data', () async {
      final authBloc = AuthBloc();
      final completer = Completer<bool>();

      authBloc.add(AuthLoginRequested(
        email: 'test@example.com',
        password: 'password123',
        rememberMe: true,
        completer: completer,
      ));

      final success = await completer.future;

      expect(success, isTrue);
      expect(authBloc.state.status, equals(AuthStatus.authenticated));
      expect(authBloc.state.currentUser?.email, equals('test@example.com'));

      // Check SharedPreferences values
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('remember_me'), isTrue);
      expect(prefs.getString('accessToken'), equals('mock_jwt_token_xxxx'));
      expect(prefs.getString('refreshToken'), equals('mock_refresh_token_xxxx'));

      final userJson = prefs.getString('user');
      expect(userJson, isNotNull);
      final userMap = jsonDecode(userJson!) as Map;
      expect(userMap['email'], equals('test@example.com'));
      expect(userMap['displayName'], equals('Imam Tamimi'));
    });

    test('login with rememberMe = false should not persist session', () async {
      final authBloc = AuthBloc();
      final completer = Completer<bool>();

      authBloc.add(AuthLoginRequested(
        email: 'test@example.com',
        password: 'password123',
        rememberMe: false,
        completer: completer,
      ));

      final success = await completer.future;

      expect(success, isTrue);
      expect(authBloc.state.status, equals(AuthStatus.authenticated));

      // Check SharedPreferences values (should be null or empty)
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('remember_me'), isFalse);
      expect(prefs.getString('accessToken'), isNull);
      expect(prefs.getString('refreshToken'), isNull);
      expect(prefs.getString('user'), isNull);
    });

    test('logout should clear all persisted credentials', () async {
      // Pre-populate SharedPreferences with active session
      SharedPreferences.setMockInitialValues({
        'remember_me': true,
        'accessToken': 'some-access-token',
        'refreshToken': 'some-refresh-token',
        'user': jsonEncode({
          'id': 'user_123',
          'email': 'active@example.com',
          'displayName': 'Active User',
        }),
      });

      final authBloc = AuthBloc();
      authBloc.add(const AuthAutoLoginRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(authBloc.state.status, equals(AuthStatus.authenticated));
      expect(authBloc.state.currentUser?.email, equals('active@example.com'));

      // Perform logout
      authBloc.add(const AuthLogoutRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(authBloc.state.status, equals(AuthStatus.unauthenticated));
      expect(authBloc.state.currentUser, isNull);

      // Verify SharedPreferences is cleared
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('accessToken'), isNull);
      expect(prefs.getString('refreshToken'), isNull);
      expect(prefs.getString('user'), isNull);
      expect(prefs.getBool('remember_me'), isNull);
    });

    test('tryAutoLogin should automatically load session when remember_me is active', () async {
      // Simulate app startup where credentials exist in local storage
      SharedPreferences.setMockInitialValues({
        'remember_me': true,
        'accessToken': 'some-access-token',
        'refreshToken': 'some-refresh-token',
        'user': jsonEncode({
          'id': 'user_123',
          'email': 'persisted@example.com',
          'displayName': 'Persisted User',
          'avatarUrl': 'https://example.com/avatar.png',
        }),
      });

      final authBloc = AuthBloc();
      
      // Initially not authenticated
      expect(authBloc.state.status, equals(AuthStatus.initial));

      // Perform auto login
      authBloc.add(const AuthAutoLoginRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      // Should be authenticated immediately
      expect(authBloc.state.status, equals(AuthStatus.authenticated));
      expect(authBloc.state.currentUser?.id, equals('user_123'));
      expect(authBloc.state.currentUser?.email, equals('persisted@example.com'));
      expect(authBloc.state.currentUser?.displayName, equals('Persisted User'));
      expect(authBloc.state.currentUser?.avatarUrl, equals('https://example.com/avatar.png'));
    });
  });
}
