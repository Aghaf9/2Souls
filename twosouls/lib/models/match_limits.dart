import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// MatchLimits
//
// Tracks the independent rate limits across both flows:
//   - Open Case (Long Term): 2 opens per rolling 24h window.
//   - Top Match walkout (Long Term, 80+ compatibility draw): 1 open per
//     rolling 7-day window.
//   - Short Term pack opening: 2 opens per rolling 6h window.
// All use real wall-clock time (DateTime.now()), so they persist for the
// lifetime of the app process and reset based on actual elapsed time, not
// a simulated clock. There is no backend yet, so this resets if the app
// process restarts — see the TODO at the bottom of this file.
// ---------------------------------------------------------------------------

class MatchLimits extends ChangeNotifier {
  MatchLimits._();
  static final MatchLimits instance = MatchLimits._();

  static const int kMaxCasesPerDay = 2;
  static const Duration kCaseWindow = Duration(hours: 24);
  static const Duration kTopMatchWindow = Duration(days: 7);
  static const int kMaxPacksPerWindow = 2;
  static const Duration kPackWindow = Duration(hours: 6);

  final List<DateTime> _caseOpenTimestamps = [];
  DateTime? _lastTopMatchOpen;
  final List<DateTime> _packOpenTimestamps = [];

  // ── Open Case (2 per day) ──────────────────────────────────────────────

  int get casesUsedToday {
    final cutoff = DateTime.now().subtract(kCaseWindow);
    _caseOpenTimestamps.removeWhere((t) => t.isBefore(cutoff));
    return _caseOpenTimestamps.length;
  }

  int get casesRemainingToday =>
      (kMaxCasesPerDay - casesUsedToday).clamp(0, kMaxCasesPerDay);

  bool get canOpenCase => casesRemainingToday > 0;

  /// Time until the oldest case-open timestamp rolls out of the 24h window,
  /// i.e. when the next slot frees up. Null if a slot is available now.
  Duration? get timeUntilNextCaseSlot {
    if (canOpenCase) return null;
    final cutoff = DateTime.now().subtract(kCaseWindow);
    _caseOpenTimestamps.removeWhere((t) => t.isBefore(cutoff));
    if (_caseOpenTimestamps.isEmpty) return null;
    final oldest = _caseOpenTimestamps.reduce((a, b) => a.isBefore(b) ? a : b);
    final freesAt = oldest.add(kCaseWindow);
    final remaining = freesAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void recordCaseOpen() {
    _caseOpenTimestamps.add(DateTime.now());
    notifyListeners();
  }

  // ── Top Match walkout (1 per 7 days) ───────────────────────────────────

  bool get canOpenTopMatch {
    if (_lastTopMatchOpen == null) return true;
    return DateTime.now().difference(_lastTopMatchOpen!) >= kTopMatchWindow;
  }

  Duration? get timeUntilNextTopMatch {
    if (canOpenTopMatch) return null;
    final freesAt = _lastTopMatchOpen!.add(kTopMatchWindow);
    final remaining = freesAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void recordTopMatchOpen() {
    _lastTopMatchOpen = DateTime.now();
    notifyListeners();
  }

  // ── Short Term pack opening (2 per 6h) ──────────────────────────────────

  int get packsUsedInWindow {
    final cutoff = DateTime.now().subtract(kPackWindow);
    _packOpenTimestamps.removeWhere((t) => t.isBefore(cutoff));
    return _packOpenTimestamps.length;
  }

  int get packsRemainingInWindow =>
      (kMaxPacksPerWindow - packsUsedInWindow).clamp(0, kMaxPacksPerWindow);

  bool get canOpenPack => packsRemainingInWindow > 0;

  /// Time until the oldest pack-open timestamp rolls out of the 6h window,
  /// i.e. when the next slot frees up. Null if a slot is available now.
  Duration? get timeUntilNextPackSlot {
    if (canOpenPack) return null;
    final cutoff = DateTime.now().subtract(kPackWindow);
    _packOpenTimestamps.removeWhere((t) => t.isBefore(cutoff));
    if (_packOpenTimestamps.isEmpty) return null;
    final oldest = _packOpenTimestamps.reduce((a, b) => a.isBefore(b) ? a : b);
    final freesAt = oldest.add(kPackWindow);
    final remaining = freesAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void recordPackOpen() {
    _packOpenTimestamps.add(DateTime.now());
    notifyListeners();
  }

  /// Formats a Duration as "Xh Ym" or "Xd Yh" for display in countdown UI.
  static String formatCountdown(Duration d) {
    if (d.inDays >= 1) {
      final hours = d.inHours % 24;
      return '${d.inDays}d ${hours}h';
    }
    if (d.inHours >= 1) {
      final mins = d.inMinutes % 60;
      return '${d.inHours}h ${mins}m';
    }
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '${mins}m ${secs}s';
  }
}

// ---------------------------------------------------------------------------
// TODO: persist case-open and top-match-open timestamps to a real backend
// once one exists, so limits survive app restarts rather than resetting
// each time the process starts fresh.
// ---------------------------------------------------------------------------
