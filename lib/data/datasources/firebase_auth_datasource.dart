import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:gym_tracker/domain/ports/auth_port.dart';

/// Adapter implementing [AuthPort] using Firebase Auth + Google Sign-In.
///
/// All Firebase-specific exceptions are caught and re-thrown as
/// domain-level [AuthException] so the presentation layer never
/// depends on `package:firebase_auth`.
class FirebaseAuthDatasource implements AuthPort {
  FirebaseAuthDatasource({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthUser? _toAuthUser(User? user) {
    if (user == null) return null;
    return AuthUser(uid: user.uid, email: user.email);
  }

  AuthUser _requireUser(UserCredential cred) {
    final user = _toAuthUser(cred.user);
    if (user == null) {
      throw const AuthException(
        code: 'null-user',
        message: 'Firebase returned null user after authentication',
      );
    }
    return user;
  }

  @override
  AuthUser? get currentUser => _toAuthUser(_auth.currentUser);

  @override
  Stream<AuthUser?> get authStateChanges =>
      _auth.authStateChanges().map(_toAuthUser);

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _requireUser(cred);
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: e.code, message: e.message);
    }
  }

  @override
  Future<AuthUser> signUpWithEmail(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _requireUser(cred);
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: e.code, message: e.message);
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in was cancelled',
      );
    }

    try {
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      return _requireUser(cred);
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: e.code, message: e.message);
    }
  }

  @override
  Future<void> signOut() async {
    // Attempt both, even if one fails
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
