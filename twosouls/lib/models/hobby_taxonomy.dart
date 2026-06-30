// ---------------------------------------------------------------------------
// HobbyTaxonomy
//
// A 2-level category tree (branch -> specific hobby) used for two things:
//   1. The searchable multi-select hobby picker in the quiz.
//   2. Computing a "closeness" score between two people's hobby sets —
//      two hobbies under the same branch (e.g. "Rock Climbing" and
//      "Hiking" both under Outdoors & Adventure) score as more compatible
//      than two hobbies from unrelated branches, mirroring the same idea
//      requested for careers (Physics and Cellular Biology are closer to
//      each other than either is to Construction, because they share the
//      Science branch).
//
// Manual "Other" entries (free text not in the list) are categorised into
// a synthetic "Other" branch and only match exactly against another
// identical free-text entry — there's no semantic understanding of
// arbitrary text without a real backend/NLP step, so this is the honest
// placeholder behaviour until that exists.
// ---------------------------------------------------------------------------

enum HobbyBranch {
  fitnessAndSport,
  outdoorsAndAdventure,
  creativeAndArts,
  musicAndPerformance,
  gamingAndTech,
  foodAndDrink,
  socialAndCommunity,
  mindAndWellness,
  travelAndCulture,
  other,
}

extension HobbyBranchX on HobbyBranch {
  String get label {
    switch (this) {
      case HobbyBranch.fitnessAndSport: return 'Fitness & Sport';
      case HobbyBranch.outdoorsAndAdventure: return 'Outdoors & Adventure';
      case HobbyBranch.creativeAndArts: return 'Creative & Arts';
      case HobbyBranch.musicAndPerformance: return 'Music & Performance';
      case HobbyBranch.gamingAndTech: return 'Gaming & Tech';
      case HobbyBranch.foodAndDrink: return 'Food & Drink';
      case HobbyBranch.socialAndCommunity: return 'Social & Community';
      case HobbyBranch.mindAndWellness: return 'Mind & Wellness';
      case HobbyBranch.travelAndCulture: return 'Travel & Culture';
      case HobbyBranch.other: return 'Other';
    }
  }
}

class HobbyEntry {
  final String id;
  final String label;
  final HobbyBranch branch;

  const HobbyEntry({required this.id, required this.label, required this.branch});
}

class HobbyTaxonomy {
  HobbyTaxonomy._();

