import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  static final DioClient _singleton = DioClient._internal();
  late final Dio dio;

  // In-memory token storage
  String? _accessToken;
  String? _refreshToken;

  // Callback to notify UI when authentication fails completely
  VoidCallback? onAuthFailure;

  factory DioClient() {
    return _singleton;
  }

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:3000/api', // default local Express API
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Inject interceptors for logging and JWT attachment
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Check if it is a 401 Unauthorized error and we have a refresh token
          if (error.response?.statusCode == 401 && _refreshToken != null) {
            try {
              // Create a fresh Dio instance to make the refresh request
              // this avoids triggering this interceptor again
              final refreshDio = Dio(
                BaseOptions(
                  baseUrl: dio.options.baseUrl,
                  connectTimeout: const Duration(seconds: 10),
                  receiveTimeout: const Duration(seconds: 10),
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                  },
                ),
              );

              final response = await refreshDio.post(
                '/auth/refresh',
                data: {'refreshToken': _refreshToken},
              );

              if (response.statusCode == 200 &&
                  response.data != null &&
                  response.data['success'] == true) {
                final data = response.data['data'];
                final newAccess = data['accessToken'] as String;
                final newRefresh = data['refreshToken'] as String;

                // Update tokens in memory
                setTokens(accessToken: newAccess, refreshToken: newRefresh);

                // Update SharedPreferences if remember_me is enabled
                final prefs = await SharedPreferences.getInstance();
                final rememberMe = prefs.getBool('remember_me') ?? false;
                if (rememberMe) {
                  await prefs.setString('accessToken', newAccess);
                  await prefs.setString('refreshToken', newRefresh);
                }

                // Retry the original request
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $newAccess';

                final retryResponse = await refreshDio.fetch(options);
                return handler.resolve(retryResponse);
              }
            } catch (e) {
              debugPrint('Token refresh failed: $e');
              // Clear tokens and trigger auth failure callback
              _accessToken = null;
              _refreshToken = null;
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('accessToken');
              await prefs.remove('refreshToken');
              await prefs.remove('user');
              
              if (onAuthFailure != null) {
                onAuthFailure!();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  void setTokens({String? accessToken, String? refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  // Backward compatibility method
  void setToken(String? token) {
    _accessToken = token;
  }

  String? get token => _accessToken;
  String? get refreshToken => _refreshToken;

  bool get isAuthenticated => _accessToken != null;

  /// Custom error parser to extract backend validation errors
  String getErrorMessage(DioException exception) {
    if (exception.response?.data != null &&
        exception.response?.data is Map &&
        exception.response?.data['message'] != null) {
      return exception.response?.data['message'].toString() ?? 'An error occurred';
    }
    return exception.message ?? 'Network error occurred';
  }
}
