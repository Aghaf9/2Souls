// ---------------------------------------------------------------------------
// CareerTaxonomy
//
// PLACEHOLDER SHELL — waiting on the user's exact category tree before
// filling in CareerTaxonomy.all. The shape mirrors hobby_taxonomy.dart
// exactly (branch -> specific career entry, plus manual/"Other" free-text
// fallback for careers not covered) so once the real tree is provided,
// only the `all` list below needs populating — nothing else in this file,
// or in any screen that imports it, needs to change.
//
// Worked example from the request: "Cellular Biology" and "Physics" would
// both sit under a CareerBranch.science branch, so two people in those
// specific careers score CLOSER to each other (same-branch partial
// credit) than either does to someone in CareerBranch.trades
// (e.g. Construction) — identical mechanism to HobbyCompatibility.
// ---------------------------------------------------------------------------

enum CareerBranch {
  science,
  technology,
  healthcare,
  education,
  business,
  creativeAndMedia,
  tradesAndConstruction,
  publicServiceAndLaw,
  hospitalityAndService,
  studentNotYetWorking,
  other,
}

extension CareerBranchX on CareerBranch {
  String get label {
    switch (this) {
      case CareerBranch.science: return 'Science';
      case CareerBranch.technology: return 'Technology';
      case CareerBranch.healthcare: return 'Healthcare';
      case CareerBranch.education: return 'Education';
      case CareerBranch.business: return 'Business';
      case CareerBranch.creativeAndMedia: return 'Creative & Media';
      case CareerBranch.tradesAndConstruction: return 'Trades & Construction';
      case CareerBranch.publicServiceAndLaw: return 'Public Service & Law';
      case CareerBranch.hospitalityAndService: return 'Hospitality & Service';
      case CareerBranch.studentNotYetWorking: return 'Student / Not Yet Working';
      case CareerBranch.other: return 'Other';
    }
  }
}

class CareerEntry {
  final String id;
  final String label;
  final CareerBranch branch;

  const CareerEntry({required this.id, required this.label, required this.branch});
}

class CareerTaxonomy {
  CareerTaxonomy._();

  // TODO: replace with the user's exact category tree once provided.
  // Minimal placeholder set below so the picker/search/scoring code is
  // fully functional and testable in the meantime.
  static const List<CareerEntry> all = [
    CareerEntry(id: 'physics', label: 'Physics', branch: CareerBranch.science),
    CareerEntry(id: 'cellular_biology', label: 'Cellular Biology', branch: CareerBranch.science),
    CareerEntry(id: 'chemistry', label: 'Chemistry', branch: CareerBranch.science),
    CareerEntry(id: 'software_engineer', label: 'Software Engineer', branch: CareerBranch.technology),
    CareerEntry(id: 'data_analyst', label: 'Data Analyst', branch: CareerBranch.technology),
    CareerEntry(id: 'nurse', label: 'Nurse', branch: CareerBranch.healthcare),
    CareerEntry(id: 'doctor', label: 'Doctor', branch: CareerBranch.healthcare),
    CareerEntry(id: 'teacher', label: 'Teacher', branch: CareerBranch.education),
    CareerEntry(id: 'university_lecturer', label: 'University Lecturer', branch: CareerBranch.education),
    CareerEntry(id: 'accountant', label: 'Accountant', branch: CareerBranch.business),
    CareerEntry(id: 'marketing_manager', label: 'Marketing Manager', branch: CareerBranch.business),
    CareerEntry(id: 'graphic_designer', label: 'Graphic Designer', branch: CareerBranch.creativeAndMedia),
    CareerEntry(id: 'journalist', label: 'Journalist', branch: CareerBranch.creativeAndMedia),
    CareerEntry(id: 'electrician', label: 'Electrician', branch: CareerBranch.tradesAndConstruction),
    CareerEntry(id: 'construction_worker', label: 'Construction Worker', branch: CareerBranch.tradesAndConstruction),
    CareerEntry(id: 'lawyer', label: 'Lawyer', branch: CareerBranch.publicServiceAndLaw),
    CareerEntry(id: 'police_officer', label: 'Police Officer', branch: CareerBranch.publicServiceAndLaw),
    CareerEntry(id: 'chef', label: 'Chef', branch: CareerBranch.hospitalityAndService),
    CareerEntry(id: 'hotel_manager', label: 'Hotel Manager', branch: CareerBranch.hospitalityAndService),
    CareerEntry(id: 'university_student', label: 'University Student', branch: CareerBranch.studentNotYetWorking),
    CareerEntry(id: 'high_school_student', label: 'High School Student', branch: CareerBranch.studentNotYetWorking),
  ];

