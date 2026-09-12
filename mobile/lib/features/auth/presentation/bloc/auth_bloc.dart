import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final DioClient _client = DioClient();

  AuthBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepositoryImpl(),
        super(const AuthState()) {
    // Setup auth failure listener to clear session on unauthorized token
    _client.onAuthFailure = () {
      add(const AuthFailureTriggered());
    };

    on<AuthAutoLoginRequested>(_onAutoLoginRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthProfileUpdated>(_onProfileUpdated);
    on<AuthPasswordChanged>(_onPasswordChanged);
    on<AuthFailureTriggered>(_onFailureTriggered);
  }

  Future<void> fetchAuthConfig() async {
    try {
      await _authRepository.fetchAuthConfig();
    } catch (e) {
      debugPrint('AuthBloc: fetchAuthConfig error: $e');
    }
  }

  Future<void> _onAutoLoginRequested(
    AuthAutoLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _authRepository.tryAutoLogin();
      if (user != null) {
        emit(state.copyWith(
          currentUser: user,
          status: AuthStatus.authenticated,
        ));
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (e) {
      debugPrint('AuthBloc: tryAutoLogin error: $e');
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      errorMessage: null,
      status: AuthStatus.loading,
    ));

    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
        rememberMe: event.rememberMe,
      );

      emit(state.copyWith(
        currentUser: user,
        isLoading: false,
        status: AuthStatus.authenticated,
      ));
      event.completer?.complete(true);
    } catch (e) {
      final message = _cleanErrorMessage(e);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: message,
        status: AuthStatus.failure,
      ));
      event.completer?.complete(false);
    }
  }

  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      errorMessage: null,
      status: AuthStatus.loading,
    ));

    try {
      final user = await _authRepository.loginWithGoogle();
      if (user == null) {
        emit(state.copyWith(
          isLoading: false,
          status: AuthStatus.unauthenticated,
        ));
        event.completer?.complete(false);
        return;
      }

      emit(state.copyWith(
        currentUser: user,
        isLoading: false,
        status: AuthStatus.authenticated,
      ));
      event.completer?.complete(true);
    } catch (e) {
      final errStr = e.toString();
      final isCancel = errStr.contains('popup_closed') || errStr.contains('canceled');

      emit(state.copyWith(
        isLoading: false,
        errorMessage: isCancel ? null : _cleanErrorMessage(e),
        status: isCancel ? AuthStatus.unauthenticated : AuthStatus.failure,
      ));
      event.completer?.complete(false);
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      errorMessage: null,
      status: AuthStatus.loading,
    ));

    try {
      final user = await _authRepository.register(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );

      emit(state.copyWith(
        currentUser: user,
        isLoading: false,
        status: AuthStatus.authenticated,
      ));
      event.completer?.complete(true);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: _cleanErrorMessage(e),
        status: AuthStatus.failure,
      ));
      event.completer?.complete(false);
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.logout();
    } catch (e) {
      debugPrint('AuthBloc: logout error: $e');
    }
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onProfileUpdated(
    AuthProfileUpdated event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      errorMessage: null,
    ));

    try {
      final user = await _authRepository.updateProfile(
        displayName: event.displayName,
        email: event.email,
        avatarUrl: event.avatarUrl,
      );

      emit(state.copyWith(
        currentUser: user,
        isLoading: false,
        status: AuthStatus.success,
      ));
      event.completer?.complete(true);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: _cleanErrorMessage(e),
        status: AuthStatus.failure,
      ));
      event.completer?.complete(false);
    }
  }

  Future<void> _onPasswordChanged(
    AuthPasswordChanged event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      errorMessage: null,
    ));

    try {
      await _authRepository.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );

      emit(state.copyWith(
        isLoading: false,
        status: AuthStatus.success,
      ));
      event.completer?.complete(true);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: _cleanErrorMessage(e),
        status: AuthStatus.failure,
      ));
      event.completer?.complete(false);
    }
  }

  void _onFailureTriggered(
    AuthFailureTriggered event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  String _cleanErrorMessage(dynamic e) {
    final str = e.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring(11);
    }
    return str;
  }
}
