// ---------------------------------------------------------------------------
// CardRarityModel
//
// Computes a card's rarity tier and "wear" finish (CS:GO-style) from the
// 5 compatibility categories between the current user and another person.
//
// CATEGORIES (5 total):
//   hobbies, careerEducation, looks, lifestyle, coreValues
//
// TIER RULE:
//   A category "qualifies" if its score is >= kQualifyThreshold (80).
//   The number of qualifying categories (0–5) determines the tier:
//     0 qualifying -> none      (no card / default lowest tier, treated as bronze-0)
//     1 qualifying -> bronze
//     2 qualifying -> silver
//     3 qualifying -> gold
//     4 qualifying -> platinum
//     5 qualifying -> purple (highest)
//
// WEAR RULE (per-tier, CS:GO style):
//   Wear is driven ONLY by the average of the qualifying categories for
//   that tier — non-qualifying categories don't drag it down or up.
//   That average (80–100) is remapped to a 0–100 "finish" score, then
//   bucketed into 5 named finishes (a CS:GO-style wear gradient, renamed
//   to feel warmer/more human for a dating app):
//     80–84  -> Promising        (rough, dull, scratched look)
//     85–89  -> Solid Match
//     90–93  -> Great Match
//     94–97  -> Standout Match
//     98–100 -> Perfect Match     (pristine, shiny, max sheen)
//
// A qualifying average of exactly 80 is the worst finish for that tier
// (still bronze/silver/etc, just scuffed). A qualifying average of 100
// is the best possible finish for that tier (pristine shine).
// ---------------------------------------------------------------------------

enum CompatCategory { hobbies, careerEducation, looks, lifestyle, coreValues }

enum RarityTier { none, bronze, silver, gold, platinum, purple }

enum WearFinish {
  battleScarred,
  wellWorn,
  fieldTested,
  minimalWear,
  factoryNew,
}

extension WearFinishX on WearFinish {
  String get label {
    switch (this) {
      case WearFinish.battleScarred:
        return 'Promising';
      case WearFinish.wellWorn:
        return 'Solid Match';
      case WearFinish.fieldTested:
        return 'Great Match';
      case WearFinish.minimalWear:
        return 'Standout Match';
      case WearFinish.factoryNew:
        return 'Perfect Match';
    }
  }

  /// 0.0 (dullest / most scratched) -> 1.0 (pristine / max sheen).
  /// Drives shader intensity, scratch overlay opacity, highlight sharpness.
  double get sheenIntensity {
    switch (this) {
      case WearFinish.battleScarred:
        return 0.05;
      case WearFinish.wellWorn:
        return 0.30;
      case WearFinish.fieldTested:
        return 0.55;
      case WearFinish.minimalWear:
        return 0.78;
      case WearFinish.factoryNew:
        return 1.0;
    }
  }

  /// How visible the scratch/scuff overlay should be (inverse of sheen).
  double get scratchOpacity {
    switch (this) {
      case WearFinish.battleScarred:
        return 0.85;
      case WearFinish.wellWorn:
        return 0.55;
      case WearFinish.fieldTested:
        return 0.32;
      case WearFinish.minimalWear:
        return 0.14;
      case WearFinish.factoryNew:
        return 0.0;
    }
  }
}

extension RarityTierX on RarityTier {
  String get label {
    switch (this) {
      case RarityTier.none:
        return 'COMMON';
      case RarityTier.bronze:
        return 'BRONZE';
      case RarityTier.silver:
        return 'SILVER';
      case RarityTier.gold:
        return 'GOLD';
      case RarityTier.platinum:
        return 'PLATINUM';
      case RarityTier.purple:
        return 'PURPLE';
    }
  }

  int get qualifyingCountRequired {
    switch (this) {
      case RarityTier.none:
        return 0;
      case RarityTier.bronze:
        return 1;
      case RarityTier.silver:
        return 2;
      case RarityTier.gold:
        return 3;
      case RarityTier.platinum:
        return 4;
      case RarityTier.purple:
        return 5;
    }
  }
}

class CardRarityResult {
  final RarityTier tier;
  final WearFinish wear;
  final double wearAverage; // raw average of qualifying categories (0-100)
  final double sheenIntensity; // 0.0-1.0, convenience passthrough
  final List<CompatCategory> qualifyingCategories;

  const CardRarityResult({
    required this.tier,
    required this.wear,
    required this.wearAverage,
    required this.sheenIntensity,
    required this.qualifyingCategories,
  });
}

class CardRarityModel {
  static const int kQualifyThreshold = 80;

  static const Map<CompatCategory, int> _emptyScores = {
    CompatCategory.hobbies: 0,
    CompatCategory.careerEducation: 0,
    CompatCategory.looks: 0,
    CompatCategory.lifestyle: 0,
    CompatCategory.coreValues: 0,
  };

  /// Computes the full rarity result from a map of category -> score (0-100).
  /// Missing categories default to 0 (won't qualify).
  static CardRarityResult compute(Map<CompatCategory, int> scores) {
    final merged = {..._emptyScores, ...scores};

    final qualifying = merged.entries
        .where((e) => e.value >= kQualifyThreshold)
        .toList();

    final tier = _tierForCount(qualifying.length);

    if (qualifying.isEmpty) {
      return CardRarityResult(
        tier: tier,
        wear: WearFinish.battleScarred,
        wearAverage: 0,
        sheenIntensity: WearFinish.battleScarred.sheenIntensity,
        qualifyingCategories: const [],
      );
    }

    final avg =
        qualifying.map((e) => e.value).reduce((a, b) => a + b) /
        qualifying.length;

    final wear = _wearForAverage(avg);

    return CardRarityResult(
      tier: tier,
      wear: wear,
      wearAverage: avg,
      sheenIntensity: wear.sheenIntensity,
      qualifyingCategories: qualifying.map((e) => e.key).toList(),
    );
  }

  static RarityTier _tierForCount(int count) {
    switch (count) {
      case 0:
        return RarityTier.none;
      case 1:
        return RarityTier.bronze;
      case 2:
        return RarityTier.silver;
      case 3:
        return RarityTier.gold;
      case 4:
        return RarityTier.platinum;
      default:
        return RarityTier.purple; // 5
    }
  }

  static WearFinish _wearForAverage(double avg) {
    // avg is always in [80, 100] when qualifying categories exist.
    if (avg >= 98) return WearFinish.factoryNew;
    if (avg >= 94) return WearFinish.minimalWear;
    if (avg >= 90) return WearFinish.fieldTested;
    if (avg >= 85) return WearFinish.wellWorn;
    return WearFinish.battleScarred; // 80-84
  }
}
