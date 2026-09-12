import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/auth_user_entity.dart';

abstract class AuthLocalDataSource {
  Future<bool> isRememberMe();
  Future<void> setRememberMe(bool value);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<AuthUser?> getCachedUser();
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,
    required bool rememberMe,
  });
  Future<void> saveCachedUser(AuthUser user);
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  @override
  Future<bool> isRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('remember_me') ?? false;
  }

  @override
  Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', value);
  }

  @override
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  @override
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refreshToken');
  }

  @override
  Future<AuthUser?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null) return null;
    try {
      final map = jsonDecode(userJson) as Map<dynamic, dynamic>;
      return AuthUser.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', rememberMe);
    if (rememberMe) {
      await prefs.setString('accessToken', accessToken);
      await prefs.setString('refreshToken', refreshToken);
      await prefs.setString('user', jsonEncode(user.toJson()));
    } else {
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await prefs.remove('user');
    }
  }

  @override
  Future<void> saveCachedUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  @override
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('user');
    await prefs.remove('remember_me');
  }
}
