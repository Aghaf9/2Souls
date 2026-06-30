import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/match_pool.dart';
import '../../models/match_limits.dart';
import '../../models/profile_completion.dart';
import '../case_opening/case_opening_screen.dart';
import '../top_match/top_match_screen.dart';
import '../messages_screen.dart' show CollectionStore;
import 'quiz_screen.dart';

// ---------------------------------------------------------------------------
// QuizHubScreen
//
// Shown after picking "Long Term" on RelationshipTypeScreen. Layout, top
// to bottom:
//   1. TOP MATCH box — randomly reveals a candidate at 80%+ compatibility
//      with a FIFA-style "card unpacked" walkout animation. Limited to
//      once per 7 days (MatchLimits.kTopMatchWindow).
//   2. OPEN CASE box — the original gambling-style draw, limited to 2
//      opens per rolling 24h window (MatchLimits.kMaxCasesPerDay).
//   3. A square, rounded "COMPLETED X/5" progress box. Tapping it expands
//      and navigates to the Profile tab, where the user can finish
//      whatever's left (bio, photos, quizzes). Once everything is
//      complete, this box disappears from the hub entirely.
// ---------------------------------------------------------------------------

class _QuizCategoryInfo {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<QuizTest> tests;

  const _QuizCategoryInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.tests,
  });
}

class QuizHubScreen extends StatefulWidget {
  const QuizHubScreen({super.key});

  @override
  State<QuizHubScreen> createState() => _QuizHubScreenState();
}

class _QuizHubScreenState extends State<QuizHubScreen> {
  final _completionStore = ProfileCompletionStore.instance;
  final _limits = MatchLimits.instance;

  @override
  void initState() {
    super.initState();
    _completionStore.addListener(_onChanged);
    _limits.addListener(_onChanged);
  }

