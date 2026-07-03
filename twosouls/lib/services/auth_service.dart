import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

// ---------------------------------------------------------------------------
// AuthService
//
// Wraps FirebaseAuth for all authentication operations:
//   - Email/password sign up (creates Firestore user doc on first sign up)
//   - Email/password sign in
//   - Sign out
//   - Stream of auth state changes (used by AuthGate to route the app)
//   - Password reset email
//
// The Firestore user document lives at /users/{uid} and is created once
// on sign-up with sensible defaults. All profile updates go through
// UserService, not here.
// ---------------------------------------------------------------------------

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  /// Stream of the current Firebase user — null when signed out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in Firebase user, or null.
  User? get currentUser => _auth.currentUser;

  String? get currentUid => _auth.currentUser?.uid;

  // ── Sign up ───────────────────────────────────────────────────────────────

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
    required DateTime dob,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Create the user document in Firestore immediately after sign-up.
      // This is the single source of truth for all profile data.
      await _db.collection('users').doc(cred.user!.uid).set({
        'uid':       cred.user!.uid,
        'email':     email.trim(),
        'name':      name.trim(),
        'dob':       Timestamp.fromDate(dob),
        'createdAt': FieldValue.serverTimestamp(),
        // Profile fields — blank until the user fills them in
        'bio':             '',
        'career':          '',
        'institution':     '',
        'location':        '',
        'photoUrl':        null,
        'looksScore':      null,
        'hobbyIds':        [],
        'careerId':        null,
        'sexualOrientation': null,
        'lookingFor':      null,
        // Pool membership
        'inShortTermPool': false,
        'inLongTermPool':  false,
        // Compat scores — populated once quizzes are completed
        'compatScores': {
          'hobbies':          0,
          'careerEducation':  0,
          'looks':            0,
          'lifestyle':        0,
          'coreValues':       0,
        },
      });

      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_friendlyError(e.code));
    } catch (e) {
      return AuthResult.error('Something went wrong. Please try again.');
    }
  }

  // ── Sign in ───────────────────────────────────────────────────────────────

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_friendlyError(e.code));
    } catch (e) {
      return AuthResult.error('Something went wrong. Please try again.');
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> signOut() => _auth.signOut();

  // ── Password reset ────────────────────────────────────────────────────────

  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_friendlyError(e.code));
    }
  }

  // ── Error messages ────────────────────────────────────────────────────────

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':    return 'An account with this email already exists.';
      case 'invalid-email':           return 'Please enter a valid email address.';
      case 'weak-password':           return 'Password must be at least 6 characters.';
      case 'user-not-found':          return 'No account found with this email.';
      case 'wrong-password':          return 'Incorrect password.';
      case 'user-disabled':           return 'This account has been disabled.';
      case 'too-many-requests':       return 'Too many attempts. Please try again later.';
      case 'network-request-failed':  return 'No internet connection.';
      default:                        return 'Authentication failed. Please try again.';
    }
  }
}

// ── Result type ───────────────────────────────────────────────────────────────

class AuthResult {
  final bool success;
  final String? errorMessage;

  const AuthResult._({required this.success, this.errorMessage});

  factory AuthResult.success() => const AuthResult._(success: true);
  factory AuthResult.error(String msg) => AuthResult._(success: false, errorMessage: msg);
}
