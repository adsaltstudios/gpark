import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  /// Sign in with Google. Rejects non-@google.com accounts.
  Future<UserProfile> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw AuthException('Sign-in was cancelled.');
    }
    return _validateAndConvert(account);
  }

  /// Attempt silent sign-in (returning user with valid token).
  Future<UserProfile?> silentSignIn() async {
    final account = await _googleSignIn.signInSilently();
    if (account == null) return null;
    return _validateAndConvert(account);
  }

  /// Sign out and clear cached credentials.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Get current signed-in user without triggering sign-in flow.
  Future<UserProfile?> getCurrentUser() async {
    final account = _googleSignIn.currentUser;
    if (account == null) return null;
    return _validateAndConvert(account);
  }

  UserProfile _validateAndConvert(GoogleSignInAccount account) {
    if (!account.email.endsWith('@google.com')) {
      _googleSignIn.signOut();
      throw AuthException(
        'Please sign in with your Google corporate account.',
      );
    }
    return UserProfile.fromGoogleSignIn(account);
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
