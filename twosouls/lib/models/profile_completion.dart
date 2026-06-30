import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// ProfileCompletionStore
//
// Tracks which of the 5 Long Term quizzes have been completed, shared
// between QuizHubScreen and the Home "Complete Your Profile" card so both
// reflect the same state. Also exposes a combined completion percentage
// used for the Hinge-style progress bar on Home.
//
// Quiz completion is NOT persisted past app restart — no backend yet, see
// TODO at the bottom.
// ---------------------------------------------------------------------------

class ProfileCompletionStore extends ChangeNotifier {
  ProfileCompletionStore._();
  static final ProfileCompletionStore instance = ProfileCompletionStore._();

  static const int totalQuizzes = 5;

  final Set<int> completedQuizzes = {};

  void markQuizComplete(int index) {
    completedQuizzes.add(index);
    notifyListeners();
  }

  bool get allQuizzesComplete => completedQuizzes.length >= totalQuizzes;

  double get quizCompletionFraction => completedQuizzes.length / totalQuizzes;

  /// Overall profile completion (0.0-1.0), combining quiz completion with
  /// basic profile-field completeness. The field-completeness portion is
  /// passed in from ProfileScreen's current state rather than stored here,
  /// since UserProfile's editable fields already live in ProfileScreen.
  double overallCompletion({required double fieldCompletionFraction}) {
    // Weighted: quizzes count for 60%, profile fields for 40% — quizzes are
    // the bigger lift, so they're weighted more heavily.
    return (quizCompletionFraction * 0.6) + (fieldCompletionFraction * 0.4);
  }
}

// ---------------------------------------------------------------------------
// TODO: persist completedQuizzes to a real backend once one exists, so
// progress survives app restarts instead of resetting each process launch.
// ---------------------------------------------------------------------------
