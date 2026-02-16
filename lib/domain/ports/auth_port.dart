/// Minimal user representation returned by [AuthPort].
class AuthUser {
  const AuthUser({required this.uid, required this.email});
  final String uid;

  /// Email address, or `null` for providers that don't supply one.
  final String? email;
}

/// Domain-level authentication exception.
///
/// Thrown by [AuthPort] implementations so the presentation layer
/// never needs to depend on infrastructure packages (e.g. firebase_auth).
class AuthException implements Exception {
  const AuthException({required this.code, this.message});

  /// Machine-readable error code (e.g. 'wrong-password', 'sign-in-cancelled').
  final String code;

  /// Optional human-readable message for logging.
  final String? message;

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
}

/// Port (interface) for authentication.
abstract class AuthPort {
  /// Currently signed-in user, or `null` if not authenticated.
  AuthUser? get currentUser;

  /// Stream that emits the current user on every auth state change.
  Stream<AuthUser?> get authStateChanges;

  /// Sign in with email and password. Throws [AuthException] on failure.
  Future<AuthUser> signInWithEmail(String email, String password);

  /// Create a new account with email and password. Throws [AuthException] on failure.
  Future<AuthUser> signUpWithEmail(String email, String password);

  /// Sign in using Google account. Throws [AuthException] on failure or cancellation.
  Future<AuthUser> signInWithGoogle();

  /// Sign out the current user.
  Future<void> signOut();
}