  static const List<HobbyEntry> all = [
    // ── Fitness & Sport ──────────────────────────────────────────────────
    HobbyEntry(id: 'gym_weightlifting', label: 'Gym / Weightlifting', branch: HobbyBranch.fitnessAndSport),
    HobbyEntry(id: 'running', label: 'Running', branch: HobbyBranch.fitnessAndSport),
    HobbyEntry(id: 'yoga', label: 'Yoga', branch: HobbyBranch.fitnessAndSport),
    HobbyEntry(id: 'pilates', label: 'Pilates', branch: HobbyBranch.fitnessAndSport),
    HobbyEntry(id: 'basketball', label: 'Basketball', branch: HobbyBranch.fitnessAndSport),
    HobbyEntry(id: 'soccer_football', label: 'Soccer / Football', branch: HobbyBranch.fitnessAndSport),
    HobbyEntry(id: 'tennis', label: 'Tennis', branch: HobbyBranch.fitnessAndSport),
    HobbyEntry(id: 'swimming', label: 'Swimming', branch: HobbyBranch.fitnessAndSport),
    HobbyEntry(id: 'martial_arts', label: 'Martial Arts / Jiu-Jitsu', branch: HobbyBranch.fitnessAndSport),
    HobbyEntry(id: 'cycling', label: 'Cycling', branch: HobbyBranch.fitnessAndSport),
    HobbyEntry(id: 'golf', label: 'Golf', branch: HobbyBranch.fitnessAndSport),
    HobbyEntry(id: 'crossfit', label: 'CrossFit', branch: HobbyBranch.fitnessAndSport),

    // ── Outdoors & Adventure ─────────────────────────────────────────────
    HobbyEntry(id: 'hiking', label: 'Hiking', branch: HobbyBranch.outdoorsAndAdventure),
    HobbyEntry(id: 'camping', label: 'Camping', branch: HobbyBranch.outdoorsAndAdventure),
    HobbyEntry(id: 'rock_climbing', label: 'Rock Climbing', branch: HobbyBranch.outdoorsAndAdventure),
    HobbyEntry(id: 'surfing', label: 'Surfing', branch: HobbyBranch.outdoorsAndAdventure),
    HobbyEntry(id: 'fishing', label: 'Fishing', branch: HobbyBranch.outdoorsAndAdventure),
    HobbyEntry(id: 'skiing_snowboarding', label: 'Skiing / Snowboarding', branch: HobbyBranch.outdoorsAndAdventure),
    HobbyEntry(id: 'sailing', label: 'Sailing', branch: HobbyBranch.outdoorsAndAdventure),
    HobbyEntry(id: 'gardening', label: 'Gardening', branch: HobbyBranch.outdoorsAndAdventure),
    HobbyEntry(id: 'astronomy', label: 'Astronomy / Stargazing', branch: HobbyBranch.outdoorsAndAdventure),

    // ── Creative & Arts ──────────────────────────────────────────────────
    HobbyEntry(id: 'painting_drawing', label: 'Painting / Drawing', branch: HobbyBranch.creativeAndArts),
    HobbyEntry(id: 'photography', label: 'Photography', branch: HobbyBranch.creativeAndArts),
    HobbyEntry(id: 'writing', label: 'Writing', branch: HobbyBranch.creativeAndArts),
    HobbyEntry(id: 'graphic_design', label: 'Graphic Design', branch: HobbyBranch.creativeAndArts),
    HobbyEntry(id: 'sculpting_pottery', label: 'Sculpting / Pottery', branch: HobbyBranch.creativeAndArts),
    HobbyEntry(id: 'fashion_design', label: 'Fashion / Sewing', branch: HobbyBranch.creativeAndArts),
    HobbyEntry(id: 'filmmaking', label: 'Filmmaking / Video Editing', branch: HobbyBranch.creativeAndArts),
    HobbyEntry(id: 'interior_design', label: 'Interior Design', branch: HobbyBranch.creativeAndArts),

    // ── Music & Performance ──────────────────────────────────────────────
    HobbyEntry(id: 'playing_instrument', label: 'Playing an Instrument', branch: HobbyBranch.musicAndPerformance),
    HobbyEntry(id: 'singing', label: 'Singing', branch: HobbyBranch.musicAndPerformance),
    HobbyEntry(id: 'dj_producing', label: 'DJing / Music Production', branch: HobbyBranch.musicAndPerformance),
    HobbyEntry(id: 'dancing', label: 'Dancing', branch: HobbyBranch.musicAndPerformance),
    HobbyEntry(id: 'theatre_acting', label: 'Theatre / Acting', branch: HobbyBranch.musicAndPerformance),
    HobbyEntry(id: 'concerts_live_music', label: 'Going to Concerts', branch: HobbyBranch.musicAndPerformance),
    HobbyEntry(id: 'stand_up_comedy', label: 'Stand-Up Comedy', branch: HobbyBranch.musicAndPerformance),

    // ── Gaming & Tech ────────────────────────────────────────────────────
    HobbyEntry(id: 'video_games', label: 'Video Games', branch: HobbyBranch.gamingAndTech),
    HobbyEntry(id: 'board_games', label: 'Board Games', branch: HobbyBranch.gamingAndTech),
    HobbyEntry(id: 'tabletop_rpgs', label: 'Tabletop RPGs (D&D etc.)', branch: HobbyBranch.gamingAndTech),
    HobbyEntry(id: 'coding_programming', label: 'Coding / Programming', branch: HobbyBranch.gamingAndTech),
    HobbyEntry(id: 'pc_building', label: 'PC Building / Tech Tinkering', branch: HobbyBranch.gamingAndTech),
    HobbyEntry(id: 'esports', label: 'Esports / Competitive Gaming', branch: HobbyBranch.gamingAndTech),
    HobbyEntry(id: 'chess', label: 'Chess', branch: HobbyBranch.gamingAndTech),

    // ── Food & Drink ─────────────────────────────────────────────────────
    HobbyEntry(id: 'cooking', label: 'Cooking', branch: HobbyBranch.foodAndDrink),
    HobbyEntry(id: 'baking', label: 'Baking', branch: HobbyBranch.foodAndDrink),
    HobbyEntry(id: 'wine_tasting', label: 'Wine Tasting', branch: HobbyBranch.foodAndDrink),
    HobbyEntry(id: 'coffee_culture', label: 'Coffee Culture', branch: HobbyBranch.foodAndDrink),
    HobbyEntry(id: 'craft_beer', label: 'Craft Beer / Brewing', branch: HobbyBranch.foodAndDrink),
    HobbyEntry(id: 'restaurant_exploring', label: 'Trying New Restaurants', branch: HobbyBranch.foodAndDrink),
    HobbyEntry(id: 'mixology', label: 'Mixology / Cocktails', branch: HobbyBranch.foodAndDrink),

    // ── Social & Community ───────────────────────────────────────────────
    HobbyEntry(id: 'volunteering', label: 'Volunteering', branch: HobbyBranch.socialAndCommunity),
    HobbyEntry(id: 'nightlife_clubbing', label: 'Nightlife / Clubbing', branch: HobbyBranch.socialAndCommunity),
    HobbyEntry(id: 'hosting_parties', label: 'Hosting Parties', branch: HobbyBranch.socialAndCommunity),
    HobbyEntry(id: 'networking_events', label: 'Networking Events', branch: HobbyBranch.socialAndCommunity),
    HobbyEntry(id: 'pet_care', label: 'Pets / Animal Care', branch: HobbyBranch.socialAndCommunity),
    HobbyEntry(id: 'activism', label: 'Activism / Politics', branch: HobbyBranch.socialAndCommunity),

    // ── Mind & Wellness ──────────────────────────────────────────────────
    HobbyEntry(id: 'reading', label: 'Reading', branch: HobbyBranch.mindAndWellness),
    HobbyEntry(id: 'meditation', label: 'Meditation', branch: HobbyBranch.mindAndWellness),
    HobbyEntry(id: 'journaling', label: 'Journaling', branch: HobbyBranch.mindAndWellness),
    HobbyEntry(id: 'podcasts', label: 'Podcasts', branch: HobbyBranch.mindAndWellness),
    HobbyEntry(id: 'philosophy_debate', label: 'Philosophy / Debate', branch: HobbyBranch.mindAndWellness),
    HobbyEntry(id: 'language_learning', label: 'Learning Languages', branch: HobbyBranch.mindAndWellness),
    HobbyEntry(id: 'puzzles', label: 'Puzzles / Brain Teasers', branch: HobbyBranch.mindAndWellness),

    // ── Travel & Culture ─────────────────────────────────────────────────
    HobbyEntry(id: 'travelling', label: 'Travelling', branch: HobbyBranch.travelAndCulture),
    HobbyEntry(id: 'museums_galleries', label: 'Museums / Galleries', branch: HobbyBranch.travelAndCulture),
    HobbyEntry(id: 'history', label: 'History', branch: HobbyBranch.travelAndCulture),
    HobbyEntry(id: 'backpacking', label: 'Backpacking', branch: HobbyBranch.travelAndCulture),
    HobbyEntry(id: 'road_trips', label: 'Road Trips', branch: HobbyBranch.travelAndCulture),
    HobbyEntry(id: 'cultural_festivals', label: 'Cultural Festivals', branch: HobbyBranch.travelAndCulture),
  ];

