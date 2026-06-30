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

  /// Physical-attractiveness match score (0-100) — how closely this
  /// candidate's self-rated/photo-rated looks align with the current
  /// user's. Drives Short Term pack pool selection alongside
  /// sharedAnswerCount (see MatchPool.buildShortTermPool).
  final int looksMatchScore;

  /// How many of the short-term quiz questions this candidate answered
  /// identically to the current user (out of kShortTermQuizQuestionCount).
  /// A higher count means a more "compatible for tonight" pool entry.
  final int sharedShortTermAnswers;

  const MatchCandidate({
    required this.id,
    required this.name,
    required this.age,
    required this.location,
    required this.tier,
    required this.wear,
    this.photoUrl,
    required this.compatibility,
    this.looksMatchScore = 50,
    this.sharedShortTermAnswers = 0,
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

  // ── Short Term pack system ─────────────────────────────────────────────
  // Unlike the general buildPool() above (used by Open Case / Top Match,
  // which draws from a broad random population), the Short Term pack pool
  // is built specifically from candidates who answered the SAME short-term
  // quiz choices as the current user, then ranked by how closely their
  // looks-match score aligns. This models "people who said the same things
  // you did, who you're also likely to find physically compatible with" —
  // a much narrower, more targeted pool than the general gambling draw.
  //
  // sharedAnswerCount and looksMatchScore are both placeholder-generated
  // here (no real answer-comparison or photo-rating backend exists yet),
  // but the pool is explicitly biased toward HIGH values on both axes, so
  // testing the pack-opening UI sees realistic-looking "great match"
  // candidates rather than uniformly random ones.
  static List<MatchCandidate> buildShortTermPool({int count = 20, int? seed}) {
    final rng = Random(seed);
    final List<MatchCandidate> pool = [];

    for (int i = 0; i < count; i++) {
      final tier = _weightedTier(rng);
      final wear = _wears[rng.nextInt(_wears.length)];
      final name = _names[rng.nextInt(_names.length)];
      final age = 20 + rng.nextInt(15);
      final location = _locations[rng.nextInt(_locations.length)];
      final baseCompat = 50 + (wear.index * 8) + rng.nextInt(15);
      final compatibility = baseCompat.clamp(40, 100);
      // Biased high — this pool is specifically "people who match you".
      final looksMatchScore = (60 + rng.nextInt(40)).clamp(0, 100);
      final sharedAnswers =
          1 + rng.nextInt(3); // out of the 3 short-term quiz questions

      pool.add(
        MatchCandidate(
          id: 'short_term_$i',
          name: name,
          age: age,
          location: location,
          tier: tier,
          wear: wear,
          compatibility: compatibility,
          looksMatchScore: looksMatchScore,
          sharedShortTermAnswers: sharedAnswers,
        ),
      );
    }

    // Sort so the highest shared-answers + looks-match candidates are
    // most likely to surface in a 4-card pack pull.
    pool.sort((a, b) {
      final scoreA = a.sharedShortTermAnswers * 100 + a.looksMatchScore;
      final scoreB = b.sharedShortTermAnswers * 100 + b.looksMatchScore;
      return scoreB.compareTo(scoreA);
    });

    return pool;
  }

  /// Draws 4 distinct candidates for a Short Term pack opening, weighted
  /// by rarity tier exactly like Open Case. If a guaranteed minimum tier
  /// is active (see PassTier), every drawn card is re-rolled until it
  /// meets or exceeds that tier.
  static List<MatchCandidate> drawPack(
    List<MatchCandidate> pool, {
    int cardCount = 4,
    PassTier? guaranteedTier,
    int? seed,
  }) {
    final rng = Random(seed);
    final drawn = <MatchCandidate>[];
    final usedIds = <String>{};

    int attempts = 0;
    while (drawn.length < cardCount && attempts < cardCount * 50) {
      attempts++;
      final candidate = drawWeighted(
        pool.where((c) => !usedIds.contains(c.id)).toList(),
        seed: seed == null ? null : seed + attempts,
      );
      if (guaranteedTier != null &&
          !guaranteedTier.meetsGuarantee(candidate.tier)) {
        continue; // re-roll: doesn't meet the pass's minimum guarantee
      }
      if (usedIds.contains(candidate.id)) continue;
      usedIds.add(candidate.id);
      drawn.add(candidate);
    }

    // Fallback: if re-rolling couldn't fill all 4 slots (small pool edge
    // case), top up with the highest-tier remaining candidates so the
    // pack always has exactly cardCount cards.
    if (drawn.length < cardCount) {
      final remaining = pool.where((c) => !usedIds.contains(c.id)).toList()
        ..sort((a, b) => b.tier.index.compareTo(a.tier.index));
      for (final c in remaining) {
        if (drawn.length >= cardCount) break;
        drawn.add(c);
        usedIds.add(c.id);
      }
    }

    return drawn;
  }
}

// ── Pass tiers ──────────────────────────────────────────────────────────
// Future monetization hook: for a limited time, a purchased pass
// guarantees every pack-opened card is at or above the pass's tier.
// Not wired to any real purchase flow yet — see ShortTermPackScreen for
// where this would be selected/applied once passes are purchasable.

enum PassTier { silver, gold, platinum, purple }

extension PassTierX on PassTier {
  String get label {
    switch (this) {
      case PassTier.silver:
        return 'Silver Pass';
      case PassTier.gold:
        return 'Gold Pass';
      case PassTier.platinum:
        return 'Platinum Pass';
      case PassTier.purple:
        return 'Purple Pass';
    }
  }

  RarityTier get minimumTier {
    switch (this) {
      case PassTier.silver:
        return RarityTier.silver;
      case PassTier.gold:
        return RarityTier.gold;
      case PassTier.platinum:
        return RarityTier.platinum;
      case PassTier.purple:
        return RarityTier.purple;
    }
  }

  /// True if the given tier meets or exceeds this pass's guarantee.
  /// Relies on RarityTier's declaration order (bronze < silver < gold <
  /// platinum < purple) matching enum index order.
  bool meetsGuarantee(RarityTier tier) => tier.index >= minimumTier.index;
}
