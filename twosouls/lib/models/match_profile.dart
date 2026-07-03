// ---------------------------------------------------------------------------
// MatchProfile
//
// Rich personal details for another user (a match, not the logged-in
// user — that's UserProfile in profile_screen.dart). Used by:
//   - The match profile screen (MatchProfileScreen), opened via "View
//     Profile" from Cards, Discover, or the Open Soulmate reveal.
//   - The Open Soulmate teaser, which picks up to 3 striking facts from
//     this data to display before the card reveal.
//
// All fields are nullable: test/placeholder candidates won't have real
// data yet, and the profile screen handles blanks gracefully with
// "—" placeholders rather than showing nothing or crashing.
// ---------------------------------------------------------------------------

class MatchProfile {
  // ── Core ─────────────────────────────────────────────────────────────────
  final String id;
  final String name;
  final int age;
  final String? nickname; // Self-chosen — "The Notorious", "The Eagle" etc.
  final String? bio;
  final String? career;
  final String? hometown; // Where they were born / grew up
  final String? currentLocation;
  final String? futureLocation; // Where they want to live eventually

  // ── Identity ──────────────────────────────────────────────────────────────
  final String?
  sexualOrientation; // "Straight", "Gay", "Bisexual", "Pansexual", etc.
  final String? genderIdentity; // "Man", "Woman", "Non-binary", etc.
  final String? lookingFor; // Orientations/genders they're open to

  // ── Languages ─────────────────────────────────────────────────────────────
  final List<String> languages;

  // ── Life & values ─────────────────────────────────────────────────────────
  final String? religion;
  final String? politicalLeaning; // broad category only, not a debate
  final int? wantedKids; // 0 = definitely no, null = open/unsure
  final String? relationshipGoal; // "Marriage", "Long-term", "Open", "Not sure"
  final String? petPreference; // "Dog person", "Cat person", "No pets", etc.

  // ── Lifestyle ─────────────────────────────────────────────────────────────
  final String? drinkingHabit; // "Socially", "Rarely", "Never", etc.
  final String? smokingHabit;
  final String? exerciseFrequency;
  final String? diet; // "Omnivore", "Vegetarian", "Vegan", etc.
  final String? sleepSchedule; // "Night owl", "Early riser", "Depends"

  // ── Personality ───────────────────────────────────────────────────────────
  final String? personalityType; // MBTI / Enneagram / free text, user's own
  final String? loveLanguage;
  final String? communicationStyle; // "Direct", "Thoughtful / slow burn", etc.
  final String? conflictStyle; // "Talk it out", "Need space first", etc.

  // ── Interests (displayed on profile, separate from quiz-derived hobbies) ──
  final List<String> interests;
  final List<String> favouriteMedia; // Shows, movies, books, music

  const MatchProfile({
    required this.id,
    required this.name,
    required this.age,
    this.nickname,
    this.bio,
    this.career,
    this.hometown,
    this.currentLocation,
    this.futureLocation,
    this.sexualOrientation,
    this.genderIdentity,
    this.lookingFor,
    this.languages = const [],
    this.religion,
    this.politicalLeaning,
    this.wantedKids,
    this.relationshipGoal,
    this.petPreference,
    this.drinkingHabit,
    this.smokingHabit,
    this.exerciseFrequency,
    this.diet,
    this.sleepSchedule,
    this.personalityType,
    this.loveLanguage,
    this.communicationStyle,
    this.conflictStyle,
    this.interests = const [],
    this.favouriteMedia = const [],
  });

  /// Returns a blank profile for a given id/name/age — used for
  /// placeholder/test candidates who don't have real data yet.
  /// The profile screen renders "—" for every null field.
  factory MatchProfile.blank(String id, String name, int age) {
    return MatchProfile(id: id, name: name, age: age);
  }
}

// ---------------------------------------------------------------------------
// SoulmateTeaser
//
// Picks up to 3 striking "connection facts" between the logged-in user's
// data and a match candidate's profile, used in the Open Soulmate buildup
// sequence before the card reveal. Facts are selected in priority order —
// stronger / more surprising matches are picked first.
//
// Each fact is a short string (max ~40 chars) and an icon code point.
// ---------------------------------------------------------------------------

class TeaserFact {
  final String text;
  final int iconCodePoint; // Material icon code point

  const TeaserFact({required this.text, required this.iconCodePoint});
}

class SoulmateTeaser {
  SoulmateTeaser._();

  static const int kMaxFacts = 3;

  /// Generates up to 3 teaser facts by comparing the logged-in user's
  /// data with a matched candidate's profile. Returns an empty list if
  /// nothing interesting can be established (e.g. blank test profile).
  static List<TeaserFact> generate({
    required String? userHometown,
    required String userCareer,
    required List<String> userLanguages,
    required MatchProfile match,
  }) {
    final facts = <TeaserFact>[];

    // 1. Same hometown — strongest "fate" signal, shown first.
    if (userHometown != null &&
        match.hometown != null &&
        _looslyMatch(userHometown, match.hometown!)) {
      facts.add(
        TeaserFact(
          text: 'Both from ${_shortCity(match.hometown!)}',
          iconCodePoint: 0xe0c8, // Icons.location_on
        ),
      );
    }

    // 2. Same / very similar career / field
    if (match.career != null &&
        match.career!.isNotEmpty &&
        userCareer.isNotEmpty &&
        _looslyMatch(userCareer, match.career!)) {
      facts.add(
        TeaserFact(
          text: 'Same career path',
          iconCodePoint: 0xe7fb, // Icons.work
        ),
      );
    }

    // 3. Shared language(s) beyond the obvious
    if (match.languages.isNotEmpty && userLanguages.isNotEmpty) {
      final shared = match.languages
          .where((l) => userLanguages.any((u) => _looslyMatch(u, l)))
          .toList();
      if (shared.isNotEmpty) {
        final lang = shared.first;
        facts.add(
          TeaserFact(
            text: 'Both speak $lang',
            iconCodePoint: 0xe894, // Icons.language
          ),
        );
      }
    }

    // 4. Wanted kids alignment
    if (facts.length < kMaxFacts && match.wantedKids != null) {
      // Hardcoded placeholder since we don't yet store the logged-in
      // user's wanted-kids answer from the quiz in an accessible way.
      // TODO: wire this to QuizAnswers.generalAnswers once that's stored.
      facts.add(
        TeaserFact(
          text: match.wantedKids == 0
              ? 'Neither wants kids'
              : 'Wants ${match.wantedKids} kid${match.wantedKids == 1 ? '' : 's'}',
          iconCodePoint: 0xe7fe, // Icons.family_restroom
        ),
      );
    }

    // 5. Lifestyle: same sleep schedule
    if (facts.length < kMaxFacts && match.sleepSchedule != null) {
      facts.add(
        TeaserFact(
          text: match.sleepSchedule!,
          iconCodePoint: 0xe022, // Icons.bedtime
        ),
      );
    }

    return facts.take(kMaxFacts).toList();
  }

  static bool _looslyMatch(String a, String b) {
    final la = a.trim().toLowerCase();
    final lb = b.trim().toLowerCase();
    if (la == lb) return true;
    // One contains the other (e.g. "Brisbane" vs "Brisbane, AU")
    return la.contains(lb) || lb.contains(la);
  }

  static String _shortCity(String location) {
    // "Brisbane, AU" -> "Brisbane"
    return location.split(',').first.trim();
  }
}