  static List<HobbyEntry> search(String query) {
    if (query.trim().isEmpty) return all;
    final q = query.trim().toLowerCase();
    return all.where((h) => h.label.toLowerCase().contains(q)).toList();
  }

  static HobbyEntry? byId(String id) {
    try {
      return all.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// HobbySelection
//
// A single selected hobby — either a taxonomy entry (id refers into
// HobbyTaxonomy.all) or a manually-typed "Other" entry (id is null,
// customLabel holds the free text, branch is always HobbyBranch.other).
// ---------------------------------------------------------------------------

class HobbySelection {
  final String? hobbyId; // null for manual/"Other" entries
  final String customLabel; // used for display; for taxonomy entries this mirrors HobbyEntry.label
  final HobbyBranch branch;

  const HobbySelection({
    required this.hobbyId,
    required this.customLabel,
    required this.branch,
  });

  factory HobbySelection.fromTaxonomy(HobbyEntry entry) {
    return HobbySelection(hobbyId: entry.id, customLabel: entry.label, branch: entry.branch);
  }

  factory HobbySelection.custom(String label) {
    return HobbySelection(hobbyId: null, customLabel: label, branch: HobbyBranch.other);
  }

  bool get isCustom => hobbyId == null;

  @override
  bool operator ==(Object other) =>
      other is HobbySelection &&
      other.hobbyId == hobbyId &&
      other.customLabel.toLowerCase() == customLabel.toLowerCase();

  @override
  int get hashCode => Object.hash(hobbyId, customLabel.toLowerCase());
}

// ---------------------------------------------------------------------------
// HobbyCompatibility
//
// Computes a 0-100 closeness score between two people's hobby sets.
// Scoring rule:
//   - Exact same hobby (same id, or same custom label) -> full credit.
//   - Different hobby, same branch -> partial credit (same idea as
//     Physics vs Cellular Biology both being Science).
//   - Different branch entirely -> no credit.
//   - Manual/"Other" entries only match exactly against an identical
//     custom label (no semantic understanding without a backend), and
//     never receive same-branch partial credit since "Other" isn't a
//     real category, it's a catch-all.
// The final score is the average best-match credit across the smaller
// person's hobby list, so someone with 3 hobbies is scored against their
// best-matching counterpart for each of those 3, not penalised for the
// other person simply having more hobbies listed.
// ---------------------------------------------------------------------------

class HobbyCompatibility {
  HobbyCompatibility._();

  static const int kExactMatchScore = 100;
  static const int kSameBranchScore = 55;
  static const int kNoMatchScore = 0;

  static int score(List<HobbySelection> a, List<HobbySelection> b) {
    if (a.isEmpty || b.isEmpty) return 0;

    final shorter = a.length <= b.length ? a : b;
    final longer = a.length <= b.length ? b : a;

    int total = 0;
    for (final mine in shorter) {
      int best = kNoMatchScore;
      for (final theirs in longer) {
        final pairScore = _pairScore(mine, theirs);
        if (pairScore > best) best = pairScore;
      }
      total += best;
    }

    return (total / shorter.length).round();
  }

  static int _pairScore(HobbySelection x, HobbySelection y) {
    if (x == y) return kExactMatchScore;
    if (x.branch == HobbyBranch.other || y.branch == HobbyBranch.other) return kNoMatchScore;
    if (x.branch == y.branch) return kSameBranchScore;
    return kNoMatchScore;
  }
}
