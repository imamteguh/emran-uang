import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:emran_uang/core/theme/app_theme.dart';
import 'package:emran_uang/features/auth/domain/entities/auth_user_entity.dart';
import 'package:emran_uang/features/auth/domain/repositories/auth_repository.dart';
import 'package:emran_uang/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:emran_uang/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:emran_uang/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:emran_uang/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:emran_uang/features/auth/presentation/screens/login_screen.dart';
import 'package:emran_uang/features/auth/presentation/screens/register_screen.dart';
import 'package:emran_uang/features/auth/presentation/screens/change_password_screen.dart';
import 'package:emran_uang/features/auth/presentation/screens/update_profile_screen.dart';
import 'package:emran_uang/features/auth/presentation/widgets/password_strength_indicator.dart';

// Fake remote data source for testing
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  bool fetchConfigCalled = false;
  bool logoutCalled = false;
  bool changePasswordCalled = false;

  @override
  Future<void> fetchAuthConfig() async {
    fetchConfigCalled = true;
  }

  @override
  Future<AuthUser?> verifySession() async {
    return AuthUser(
      id: 'usr_verified',
      email: 'verified@example.com',
      displayName: 'Verified User',
      authProvider: 'EMAIL',
    );
  }

  @override
  Future<({String accessToken, String refreshToken, AuthUser user})> login({
    required String email,
    required String password,
  }) async {
    return (
      accessToken: 'token_123',
      refreshToken: 'refresh_123',
      user: AuthUser(
        id: 'usr_1',
        email: email,
        displayName: 'Test User',
        authProvider: 'EMAIL',
      ),
    );
  }

  @override
  Future<({String accessToken, String refreshToken, AuthUser user})?> loginWithGoogle() async {
    return (
      accessToken: 'google_token_123',
      refreshToken: 'google_refresh_123',
      user: AuthUser(
        id: 'usr_google',
        email: 'google@example.com',
        displayName: 'Google User',
        authProvider: 'GOOGLE',
      ),
    );
  }

  @override
  Future<({String accessToken, String refreshToken, AuthUser user})> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return (
      accessToken: 'reg_token',
      refreshToken: 'reg_refresh',
      user: AuthUser(
        id: 'usr_reg',
        email: email,
        displayName: displayName,
        authProvider: 'EMAIL',
      ),
    );
  }

  @override
  Future<void> clearFcmToken() async {
    logoutCalled = true;
  }

  @override
  Future<AuthUser> updateProfile({
    required String displayName,
    String? email,
    String? avatarUrl,
  }) async {
    return AuthUser(
      id: 'usr_updated',
      email: email ?? 'updated@example.com',
      displayName: displayName,
      avatarUrl: avatarUrl,
      authProvider: 'EMAIL',
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalled = true;
  }
}

// Fake repository for testing presentation screens
class FakeAuthRepository implements AuthRepository {
  final AuthUser? testUser;
  FakeAuthRepository({this.testUser});

  @override
  Future<void> fetchAuthConfig() async {}

  @override
  Future<AuthUser?> tryAutoLogin() async => testUser;

  @override
  Future<AuthUser> login({required String email, required String password, required bool rememberMe}) async {
    return testUser ?? AuthUser(id: '1', email: email, displayName: 'User');
  }

  @override
  Future<AuthUser?> loginWithGoogle() async => testUser;

  @override
  Future<AuthUser> register({required String email, required String password, required String displayName}) async {
    return AuthUser(id: '2', email: email, displayName: displayName);
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthUser> updateProfile({required String displayName, String? email, String? avatarUrl}) async {
    return AuthUser(id: '3', email: email ?? 'u@u.com', displayName: displayName, avatarUrl: avatarUrl);
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    dotenv.loadFromString(envString: 'API_URL=https://dummy.api\n');
  });

