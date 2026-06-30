import 'card_rarity_model.dart';

// ---------------------------------------------------------------------------
// IncomingUnpack
//
// Represents someone who has "unpacked" (drawn/won) the current user via
// either the Open Case / Top Match (Long Term) or Pack (Short Term) draw
// on their own end. Shown on the Discover screen so the current user can
// Accept or Deny them back, Hinge-Likes-You style.
//
// Placeholder data only — no real backend exists yet to actually detect
// when another user has unpacked you.
// ---------------------------------------------------------------------------

enum UnpackSource { shortTerm, longTerm }

extension UnpackSourceX on UnpackSource {
  String get label {
    switch (this) {
      case UnpackSource.shortTerm: return 'Short Term';
      case UnpackSource.longTerm: return 'Long Term';
    }
  }
}

class IncomingUnpack {
  final String id;
  final String name;
  final int age;
  final String location;
  final RarityTier tier;
  final WearFinish wear;
  final UnpackSource source;
  final String? photoUrl;

  const IncomingUnpack({
    required this.id,
    required this.name,
    required this.age,
    required this.location,
    required this.tier,
    required this.wear,
    required this.source,
    this.photoUrl,
  });
}
