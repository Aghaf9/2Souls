// ---------------------------------------------------------------------------
// UserMatchStats
//
// Computes "about your own matching activity" stats from CollectionStore
// for display on the user's own expanded profile card. These stats are
// purely derived from in-memory state (no real backend yet), so they
// reset on app restart.
//
// Stats shown:
//   - Total matches: how many people the user has claimed from cases/packs.
//   - Accepted back: how many of those are in the Chats section (the other
//     person "accepted" by the user keeping them, vs just winning them and
//     discarding). In the real product this would be bidirectional (the
//     other person also accepting), but without a backend this is the
//     closest meaningful proxy.
//   - Match rate: accepted / total, as a percentage.
//   - Avg chat lifespan: placeholder — without a real messaging backend
//     tracking first/last message timestamps, this can't be computed
//     accurately yet, so it shows a friendly stub.
// ---------------------------------------------------------------------------

class UserMatchStats {
  final int totalMatches;
  final int inChats;
  final int expired;

  const UserMatchStats({
    required this.totalMatches,
    required this.inChats,
    required this.expired,
  });

  /// How many claimed matches the user actively kept (moved into Chats).
  int get acceptedCount => inChats;

  /// Percentage of claimed matches that made it into Chats.
  int get matchRatePct =>
      totalMatches == 0 ? 0 : ((inChats / totalMatches) * 100).round();

  /// Placeholder for avg chat duration — not computable without a real
  /// messaging backend tracking timestamps. Shown as "--" in the UI.
  String get avgChatDuration => '--';

  static const UserMatchStats empty = UserMatchStats(
    totalMatches: 0,
    inChats: 0,
    expired: 0,
  );
}
