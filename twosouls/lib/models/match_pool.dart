import 'dart:math';
import 'card_rarity_model.dart';

// ---------------------------------------------------------------------------
// MatchCandidate / MatchPool
//
// A weighted draw pool used by the case-opening spinner (see
// case_opening_screen.dart). Mirrors a gambling-style loot pool: most
// entries are common (Bronze/Silver), with progressively fewer Gold,
// Platinum, and Purple — making top-tier profiles genuinely rare to land
// on, same idea as CS:GO case drop rates.
//
// This is placeholder data only — no real backend matching exists yet.
// ---------------------------------------------------------------------------

class MatchCandidate {
  final String id;
  final String name;
  final int age;
  final String location;
  final RarityTier tier;
  final WearFinish wear;
  final String? photoUrl;

  /// Overall compatibility percentage (0-100) with the current user.
  /// Drives the "Top Match" walkout feature, which only draws from
  /// candidates at or above kTopMatchThreshold.
  final int compatibility;

  const MatchCandidate({
    required this.id,
    required this.name,
    required this.age,
    required this.location,
    required this.tier,
    required this.wear,
    this.photoUrl,
    required this.compatibility,
  });
}

class MatchPool {
  MatchPool._();

  /// Minimum compatibility for a candidate to be eligible for the Top
  /// Match walkout (the rare, once-per-7-days "find your strongest match"
  /// draw).
  static const int kTopMatchThreshold = 80;

  /// Rarity weights — higher number = more common in the draw.
  /// Mirrors a gambling-style drop table: Bronze and Silver dominate,
  /// Gold is uncommon, Platinum is rare, Purple is very rare.
  static const Map<RarityTier, int> _tierWeights = {
    RarityTier.bronze: 45,
    RarityTier.silver: 30,
    RarityTier.gold: 15,
    RarityTier.platinum: 7,
    RarityTier.purple: 3,
  };

  static const List<String> _names = [
    'Maya',
    'Jordan',
    'Priya',
    'Liam',
    'Sofia',
    'Ethan',
    'Amara',
    'Noah',
    'Zara',
    'Lucas',
    'Elena',
    'Mason',
    'Layla',
    'Owen',
    'Nadia',
    'Felix',
    'Aisha',
    'Theo',
    'Ines',
    'Kai',
  ];

  static const List<String> _locations = [
    'Brisbane, AU',
    'Sydney, AU',
    'Melbourne, AU',
    'Gold Coast, AU',
    'Perth, AU',
    'Auckland, NZ',
    'Canberra, AU',
    'Adelaide, AU',
  ];

  static final List<WearFinish> _wears = WearFinish.values;

  /// Builds the candidate pool once. Each candidate's tier is assigned by
  /// weighted random so the pool itself already skews common, and the
  /// spinner draw (see drawWeighted) applies the same weighting again on
  /// top when picking the final landing card — doubling down on the "rare
  /// top tier" feel.
  static List<MatchCandidate> buildPool({int count = 24, int? seed}) {
    final rng = Random(seed);
    final List<MatchCandidate> pool = [];

    for (int i = 0; i < count; i++) {
      final tier = _weightedTier(rng);
      final wear = _wears[rng.nextInt(_wears.length)];
      final name = _names[rng.nextInt(_names.length)];
      final age = 20 + rng.nextInt(15);
      final location = _locations[rng.nextInt(_locations.length)];
      // Compatibility loosely correlated with wear sheen, so higher-wear
      // candidates tend to also be higher compatibility — same idea as a
      // "pristine" skin being more desirable on every axis.
      final baseCompat = 50 + (wear.index * 8) + rng.nextInt(15);
      final compatibility = baseCompat.clamp(40, 100);

      pool.add(
        MatchCandidate(
          id: 'candidate_$i',
          name: name,
          age: age,
          location: location,
          tier: tier,
          wear: wear,
          compatibility: compatibility,
        ),
      );
    }
    return pool;
  }

  static RarityTier _weightedTier(Random rng) {
    final total = _tierWeights.values.reduce((a, b) => a + b);
    int roll = rng.nextInt(total);
    for (final entry in _tierWeights.entries) {
      if (roll < entry.value) return entry.key;
      roll -= entry.value;
    }
    return RarityTier.bronze; // fallback, unreachable in practice
  }

  /// Picks the final "winning" candidate for a case-opening spin, using the
  /// same weighting so the visual reel can be built to land on it.
  static MatchCandidate drawWeighted(List<MatchCandidate> pool, {int? seed}) {
    final rng = Random(seed);
    final total = pool.fold<int>(0, (sum, c) => sum + _tierWeights[c.tier]!);
    int roll = rng.nextInt(total);
    for (final c in pool) {
      final weight = _tierWeights[c.tier]!;
      if (roll < weight) return c;
      roll -= weight;
    }
    return pool.last; // fallback, unreachable in practice
  }

  /// Draws a uniformly random candidate from only those at or above
  /// kTopMatchThreshold compatibility, for the Top Match walkout. If the
  /// pool happens to contain no qualifying candidate (unlikely given the
  /// compatibility generation skew, but possible with a small pool), a
  /// synthetic 80+ candidate is generated as a guaranteed fallback so the
  /// walkout always has someone to reveal.
  static MatchCandidate drawTopMatch(List<MatchCandidate> pool, {int? seed}) {
    final rng = Random(seed);
    final qualifying = pool
        .where((c) => c.compatibility >= kTopMatchThreshold)
        .toList();

    if (qualifying.isEmpty) {
      final wear = _wears[rng.nextInt(_wears.length)];
      return MatchCandidate(
        id: 'top_match_fallback',
        name: _names[rng.nextInt(_names.length)],
        age: 20 + rng.nextInt(15),
        location: _locations[rng.nextInt(_locations.length)],
        tier: _weightedTier(rng),
        wear: wear,
        compatibility: kTopMatchThreshold + rng.nextInt(20),
      );
    }

    return qualifying[rng.nextInt(qualifying.length)];
  }
}
