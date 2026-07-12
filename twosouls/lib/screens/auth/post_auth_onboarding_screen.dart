import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../services/user_service.dart';
import '../../models/quiz_answers.dart';
import '../quiz/quiz_screen.dart';

// ---------------------------------------------------------------------------
// PostAuthOnboardingScreen
//
// Runs once, immediately after a NEW Google sign-in (see GoogleLoginScreen
// / main.dart's router — isNewUser gates whether this screen is ever
// shown at all; returning users skip straight to MainShell).
//
// Sequence:
//   1. Age gate — only shown if dob is still null (Google's basic
//      sign-in scope doesn't reliably provide birthdate; see the note
//      in AuthService.signInWithGoogle). Skipped entirely if dob somehow
//      is already set.
//   2. The 5 existing long-term quiz categories (Hobbies, Career, Looks,
//      Lifestyle, Core Values), each already one-at-a-time internally
//      via QuizScreen. Each is preceded by a "Start / Skip for now"
//      intro screen so a user can bail on any individual category
//      without losing the rest of onboarding.
//
// No scoring logic is invented here — see _saveQuizAnswers.
// ---------------------------------------------------------------------------

class PostAuthOnboardingScreen extends StatefulWidget {
  final bool needsDob;
  final VoidCallback onDone;

  const PostAuthOnboardingScreen({
    super.key,
    required this.needsDob,
    required this.onDone,
  });

  @override
  State<PostAuthOnboardingScreen> createState() => _PostAuthOnboardingScreenState();
}

class _PostAuthOnboardingScreenState extends State<PostAuthOnboardingScreen> {
  DateTime? _dob;
  bool _savingDob = false;
  String? _dobError;

  late final List<_QuizCategory> _quizCategories = [
    _QuizCategory('Hobbies', 'A few questions about how you spend your time.', kHobbiesQuizTests),
    _QuizCategory('Career & Education', 'What you do, and where you\u2019re headed.', kCareerQuizTests),
    _QuizCategory('Looks & Preferences', 'What you\u2019re drawn to in a partner.', kLooksQuizTests),
    _QuizCategory('Lifestyle', 'Day-to-day habits and how you like to live.', kLifestyleQuizTests),
    _QuizCategory('Core Values', 'The things that matter most long-term.', kCoreValuesQuizTests),
  ];

  int get _totalSteps => (widget.needsDob ? 1 : 0) + _quizCategories.length;

  @override
  void initState() {
    super.initState();
    if (!widget.needsDob) {
      // No age gate needed — jump straight into the quiz chain after
      // this frame, so the widget tree is mounted before we push.
      WidgetsBinding.instance.addPostFrameCallback((_) => _runQuizChain(0));
    }
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _confirmDob() async {
    if (_dob == null) {
      setState(() => _dobError = 'Please enter your date of birth.');
      return;
    }
    setState(() {
      _savingDob = true;
      _dobError = null;
    });
    await UserService.instance.updateProfile({
      'dob': Timestamp.fromDate(_dob!),
    });
    if (!mounted) return;
    setState(() => _savingDob = false);
    _runQuizChain(0);
  }

  Future<void> _runQuizChain(int index) async {
    if (index >= _quizCategories.length) {
      widget.onDone();
      return;
    }

    final category = _quizCategories[index];
    final overallStep = (widget.needsDob ? 1 : 0) + index;

    final action = await Navigator.of(context).push<_QuizIntroAction>(
      MaterialPageRoute(
        builder: (_) => _QuizIntroScreen(
          category: category,
          stepIndex: overallStep,
          stepTotal: _totalSteps,
        ),
      ),
    );

    if (!mounted) return;

    if (action == _QuizIntroAction.start) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            tests: category.tests,
            title: category.title,
            onComplete: (answers) => _saveQuizAnswers(category, answers),
          ),
        ),
      );
    }
    if (!mounted) return;
    _runQuizChain(index + 1);
  }

  Future<void> _saveQuizAnswers(_QuizCategory category, QuizAnswers answers) async {
    final fields = <String, dynamic>{};

    if (answers.hobbies.isNotEmpty) {
      fields['hobbyIds'] = answers.hobbies
          .where((h) => !h.isCustom)
          .map((h) => h.hobbyId)
          .whereType<String>()
          .toList();
    }
    if (answers.career != null) {
      fields['careerId'] = answers.career!.careerId;
      fields['career'] = answers.career!.customLabel;
    }
    if (answers.generalAnswers.isNotEmpty) {
      fields['quizGeneralAnswers_${category.storageKey}'] = answers.generalAnswers;
    }

    if (fields.isNotEmpty) {
      await UserService.instance.updateProfile(fields);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.needsDob) {
      // Blank holding screen while the post-frame callback pushes the
      // first quiz intro — avoids a flash of unrelated content.
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _StepHeader(stepIndex: 0, stepTotal: _totalSteps),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'When\u2019s your birthday?',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Google didn\u2019t share this with us \u2014 you must be 18 or older to use 2Souls.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: _pickDob,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        decoration: BoxDecoration(
                          color: AppColors.panelBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.panelBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cake_outlined,
                              color: AppColors.textSecondary.withOpacity(0.5),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _dob == null
                                  ? 'Date of Birth'
                                  : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                              style: TextStyle(
                                color: _dob == null
                                    ? AppColors.textSecondary.withOpacity(0.5)
                                    : AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_dobError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _dobError!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savingDob ? null : _confirmDob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _savingDob
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizCategory {
  final String title;
  final String description;
  final List<QuizTest> tests;
  const _QuizCategory(this.title, this.description, this.tests);

  String get storageKey => title.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), '_');
}

enum _QuizIntroAction { start, skip }

// ── Shared step chrome ───────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final int stepIndex;
  final int stepTotal;

  const _StepHeader({required this.stepIndex, required this.stepTotal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(stepTotal, (i) {
                final isDone = i <= stepIndex;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i == stepTotal - 1 ? 0 : 4),
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.accent : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${stepIndex + 1}/$stepTotal',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quiz intro / skip screen ─────────────────────────────────────────────

class _QuizIntroScreen extends StatelessWidget {
  final _QuizCategory category;
  final int stepIndex;
  final int stepTotal;

  const _QuizIntroScreen({
    required this.category,
    required this.stepIndex,
    required this.stepTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _StepHeader(stepIndex: stepIndex, stepTotal: stepTotal),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withOpacity(0.12),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.5),
                            width: 1.4,
                          ),
                        ),
                        child: const Icon(
                          Icons.quiz_outlined,
                          color: AppColors.accent,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        category.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_QuizIntroAction.start),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Start',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(_QuizIntroAction.skip),
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
