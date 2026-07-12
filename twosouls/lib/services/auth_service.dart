import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';

// ---------------------------------------------------------------------------
// AuthService
//
// Wraps FirebaseAuth for all authentication operations:
//   - Google Sign-In (the only sign-in method now — see signInWithGoogle)
//   - Sign out
//   - Stream of auth state changes (used by AuthGate to route the app)
//
// The Firestore user document lives at /users/{uid} and is created once
// on first Google sign-in with sensible defaults, with dob left null
// (Google doesn't reliably provide birthdate — see the note on
// signInWithGoogle). All profile updates go through UserService, not
// here.
//
// ── google_sign_in v7 setup notes ───────────────────────────────────────
// This package's API changed significantly in v7: GoogleSignIn.instance is
// now a singleton and MUST have initialize() called (and awaited) once
// before authenticate() or anything else is called. Call
// AuthService.instance.initializeGoogleSignIn() once at app startup
// (e.g. in main() after Firebase.initializeApp()), not per sign-in
// attempt.
// ---------------------------------------------------------------------------

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  bool _googleSignInInitialized = false;

  // Required for google_sign_in on web specifically — unlike mobile,
  // which picks this up automatically from google-services.json /
  // GoogleService-Info.plist, the web plugin throws an assertion error
  // at initialize() without an explicit client ID. Find yours at:
  // Firebase Console -> Authentication -> Sign-in method -> Google ->
  // "Web SDK configuration" -> Web client ID.
  //
  // Passed via --dart-define so it's not hardcoded in source, same
  // pattern as REMOVE_BG_API_KEY in photo_service.dart. Run with:
  //   flutter run -d chrome \
  //     --dart-define=GOOGLE_WEB_CLIENT_ID=your_id.apps.googleusercontent.com
  static const String _webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// Stream of the current Firebase user — null when signed out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in Firebase user, or null.
  User? get currentUser => _auth.currentUser;

  String? get currentUid => _auth.currentUser?.uid;

  // ── Google Sign-In setup ─────────────────────────────────────────────────

  /// Must be called once (and awaited) before signInWithGoogle() —
  /// call this from main() after Firebase.initializeApp(). Safe to call
  /// more than once; only initializes on the first call.
  Future<void> initializeGoogleSignIn() async {
    if (_googleSignInInitialized) return;

    if (kIsWeb && _webClientId.isEmpty) {
      throw StateError(
        'GOOGLE_WEB_CLIENT_ID was not provided. Google Sign-In on web '
        'requires it. Run with '
        '--dart-define=GOOGLE_WEB_CLIENT_ID=your_id.apps.googleusercontent.com '
        '(find this in Firebase Console -> Authentication -> Sign-in '
        'method -> Google -> Web SDK configuration).',
      );
    }

    await GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? _webClientId : null,
    );
    _googleSignInInitialized = true;
  }

  // ── Google Sign-In ───────────────────────────────────────────────────────

  Future<AuthResult> signInWithGoogle() async {
    try {
      if (!_googleSignInInitialized) {
        // Defensive fallback in case initializeGoogleSignIn() wasn't
        // called at startup — should not normally be hit.
        await initializeGoogleSignIn();
      }

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        return AuthResult.error(
          'Google Sign-In is not supported on this platform.',
        );
      }

      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate();

      // authenticate() gives identity (idToken). accessToken is a
      // separate authorization step in v7 — Firebase's credential can
      // work with just the idToken, but requesting the access token too
      // keeps this future-proof if Firebase ever tightens the
      // requirement.
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        return AuthResult.error('Google Sign-In did not return an ID token.');
      }

      String? accessToken;
      try {
        final authorization = await account.authorizationClient
            .authorizationForScopes(['email', 'profile']);
        accessToken = authorization?.accessToken;
      } catch (_) {
        // Non-fatal — idToken alone is enough for Firebase in most cases.
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        // First-ever sign-in for this account — create the Firestore
        // profile doc. dob is intentionally left null: Google's basic
        // sign-in scope does not reliably include birthdate (that
        // requires a separately-approved, heavily-restricted People API
        // scope) — the app's age-gate screen collects it instead.
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email ?? '',
          'name': user.displayName ?? '',
          'dob': null,
          'createdAt': FieldValue.serverTimestamp(),
          'bio': '',
          'career': '',
          'institution': '',
          'location': '',
          'photoUrl': user.photoURL,
          'looksScore': null,
          'hobbyIds': [],
          'careerId': null,
          'sexualOrientation': null,
          'lookingFor': null,
          'countryCode': null,
          'inShortTermPool': false,
          'inLongTermPool': false,
          'compatScores': {
            'hobbies': 0,
            'careerEducation': 0,
            'looks': 0,
            'lifestyle': 0,
            'coreValues': 0,
          },
        });
      }

      return AuthResult.success(isNewUser: isNewUser);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return AuthResult.error('Sign-in was canceled.');
      }
      return AuthResult.error('Google Sign-In failed: ${e.code}');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_friendlyError(e.code));
    } catch (e) {
      return AuthResult.error('Something went wrong. Please try again.');
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Non-fatal — Firebase sign-out already succeeded, which is what
      // actually matters for the app's auth state.
    }
  }

  // ── Error messages ────────────────────────────────────────────────────────

  String _friendlyError(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'invalid-credential':
        return 'That sign-in could not be verified. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

// ── Result type ───────────────────────────────────────────────────────────────

class AuthResult {
  final bool success;
  final String? errorMessage;
  final bool isNewUser;

  const AuthResult._({
    required this.success,
    this.errorMessage,
    this.isNewUser = false,
  });

  factory AuthResult.success({bool isNewUser = false}) =>
      AuthResult._(success: true, isNewUser: isNewUser);
  factory AuthResult.error(String msg) =>
      AuthResult._(success: false, errorMessage: msg);
}
