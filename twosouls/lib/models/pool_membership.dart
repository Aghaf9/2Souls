import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// PoolMembershipStore
//
// Tracks which relationship pools the logged-in user has opted into.
// Being in a pool means OTHER users can unpack you from that pool —
// declining to join means you can't be unpacked in that context.
//
// This is display-only state for now (no real backend server-side
// filtering exists yet). The confirmation gate on the home screen and the
// leave-pool buttons are purely local UI, ready for backend wiring later.
// ---------------------------------------------------------------------------

enum RelationshipPool { shortTerm, longTerm }

extension RelationshipPoolX on RelationshipPool {
  String get displayName {
    switch (this) {
      case RelationshipPool.shortTerm: return 'Short Term';
      case RelationshipPool.longTerm: return 'Long Term';
    }
  }

  String get description {
    switch (this) {
      case RelationshipPool.shortTerm:
        return 'You\'ll enter the Short Term dating pool, meaning other users can unpack you when opening a Short Term pack. These are matches based on shared vibe, meeting preferences, and looks compatibility — no strings attached.';
      case RelationshipPool.longTerm:
        return 'You\'ll enter the Long Term dating pool, meaning other users can unpack you when opening a case or finding their soulmate. These are deeper matches based on career, hobbies, lifestyle, values, and core compatibility scores.';
    }
  }

  String get emoji {
    switch (this) {
      case RelationshipPool.shortTerm: return '⚡';
      case RelationshipPool.longTerm: return '❤️';
    }
  }
}

class PoolMembershipStore extends ChangeNotifier {
  PoolMembershipStore._();
  static final PoolMembershipStore instance = PoolMembershipStore._();

  final Set<RelationshipPool> _joined = {};

  bool isJoined(RelationshipPool pool) => _joined.contains(pool);
  bool get inShortTerm => _joined.contains(RelationshipPool.shortTerm);
  bool get inLongTerm => _joined.contains(RelationshipPool.longTerm);

  void join(RelationshipPool pool) {
    _joined.add(pool);
    notifyListeners();
  }

  void leave(RelationshipPool pool) {
    _joined.remove(pool);
    notifyListeners();
  }
}
