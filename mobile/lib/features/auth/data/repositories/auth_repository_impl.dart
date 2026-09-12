import '../../domain/entities/auth_user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({
    AuthRemoteDataSource? remoteDataSource,
    AuthLocalDataSource? localDataSource,
  })  : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSourceImpl(),
        _localDataSource = localDataSource ?? AuthLocalDataSourceImpl();

  @override
  Future<void> fetchAuthConfig() async {
    await _remoteDataSource.fetchAuthConfig();
  }

  @override
  Future<AuthUser?> tryAutoLogin() async {
    await fetchAuthConfig();

    final rememberMe = await _localDataSource.isRememberMe();
    if (!rememberMe) {
      return null;
    }

    final accessToken = await _localDataSource.getAccessToken();
    final refreshToken = await _localDataSource.getRefreshToken();
    final cachedUser = await _localDataSource.getCachedUser();

    if (accessToken != null && refreshToken != null && cachedUser != null) {
      // Background verify
      _remoteDataSource.verifySession().then((verifiedUser) {
        if (verifiedUser != null) {
          _localDataSource.saveCachedUser(verifiedUser);
        }
      });
      return cachedUser;
    }
    return null;
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final result = await _remoteDataSource.login(
      email: email,
      password: password,
    );

    await _localDataSource.saveSession(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      user: result.user,
      rememberMe: rememberMe,
    );

    return result.user;
  }

  @override
  Future<AuthUser?> loginWithGoogle() async {
    final result = await _remoteDataSource.loginWithGoogle();
    if (result == null) return null;

    await _localDataSource.saveSession(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      user: result.user,
      rememberMe: true,
    );

    return result.user;
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final result = await _remoteDataSource.register(
      email: email,
      password: password,
      displayName: displayName,
    );

    await _localDataSource.saveSession(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      user: result.user,
      rememberMe: true,
    );

    return result.user;
  }

  @override
  Future<void> logout() async {
    await _remoteDataSource.clearFcmToken();
    await _localDataSource.clearSession();
  }

  @override
  Future<AuthUser> updateProfile({
    required String displayName,
    String? email,
    String? avatarUrl,
  }) async {
    final updatedUser = await _remoteDataSource.updateProfile(
      displayName: displayName,
      email: email,
      avatarUrl: avatarUrl,
    );

    final rememberMe = await _localDataSource.isRememberMe();
    if (rememberMe) {
      await _localDataSource.saveCachedUser(updatedUser);
    }

    return updatedUser;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
