import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around [FirebaseAuth].
///
/// Centralises auth access so screens depend on this service rather than
/// importing firebase_auth directly.
class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Stream of auth-state changes (null = signed out).
  Stream<User?> get userStream => _auth.authStateChanges();

  /// The currently signed-in user, or null.
  User? get currentUser => _auth.currentUser;

  Future<void> signOut() => _auth.signOut();
}
