import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import '../models/app_user.dart';
import 'auth_service.dart';

// ---------------------------------------------------------------------------
// UserService
//
// All Firestore read/write operations for the logged-in user's profile.
// Keeps a local in-memory cache (_current) so the UI can read it
// synchronously between Firestore updates.
//
// ⚠️  PHOTO UPLOAD DISABLED UNTIL LAUNCH — Firebase Storage now requires
// the Blaze (pay-as-you-go) plan to provision a bucket at all, which
// means putting a card on file. Deferred deliberately until launch
// rather than doing that now. uploadProfilePhoto() is stubbed below —
// search "RE-ENABLE AT LAUNCH" for the exact spot to restore once
// Storage is provisioned (see photo_service.dart for the same pattern).
// ---------------------------------------------------------------------------

class UserService {
  UserService._();
  static final UserService instance = UserService._();

  final _db = FirebaseFirestore.instance;

  AppUser? _current;
  AppUser? get current => _current;

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Fetch the logged-in user's document from Firestore and cache it.
  Future<AppUser?> loadCurrentUser() async {
    final uid = AuthService.instance.currentUid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    _current = AppUser.fromFirestore(doc);
    return _current;
  }

  /// Real-time stream of the user's document — use this in widgets that
  /// need to react to profile changes made on another device.
  Stream<AppUser?> watchCurrentUser() {
    final uid = AuthService.instance.currentUid;
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      _current = AppUser.fromFirestore(doc);
      return _current;
    });
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Partially update any profile fields. Only the provided keys are
  /// written — everything else is left unchanged.
  Future<void> updateProfile(Map<String, dynamic> fields) async {
    final uid = AuthService.instance.currentUid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update(fields);
    // Refresh local cache
    await loadCurrentUser();
  }

  /// PRE-LAUNCH STUB — always returns null and writes nothing.
  ///
  /// RE-ENABLE AT LAUNCH: once Firebase Storage is provisioned (Blaze
  /// plan active), restore this to actually upload via
  /// FirebaseStorage.instance and call updateProfile({'photoUrl': url}).
  /// Until then this deliberately does nothing so the app never depends
  /// on a Storage bucket that doesn't exist yet.
  Future<String?> uploadProfilePhoto(Uint8List bytes, String filename) async {
    // ignore: avoid_print
    print(
      'uploadProfilePhoto: skipped — Firebase Storage not provisioned '
      'yet (deferred until launch, see UserService header comment).',
    );
    return null;
  }

  /// Update pool membership fields.
  Future<void> setPoolMembership({bool? shortTerm, bool? longTerm}) async {
    final fields = <String, dynamic>{};
    if (shortTerm != null) fields['inShortTermPool'] = shortTerm;
    if (longTerm != null) fields['inLongTermPool'] = longTerm;
    if (fields.isNotEmpty) await updateProfile(fields);
  }

  /// Update compat scores after a quiz completion.
  Future<void> updateCompatScores(Map<String, int> scores) async {
    final merged = {...(_current?.compatScores ?? {}), ...scores};
    await updateProfile({'compatScores': merged});
  }

  /// Save face ranking score (0-100).
  Future<void> saveLooksScore(int score) async {
    await updateProfile({'looksScore': score});
  }
}
