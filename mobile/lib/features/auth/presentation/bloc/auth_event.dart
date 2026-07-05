import 'dart:async';

abstract class AuthEvent {
  const AuthEvent();
}

class AuthAutoLoginRequested extends AuthEvent {
  const AuthAutoLoginRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;
  final Completer<bool>? completer;

  const AuthLoginRequested({
    required this.email,
    required this.password,
    required this.rememberMe,
    this.completer,
  });
}

class AuthGoogleLoginRequested extends AuthEvent {
  final Completer<bool>? completer;

  const AuthGoogleLoginRequested({this.completer});
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;
  final Completer<bool>? completer;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.displayName,
    this.completer,
  });
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthProfileUpdated extends AuthEvent {
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final Completer<bool>? completer;

  const AuthProfileUpdated({
    required this.displayName,
    this.email,
    this.avatarUrl,
    this.completer,
  });
}

class AuthPasswordChanged extends AuthEvent {
  final String currentPassword;
  final String newPassword;
  final Completer<bool>? completer;

  const AuthPasswordChanged({
    required this.currentPassword,
    required this.newPassword,
    this.completer,
  });
}

class AuthFailureTriggered extends AuthEvent {
  const AuthFailureTriggered();
}
