import 'auth_user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, success, failure }

class AuthState {
  final AuthUser? currentUser;
  final bool isLoading;
  final String? errorMessage;
  final AuthStatus status;

  const AuthState({
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
    this.status = AuthStatus.initial,
  });

  bool get isAuthenticated => currentUser != null;

  AuthState copyWith({
    AuthUser? currentUser,
    bool? isLoading,
    String? errorMessage,
    AuthStatus? status,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      status: status ?? this.status,
    );
  }
}
