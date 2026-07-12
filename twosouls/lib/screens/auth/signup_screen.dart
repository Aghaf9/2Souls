import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/quiz_answers.dart';
import '../quiz/quiz_screen.dart';
import 'auth_field.dart';

// ---------------------------------------------------------------------------
// SignUpFlowScreen
//
// Hinge-style signup: one question per screen instead of one long form.
// Sequence:
//   1. Name
//   2. Email
//   3. Password (+ confirm)
//   4. Date of birth  -> account is created here via AuthService.signUp
//   5-9. The 5 existing long-term quiz categories (Hobbies, Career, Looks,
//        Lifestyle, Core Values), each already one-at-a-time internally
//        via QuizScreen. Each is preceded by a "Start / Skip for now"
//        intro screen so a user can bail on any individual category
//        without abandoning signup entirely.
//
// Reuses QuizScreen as-is — no scoring logic is invented here. Raw
// answers are persisted to Firestore via UserService in the same shape
// AppUser already expects (hobbyIds, careerId); everything else lands in
// a generic quizGeneralAnswers map, ready for whenever the real scoring
// pass happens (see the TODO at the bottom of quiz_screen.dart).
//
// Called from LoginScreen's "Create account" link in place of the old
// single-page SignUpScreen:
//   MaterialPageRoute(builder: (_) => SignUpFlowScreen(onDone: ...))
// `onDone` should do whatever the old SignUpScreen's onSuccess did (enter
// MainShell) — it fires whether the user completes every quiz or skips
// straight through all of them.
// ---------------------------------------------------------------------------

class SignUpFlowScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SignUpFlowScreen({super.key, required this.onDone});

  @override
  State<SignUpFlowScreen> createState() => _SignUpFlowScreenState();
}

class _SignUpFlowScreenState extends State<SignUpFlowScreen> {
  final _pageController = PageController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  DateTime? _dob;
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  int _step = 0;

  static const int _basicStepCount = 4; // name, email, password, dob

  // The 5 long-term quiz categories run in this order after account
  // creation. Kept as data so the intro/skip chain below can loop over
  // them rather than hand-writing 5 near-identical navigation calls.
  late final List<_QuizCategory> _quizCategories = [
    _QuizCategory(
      'Hobbies',
      'A few questions about how you spend your time.',
      kHobbiesQuizTests,
    ),
    _QuizCategory(
      'Career & Education',
      'What you do, and where you\u2019re headed.',
      kCareerQuizTests,
    ),
    _QuizCategory(
      'Looks & Preferences',
      'What you\u2019re drawn to in a partner.',
      kLooksQuizTests,
    ),
    _QuizCategory(
      'Lifestyle',
      'Day-to-day habits and how you like to live.',
      kLifestyleQuizTests,
    ),
    _QuizCategory(
      'Core Values',
      'The things that matter most long-term.',
      kCoreValuesQuizTests,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      _goToStep(_step - 1);
    }
  }

  void _next() {
    setState(() => _error = null);

    switch (_step) {
      case 0:
        if (_nameCtrl.text.trim().isEmpty) {
          setState(() => _error = 'Please enter your name.');
          return;
        }
        break;
      case 1:
        if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@')) {
          setState(() => _error = 'Please enter a valid email.');
          return;
        }
        break;
      case 2:
        if (_passwordCtrl.text.length < 6) {
          setState(() => _error = 'Password must be at least 6 characters.');
          return;
        }
        if (_passwordCtrl.text != _confirmCtrl.text) {
          setState(() => _error = 'Passwords do not match.');
          return;
        }
        break;
      case 3:
        if (_dob == null) {
          setState(() => _error = 'Please enter your date of birth.');
          return;
        }
        _createAccount();
        return; // _createAccount drives what happens next, not this method
    }