  @override
  void dispose() {
    _completionStore.removeListener(_onChanged);
    _limits.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  List<_QuizCategoryInfo> get _categories => [
    _QuizCategoryInfo(
      title: 'Hobbies',
      description: 'What you actually like spending time on',
      icon: Icons.sports_esports_outlined,
      color: const Color(0xFF3D74FF),
      tests: kCoreValuesQuizTests, // placeholder shared content for now
    ),
    _QuizCategoryInfo(
      title: 'Career & Education',
      description: 'Where you\u2019re headed professionally',
      icon: Icons.work_outline,
      color: AppColors.textSecondary,
      tests: kCoreValuesQuizTests,
    ),
    _QuizCategoryInfo(
      title: 'Looks',
      description: 'Physical preferences and presentation',
      icon: Icons.face_outlined,
      color: AppColors.gold,
      tests: kCoreValuesQuizTests,
    ),
    _QuizCategoryInfo(
      title: 'Lifestyle',
      description: 'Health, routine, and how you live day to day',
      icon: Icons.fitness_center_outlined,
      color: AppColors.emerald,
      tests: kCoreValuesQuizTests,
    ),
    _QuizCategoryInfo(
      title: 'Core Values',
      description: 'Family, beliefs, language, and what matters most',
      icon: Icons.auto_awesome,
      color: AppColors.purple,
      tests: kCoreValuesQuizTests,
    ),
  ];

  Future<void> _openQuiz(int index, _QuizCategoryInfo info) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(tests: info.tests, title: info.title),
      ),
    );
    // QuizScreen pops itself after its completion dialog closes — treat
    // returning here as "completed" for now, since there's no real
    // per-question scoring/answer validation yet.
    _completionStore.markQuizComplete(index);
  }

  void _openCaseOpening() {
    if (!_limits.canOpenCase) return;
    _limits.recordCaseOpen();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaseOpeningScreen(
          onWin: (MatchCandidate winner) {
            CollectionStore.instance.addWonMatch(winner);
          },
        ),
      ),
    );
  }

  void _openTopMatch() {
    if (!_limits.canOpenTopMatch) return;
    _limits.recordTopMatchOpen();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopMatchScreen(
          onWin: (MatchCandidate winner) {
            CollectionStore.instance.addWonMatch(winner);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0x22B44CFF))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.panelBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x33B44CFF)),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'LONG TERM',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopMatchBox(
                      onTap: _openTopMatch,
                      canOpen: _limits.canOpenTopMatch,
                      countdown: _limits.timeUntilNextTopMatch,
                    ),
                    const SizedBox(height: 14),
                    _CaseBox(
                      onTap: _openCaseOpening,
                      canOpen: _limits.canOpenCase,
                      remaining: _limits.casesRemainingToday,
                      countdown: _limits.timeUntilNextCaseSlot,
                    ),
                    const SizedBox(height: 18),
                    _QuizProgressBox(
                      categories: categories,
                      completed: _completionStore.completedQuizzes,
                      onTapQuiz: _openQuiz,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top Match box (7-day limit) ──────────────────────────────────────────

// ── Shared base for the Top Match / Open Case boxes — guarantees both
// are visually symmetric (same padding, radius, icon size, border weight)
// instead of being two independently-tuned containers that drifted apart.

class _HubActionBox extends StatelessWidget {
  final VoidCallback? onTap;
  final bool enabled;
  final IconData icon;
  final String title;
  final String subtitle;

  const _HubActionBox({
    required this.onTap,
    required this.enabled,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.55,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E2208), Color(0xFF161002)],
            ),
            border: Border.all(
              color: AppColors.gold.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.18),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.gold, size: 34),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.85),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopMatchBox extends StatelessWidget {
  final VoidCallback onTap;
  final bool canOpen;
  final Duration? countdown;

  const _TopMatchBox({
    required this.onTap,
    required this.canOpen,
    required this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    return _HubActionBox(
      onTap: onTap,
      enabled: canOpen,
      icon: Icons.workspace_premium,
      title: 'FIND YOUR STRONGEST MATCH',
      subtitle: canOpen
          ? 'Guaranteed 80%+ compatibility \u2014 once every 7 days'
          : 'Available again in ${MatchLimits.formatCountdown(countdown ?? Duration.zero)}',
    );
  }
}

// ── Open Case box (2/day limit) ──────────────────────────────────────────

class _CaseBox extends StatelessWidget {
  final VoidCallback onTap;
  final bool canOpen;
  final int remaining;
  final Duration? countdown;

  const _CaseBox({
    required this.onTap,
    required this.canOpen,
    required this.remaining,
    required this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    return _HubActionBox(
      onTap: onTap,
      enabled: canOpen,
      icon: Icons.card_giftcard,
      title: 'OPEN A CASE',
      subtitle: canOpen
          ? '$remaining of ${MatchLimits.kMaxCasesPerDay} opens left today'
          : 'Next case in ${MatchLimits.formatCountdown(countdown ?? Duration.zero)}',
    );
  }
}

// ── Quiz progress box: symmetric 2-column grid ──────────────────────────

class _QuizProgressBox extends StatelessWidget {
  final List<_QuizCategoryInfo> categories;
  final Set<int> completed;
  final void Function(int index, _QuizCategoryInfo info) onTapQuiz;

  const _QuizProgressBox({
    required this.categories,
    required this.completed,
    required this.onTapQuiz,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColors.panelBg,
        border: Border.all(color: AppColors.panelBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'COMPLETED',
                style: TextStyle(
                  color: AppColors.purple,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '${completed.length} / ${categories.length}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completed.length / categories.length,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.07),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
            ),
          ),
          const SizedBox(height: 16),
          // Symmetric 2-column grid — 5 quizzes means the last cell is
          // left empty rather than letting the 5th tile span full width
          // and break the grid's symmetry. A LayoutBuilder computes equal
          // tile heights so every row lines up cleanly regardless of how
          // long each title/description text runs.
          LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 2;
              const spacing = 10.0;
              final tileWidth =
                  (constraints.maxWidth - spacing) / crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(categories.length, (index) {
                  final info = categories[index];
                  final isDone = completed.contains(index);
                  return SizedBox(
                    width: tileWidth,
                    child: _QuizTile(
                      info: info,
                      isDone: isDone,
                      onTap: () => onTapQuiz(index, info),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuizTile extends StatelessWidget {
  final _QuizCategoryInfo info;
  final bool isDone;
  final VoidCallback onTap;

  const _QuizTile({
    required this.info,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 108,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: info.color.withOpacity(isDone ? 0.5 : 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: info.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: info.color.withOpacity(0.3)),
                  ),
                  child: Icon(info.icon, color: info.color, size: 16),
                ),
                if (isDone)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.emerald.withOpacity(0.9),
                    size: 16,
                  )
                else
                  Icon(
                    Icons.radio_button_unchecked,
                    color: Colors.white.withOpacity(0.15),
                    size: 16,
                  ),
              ],
            ),
            const Spacer(),
            Text(
              info.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isDone ? 'Done' : 'Start',
              style: TextStyle(
                color: isDone
                    ? AppColors.emerald.withOpacity(0.9)
                    : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
