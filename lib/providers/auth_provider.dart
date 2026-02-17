import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final service = ref.read(authServiceProvider);
  return AuthNotifier(service);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthLoading()) {
    _init();
  }

  Future<void> _init() async {
    if (kIsWeb) {
      state = AuthAuthenticated(UserProfile(
        displayName: 'Demo User',
        email: 'demo@google.com',
        ldap: 'demo',
      ));
      return;
    }
    try {
      final user = await _service.silentSignIn();
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> signIn() async {
    state = const AuthLoading();
    try {
      final user = await _service.signIn();
      if (!mounted) return;
      state = AuthAuthenticated(user);
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = const AuthError('Sign-in failed. Check your connection.');
    }
  }

  Future<void> signOut() async {
    if (kIsWeb) {
      _init();
      return;
    }
    await _service.signOut();
    state = const AuthUnauthenticated();
  }

  UserProfile? get currentUser {
    final s = state;
    if (s is AuthAuthenticated) return s.user;
    return null;
  }
}

sealed class AuthState {
  const AuthState();

  T when<T>({
    required T Function() loading,
    required T Function(UserProfile user) authenticated,
    required T Function() unauthenticated,
    required T Function(String message) error,
  }) {
    return switch (this) {
      AuthLoading() => loading(),
      AuthAuthenticated(user: final user) => authenticated(user),
      AuthUnauthenticated() => unauthenticated(),
      AuthError(message: final msg) => error(msg),
    };
  }
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserProfile user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
