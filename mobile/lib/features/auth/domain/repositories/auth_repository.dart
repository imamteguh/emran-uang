import '../entities/auth_user_entity.dart';

abstract class AuthRepository {
  /// Fetches remote auth configuration (such as googleClientId).
  Future<void> fetchAuthConfig();

  /// Attempts to restore session from persistent local storage.
  Future<AuthUser?> tryAutoLogin();

  /// Logs in a user with email and password credentials.
  Future<AuthUser> login({
    required String email,
    required String password,
    required bool rememberMe,
  });

  /// Logs in a user using Google Sign-In OAuth.
  Future<AuthUser?> loginWithGoogle();

  /// Registers a new user account.
  Future<AuthUser> register({
    required String email,
    required String password,
    required String displayName,
  });

  /// Logs out the user, clearing tokens, push notifications, and cached session.
  Future<void> logout();

  /// Updates user profile details (displayName, optional email, optional avatarUrl).
  Future<AuthUser> updateProfile({
    required String displayName,
    String? email,
    String? avatarUrl,
  });

  /// Updates user password with current password verification.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
