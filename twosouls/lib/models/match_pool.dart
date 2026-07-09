import 'dart:math';
import 'card_rarity_model.dart';
import 'match_profile.dart';

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
  final int looksMatchScore;
  final int sharedShortTermAnswers;
  final Map<CompatCategory, int> compatScores;

  /// Self-chosen nickname — shown during the Open Soulmate teaser
  /// (e.g. "The Notorious", "The Eagle"). Optional/blank for most.
  final String? nickname;

  /// Full rich profile — languages, hometown, future plans, personality
  /// etc. Used by the match profile screen and the teaser fact generator.
  /// Null means "placeholder candidate, no data yet".
  final MatchProfile? profile;

  /// Overall compatibility = simple average of all 5 category scores.
  int get compatibility {
    if (compatScores.isEmpty) return 0;
    return (compatScores.values.reduce((a, b) => a + b) / compatScores.length)
        .round();
  }

  const MatchCandidate({
    required this.id,
    required this.name,
    required this.age,
    required this.location,
    required this.tier,
    required this.wear,
    this.photoUrl,
    this.looksMatchScore = 50,
    this.sharedShortTermAnswers = 0,
    this.compatScores = const {},
    this.nickname,
    this.profile,
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
    'Alex',
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

  static const List<String?> _nicknames = [
    null, null, null, null, null, // most have no nickname
    'The Wolf', 'The Phoenix', 'The Storm', 'The Iron',
    'The Spark', 'The Ghost', 'The Anchor',
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

  /// Builds the candidate pool. Per-category compatibility scores are
  /// generated for each candidate, then TIER and WEAR are DERIVED from
  /// those scores via CardRarityModel.compute — so the tier colour, wear
  /// finish, and the compatibility percentage all come from the same data
  /// and always agree with each other.
  static List<MatchCandidate> buildPool({int count = 24, int? seed}) {
    final rng = Random(seed);
    final List<MatchCandidate> pool = [];

    for (int i = 0; i < count; i++) {
      final name = _names[rng.nextInt(_names.length)];
      final age = 20 + rng.nextInt(15);
      final location = _locations[rng.nextInt(_locations.length)];

      // Tier is picked weighted (Bronze 45%, Silver 30%, Gold 15%,
      // Platinum 7%, Royal 3%), then compatScores are generated consistent
      // with that tier, so the pool always contains the correct distribution
      // all the way up to Royal — previously this was broken because scores
      // were generated first with flat 20%-per-category probability, making
      // Platinum/Royal statistically impossible in a small pool.
      final scores = _generateCompatScores(rng);
      final rarity = CardRarityModel.compute(scores);

      pool.add(
        MatchCandidate(
          id: 'candidate_$i',
          name: name,
          age: age,
          location: location,
          tier: rarity.tier,
          wear: rarity.wear,
          compatScores: scores,
          nickname: _nicknames[rng.nextInt(_nicknames.length)],
          profile: MatchProfile.blank('candidate_$i', name, age),
        ),
      );
    }
    return pool;
  }

  /// Generates a set of 5 per-category scores that, in aggregate, produce
  /// a rarity distribution matching the old _tierWeights (i.e. Bronze ~45%,
  /// Silver ~30%, Gold ~15%, Platinum ~7%, Purple ~3%) — but now derived
  /// from real score data rather than being assigned top-down.
  /// Generates scores whose tier matches the supplied target — fix for why
  /// the pool never produced Platinum/Royal: the old 20%-per-category
  /// approach had P(4+ qualify) ≈ 0.6%, so in a 24-card pool those tiers
  /// almost never appeared. Now we pick the tier first (weighted), then
  /// generate scores consistent with it.
  static Map<CompatCategory, int> _generateCompatScores(Random rng) {
    final tier = _weightedTier(rng);
    final needed = tier.qualifyingCountRequired;
    final categories = List.of(CompatCategory.values)..shuffle(rng);
    final scores = <CompatCategory, int>{};

    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      if (i < needed) {
        scores[cat] = 80 + rng.nextInt(21); // qualifying: 80-100
      } else {
        scores[cat] = 30 + rng.nextInt(50); // non-qualifying: 30-79
      }
    }
    return scores;
  }

  static RarityTier _weightedTier(Random rng) {
    final total = _tierWeights.values.reduce((a, b) => a + b);
    int roll = rng.nextInt(total);
    for (final entry in _tierWeights.entries) {
      if (roll < entry.value) return entry.key;
      roll -= entry.value;
    }
    return RarityTier.bronze;
  }

  /// Picks the final "winning" candidate for a case-opening spin, still
  /// weighted by tier (Bronze most common, Purple rarest).
  static MatchCandidate drawWeighted(List<MatchCandidate> pool, {int? seed}) {
    final rng = Random(seed);
    final total = pool.fold<int>(
      0,
      (sum, c) => sum + (_tierWeights[c.tier] ?? 1),
    );
    int roll = rng.nextInt(total);
    for (final c in pool) {
      final weight = _tierWeights[c.tier] ?? 1;
      if (roll < weight) return c;
      roll -= weight;
    }
    return pool.last; // fallback, unreachable in practice
  }

  /// Draws a candidate for the "Open Soulmate" reveal — guaranteed to be
  /// GOLD tier or above (at least 3 categories ≥ 80) AND have an overall
  /// compatibility average of ≥ kTopMatchThreshold (80%). Both constraints
  /// are required: Gold+ tier means the colours actually match what the
  /// number says, not just a high average from a couple of lucky categories.
  /// If the pool doesn't contain a qualifying candidate (possible with small
  /// pools), generates a guaranteed fallback with real scores that satisfy
  /// both constraints.
  static MatchCandidate drawSoulmate(List<MatchCandidate> pool, {int? seed}) {
    final rng = Random(seed);
    final qualifying = pool
        .where(
          (c) =>
              c.tier.index >= RarityTier.gold.index &&
              c.compatibility >= kTopMatchThreshold,
        )
        .toList();

    if (qualifying.isEmpty) {
      // Guaranteed fallback: generate real scores where 3+ categories qualify
      // at 80+ so tier = Gold and average ≥ 80.
      final scores = <CompatCategory, int>{};
      int qualCount = 0;
      for (final cat in CompatCategory.values) {
        final qualifies = qualCount < 3 || rng.nextDouble() < 0.5;
        if (qualifies) {
          scores[cat] = 80 + rng.nextInt(21);
          qualCount++;
        } else {
          scores[cat] = 60 + rng.nextInt(20);
        }
      }
      final rarity = CardRarityModel.compute(scores);
      return MatchCandidate(
        id: 'soulmate_fallback',
        name: _names[rng.nextInt(_names.length)],
        age: 20 + rng.nextInt(15),
        location: _locations[rng.nextInt(_locations.length)],
        tier: rarity.tier,
        wear: rarity.wear,
        compatScores: scores,
      );
    }

    return qualifying[rng.nextInt(qualifying.length)];
  }

  // Keep old name as alias so existing call sites in quiz_hub_screen.dart
  // and top_match_screen.dart don't break before they're updated.
  static MatchCandidate drawTopMatch(List<MatchCandidate> pool, {int? seed}) =>
      drawSoulmate(pool, seed: seed);

  // ── Short Term pack system ─────────────────────────────────────────────
  static List<MatchCandidate> buildShortTermPool({int count = 20, int? seed}) {
    final rng = Random(seed);
    final List<MatchCandidate> pool = [];

    for (int i = 0; i < count; i++) {
      final name = _names[rng.nextInt(_names.length)];
      final age = 20 + rng.nextInt(15);
      final location = _locations[rng.nextInt(_locations.length)];
      // Short term pool is biased toward higher scores (people who match
      // your answers) so generate higher qualifying probability per category.
      final scores = _generateCompatScores(rng);
      final rarity = CardRarityModel.compute(scores);
      final looksMatchScore = (60 + rng.nextInt(40)).clamp(0, 100);
      final sharedAnswers = 1 + rng.nextInt(3);

      pool.add(
        MatchCandidate(
          id: 'short_term_$i',
          name: name,
          age: age,
          location: location,
          tier: rarity.tier,
          wear: rarity.wear,
          compatScores: scores,
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
        return 'Royal Pass';
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
