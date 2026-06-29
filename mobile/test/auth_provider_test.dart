import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emran_uang/features/auth/presentation/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider Remember Me & Session Persistence Tests', () {
    setUp(() {
      // Initialize SharedPreferences with empty values before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('login with rememberMe = true should persist tokens and user data', () async {
      final authProvider = AuthProvider();

      // We will perform a login which triggers the mock fallback
      final success = await authProvider.login('test@example.com', 'password123', rememberMe: true);

      expect(success, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.email, equals('test@example.com'));

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
      final authProvider = AuthProvider();

      final success = await authProvider.login('test@example.com', 'password123', rememberMe: false);

      expect(success, isTrue);
      expect(authProvider.isAuthenticated, isTrue);

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

      final authProvider = AuthProvider();
      await authProvider.tryAutoLogin();

      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.email, equals('active@example.com'));

      // Perform logout
      await authProvider.logout();

      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.currentUser, isNull);

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

      final authProvider = AuthProvider();
      
      // Initially not authenticated
      expect(authProvider.isAuthenticated, isFalse);

      // Perform auto login
      await authProvider.tryAutoLogin();

      // Should be authenticated immediately
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.id, equals('user_123'));
      expect(authProvider.currentUser?.email, equals('persisted@example.com'));
      expect(authProvider.currentUser?.displayName, equals('Persisted User'));
      expect(authProvider.currentUser?.avatarUrl, equals('https://example.com/avatar.png'));
    });
  });
}