  static List<CareerEntry> search(String query) {
    if (query.trim().isEmpty) return all;
    final q = query.trim().toLowerCase();
    return all.where((c) => c.label.toLowerCase().contains(q)).toList();
  }

  static CareerEntry? byId(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Best-effort auto-categorisation for manually-typed career text not
  /// found in the taxonomy. Currently a simple keyword match against
  /// existing entries' labels/branch names — genuinely limited without a
  /// real backend/NLP step, but means a typed "Astrophysics" still lands
  /// in Science via partial match against "Physics", rather than always
  /// falling through to the catch-all Other branch.
  static CareerBranch guessBranch(String freeText) {
    final text = freeText.toLowerCase();
    for (final entry in all) {
      final words = entry.label.toLowerCase().split(' ');
      for (final w in words) {
        if (w.length >= 4 && text.contains(w)) return entry.branch;
      }
    }
    for (final branch in CareerBranch.values) {
      if (branch == CareerBranch.other) continue;
      if (text.contains(branch.label.toLowerCase().split(' ').first.toLowerCase())) {
        return branch;
      }
    }
    return CareerBranch.other;
  }
}

// ---------------------------------------------------------------------------
// CareerSelection — mirrors HobbySelection's shape exactly.
// ---------------------------------------------------------------------------

class CareerSelection {
  final String? careerId; // null for manual/"Other" entries
  final String customLabel;
  final CareerBranch branch;

  const CareerSelection({
    required this.careerId,
    required this.customLabel,
    required this.branch,
  });

  factory CareerSelection.fromTaxonomy(CareerEntry entry) {
    return CareerSelection(careerId: entry.id, customLabel: entry.label, branch: entry.branch);
  }

  /// Manual entries still get a best-effort branch guess (see
  /// CareerTaxonomy.guessBranch) rather than always landing in Other, so
  /// someone typing "Astrophysicist" still scores closer to a listed
  /// "Physics" career than to someone in Construction.
  factory CareerSelection.custom(String label) {
    return CareerSelection(
      careerId: null,
      customLabel: label,
      branch: CareerTaxonomy.guessBranch(label),
    );
  }

  bool get isCustom => careerId == null;

  @override
  bool operator ==(Object other) =>
      other is CareerSelection &&
      other.careerId == careerId &&
      other.customLabel.toLowerCase() == customLabel.toLowerCase();

  @override
  int get hashCode => Object.hash(careerId, customLabel.toLowerCase());
}

// ---------------------------------------------------------------------------
// CareerCompatibility — identical scoring mechanism to HobbyCompatibility.
//   - Exact same career -> full credit.
//   - Different career, same branch (e.g. Physics vs Cellular Biology,
//     both Science) -> partial credit.
//   - Different branch -> no credit.
// ---------------------------------------------------------------------------

class CareerCompatibility {
  CareerCompatibility._();

  static const int kExactMatchScore = 100;
  static const int kSameBranchScore = 60;
  static const int kNoMatchScore = 0;

  static int score(CareerSelection a, CareerSelection b) {
    if (a == b) return kExactMatchScore;
    if (a.branch == b.branch && a.branch != CareerBranch.other) return kSameBranchScore;
    return kNoMatchScore;
  }
}