    _goToStep(_step + 1);
  }

  Future<void> _createAccount() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService.instance.signUp(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      name: _nameCtrl.text,
      dob: _dob!,
    );

    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _loading = false;
        _error = result.errorMessage;
      });
      return;
    }

    setState(() => _loading = false);
    _runQuizChain(0);
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

  // ── Quiz chain (after account creation) ──────────────────────────────────

  /// Pushes the intro screen for quiz category [index]. Recurses into the
  /// next category (or finishes) once that category's intro resolves,
  /// whichever way the user chose (started+completed, or skipped).
  Future<void> _runQuizChain(int index) async {
    if (index >= _quizCategories.length) {
      widget.onDone();
      return;
    }

    final category = _quizCategories[index];
    final overallStep = _basicStepCount + index; // for the progress dots
    final overallTotal = _basicStepCount + _quizCategories.length;

    final action = await Navigator.of(context).push<_QuizIntroAction>(
      MaterialPageRoute(
        builder: (_) => _QuizIntroScreen(
          category: category,
          stepIndex: overallStep,
          stepTotal: overallTotal,
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
    // action == skip, or the user backed out of the quiz mid-way (still
    // returns here either way) — either way, move to the next category.
    if (!mounted) return;
    _runQuizChain(index + 1);
  }

  /// Persists whatever the user actually answered. Only the two
  /// first-class AppUser fields (hobbyIds, careerId) are mapped directly;
  /// everything else goes into a generic bucket keyed by category, ready
  /// for the real scoring pass (see quiz_screen.dart's TODO) rather than
  /// inventing scoring math here.
  Future<void> _saveQuizAnswers(
    _QuizCategory category,
    QuizAnswers answers,
  ) async {
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
      fields['quizGeneralAnswers_${category.storageKey}'] =
          answers.generalAnswers;
    }

    if (fields.isNotEmpty) {
      await UserService.instance.updateProfile(fields);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _StepHeader(
              stepIndex: _step,
              stepTotal: _basicStepCount + _quizCategories.length,
              onBack: _back,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _NameStep(controller: _nameCtrl),
                  _EmailStep(controller: _emailCtrl),
                  _PasswordStep(
                    passwordController: _passwordCtrl,
                    confirmController: _confirmCtrl,
                    obscure: _obscure,
                    onToggleObscure: () => setState(() => _obscure = !_obscure),
                  ),
                  _DobStep(dob: _dob, onPick: _pickDob),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: ErrorBox(message: _error!),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: AuthButton(
                label: _step == _basicStepCount - 1
                    ? 'Create Account'
                    : 'Continue',
                loading: _loading,
                onTap: _next,
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

  String get storageKey =>
      title.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), '_');
}

enum _QuizIntroAction { start, skip }

// ── Shared step chrome ───────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final int stepIndex;
  final int stepTotal;
  final VoidCallback onBack;

  const _StepHeader({
    required this.stepIndex,
    required this.stepTotal,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.panelBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accentGlow),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: List.generate(stepTotal, (i) {
                final isDone = i <= stepIndex;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i == stepTotal - 1 ? 0 : 4),
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.accent
                          : Colors.white.withOpacity(0.08),
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

class _StepQuestion extends StatelessWidget {
  final String question;
  final String subtitle;
  final Widget child;

  const _StepQuestion({
    required this.question,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

// ── Steps 1-4: basic info ────────────────────────────────────────────────

class _NameStep extends StatelessWidget {
  final TextEditingController controller;
  const _NameStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _StepQuestion(
      question: 'What\u2019s your name?',
      subtitle: 'This is how you\u2019ll appear to other people.',
      child: AuthField(controller: controller, label: 'Full Name'),
    );
  }
}

class _EmailStep extends StatelessWidget {
  final TextEditingController controller;
  const _EmailStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _StepQuestion(
      question: 'What\u2019s your email?',
      subtitle: 'We\u2019ll use this to sign you in.',
      child: AuthField(
        controller: controller,
        label: 'Email',
        keyboardType: TextInputType.emailAddress,
      ),
    );
  }
}

class _PasswordStep extends StatelessWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscure;
  final VoidCallback onToggleObscure;

  const _PasswordStep({
    required this.passwordController,
    required this.confirmController,
    required this.obscure,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return _StepQuestion(
      question: 'Create a password',
      subtitle: 'At least 6 characters.',
      child: Column(
        children: [
          AuthField(
            controller: passwordController,
            label: 'Password',
            obscure: obscure,
            suffix: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size: 18,
              ),
              onPressed: onToggleObscure,
            ),
          ),
          const SizedBox(height: 14),
          AuthField(
            controller: confirmController,
            label: 'Confirm Password',
            obscure: true,
          ),
        ],
      ),
    );
  }
}

class _DobStep extends StatelessWidget {
  final DateTime? dob;
  final VoidCallback onPick;

  const _DobStep({required this.dob, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return _StepQuestion(
      question: 'When\u2019s your birthday?',
      subtitle: 'You must be 18 or older to use 2Souls.',
      child: GestureDetector(
        onTap: onPick,
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
                dob == null
                    ? 'Date of Birth'
                    : '${dob!.day}/${dob!.month}/${dob!.year}',
                style: TextStyle(
                  color: dob == null
                      ? AppColors.textSecondary.withOpacity(0.5)
                      : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
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
            _StepHeader(
              stepIndex: stepIndex,
              stepTotal: stepTotal,
              onBack: () => Navigator.of(context).pop(_QuizIntroAction.skip),
            ),
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
                      onPressed: () =>
                          Navigator.of(context).pop(_QuizIntroAction.start),
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
                    onTap: () =>
                        Navigator.of(context).pop(_QuizIntroAction.skip),
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
