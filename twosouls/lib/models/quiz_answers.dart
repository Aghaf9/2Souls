import 'hobby_taxonomy.dart';
import 'career_taxonomy.dart';

// ---------------------------------------------------------------------------
// QuizAnswers
//
// Collects whatever a user actually answered during a single QuizScreen
// run, keyed by each QuizTest's question text (simple, stable-enough key
// since question text doesn't change at runtime). QuizScreen builds one
// of these as the user progresses and hands it back via onComplete once
// the quiz finishes — see quiz_screen.dart.
//
// Two fields are first-class (not just generic key/value) because they
// drive real compatibility scoring elsewhere: hobbies and career. Every
// other answer (image elimination picks, number picker values) is stored
// generically in `generalAnswers` for now — feeding those into
// UserProfile is a smaller, more mechanical follow-up once this lands.
// ---------------------------------------------------------------------------

class QuizAnswers {
  final List<HobbySelection> hobbies;
  final CareerSelection? career;
  final Map<String, dynamic> generalAnswers;

  const QuizAnswers({
    this.hobbies = const [],
    this.career,
    this.generalAnswers = const {},
  });

  QuizAnswers copyWith({
    List<HobbySelection>? hobbies,
    CareerSelection? career,
    Map<String, dynamic>? generalAnswers,
  }) {
    return QuizAnswers(
      hobbies: hobbies ?? this.hobbies,
      career: career ?? this.career,
      generalAnswers: generalAnswers ?? this.generalAnswers,
    );
  }
}