  group('Clean Architecture Data & Domain Layer Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('AuthLocalDataSource saves, retrieves, and clears session correctly', () async {
      final localDataSource = AuthLocalDataSourceImpl();
      final user = AuthUser(
        id: 'usr_local',
        email: 'local@example.com',
        displayName: 'Local User',
        authProvider: 'EMAIL',
      );

      expect(await localDataSource.isRememberMe(), isFalse);

      await localDataSource.saveSession(
        accessToken: 'acc_tok',
        refreshToken: 'ref_tok',
        user: user,
        rememberMe: true,
      );

      expect(await localDataSource.isRememberMe(), isTrue);
      expect(await localDataSource.getAccessToken(), equals('acc_tok'));
      expect(await localDataSource.getRefreshToken(), equals('ref_tok'));

      final cachedUser = await localDataSource.getCachedUser();
      expect(cachedUser, isNotNull);
      expect(cachedUser?.email, equals('local@example.com'));

      await localDataSource.clearSession();
      expect(await localDataSource.getAccessToken(), isNull);
      expect(await localDataSource.getCachedUser(), isNull);
    });

    test('AuthRepositoryImpl executes login, saves session, and returns user', () async {
      final fakeRemote = FakeAuthRemoteDataSource();
      final localDataSource = AuthLocalDataSourceImpl();
      final repo = AuthRepositoryImpl(
        remoteDataSource: fakeRemote,
        localDataSource: localDataSource,
      );

      final user = await repo.login(
        email: 'hello@test.com',
        password: 'password123',
        rememberMe: true,
      );

      expect(user.email, equals('hello@test.com'));
      expect(await localDataSource.getAccessToken(), equals('token_123'));
    });

    test('AuthRepositoryImpl updates profile and persists to local cache', () async {
      final fakeRemote = FakeAuthRemoteDataSource();
      final localDataSource = AuthLocalDataSourceImpl();
      final repo = AuthRepositoryImpl(
        remoteDataSource: fakeRemote,
        localDataSource: localDataSource,
      );

      await localDataSource.setRememberMe(true);
      final updated = await repo.updateProfile(
        displayName: 'New Name',
        email: 'new@email.com',
        avatarUrl: '🦊',
      );

      expect(updated.displayName, equals('New Name'));
      expect(updated.avatarUrl, equals('🦊'));

      final cached = await localDataSource.getCachedUser();
      expect(cached?.displayName, equals('New Name'));
    });
  });

  group('Presentation Screen & Widget Tests', () {
    late AuthBloc authBloc;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authBloc = AuthBloc(
        authRepository: FakeAuthRepository(
          testUser: AuthUser(
            id: 'u_123',
            email: 'user@example.com',
            displayName: 'John Doe',
            authProvider: 'EMAIL',
            createdAt: DateTime(2025, 1, 15),
          ),
        ),
      );
    });

    tearDown(() {
      authBloc.close();
    });

    Widget createTestApp(Widget child) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: child,
        ),
      );
    }

    testWidgets('PasswordStrengthIndicator renders bar and checks dynamically', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordStrengthIndicator(
              password: 'P@ssword123',
              confirmPassword: 'P@ssword123',
            ),
          ),
        ),
      );

      expect(find.text('Kekuatan Kata Sandi:'), findsOneWidget);
      expect(find.text('Min. 8 Karakter'), findsOneWidget);
      expect(find.text('Huruf Besar & Kecil'), findsOneWidget);
      expect(find.text('Angka / Simbol'), findsOneWidget);
      expect(find.text('Sandi Cocok'), findsOneWidget);
    });

    testWidgets('LoginScreen renders header, social button, form inputs and submit button', (tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Selamat Datang Kembali'), findsOneWidget);
      expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
      expect(find.text('Alamat Email'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Ingat saya'), findsOneWidget);
      expect(find.text('Lupa Sandi?'), findsOneWidget);
      expect(find.text('Masuk Sekarang'), findsOneWidget);
      expect(find.text('Buat akun bersama'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders registration form and strength indicator', (tester) async {
      await tester.pumpWidget(createTestApp(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Buat Akun Baru'), findsOneWidget);
      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Alamat Email'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Konfirmasi Kata Sandi'), findsOneWidget);
      expect(find.text('Daftar Sekarang'), findsOneWidget);
      expect(find.text('Masuk di sini'), findsOneWidget);
    });

    testWidgets('ChangePasswordScreen renders for email user with strength indicator', (tester) async {
      await tester.pumpWidget(createTestApp(const ChangePasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Ubah Kata Sandi'), findsOneWidget);
      expect(find.text('Kata Sandi Saat Ini'), findsOneWidget);
      expect(find.text('Kata Sandi Baru'), findsOneWidget);
      expect(find.text('Konfirmasi Kata Sandi Baru'), findsOneWidget);
      expect(find.text('Perbarui Kata Sandi'), findsOneWidget);
    });

    testWidgets('UpdateProfileScreen renders profile inputs and metadata', (tester) async {
      await tester.pumpWidget(createTestApp(const UpdateProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profil'), findsOneWidget);
      expect(find.text('Ubah Foto Profil'), findsOneWidget);
      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Alamat Email'), findsOneWidget);
      expect(find.text('Tipe Autentikasi'), findsOneWidget);
      expect(find.text('Terdaftar Sejak'), findsOneWidget);
      expect(find.text('ID Akun'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
    });
  });
}
