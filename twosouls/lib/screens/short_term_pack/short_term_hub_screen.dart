import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/floor_cards_background.dart';
import '../../models/match_pool.dart';
import '../../models/match_limits.dart';
import '../messages_screen.dart' show CollectionStore;
import '../quiz/quiz_screen.dart';
import 'short_term_pack_screen.dart';

// ---------------------------------------------------------------------------
// ShortTermHubScreen
//
// The short-term quiz must be completed before the pack unlocks — the
// pack pool is built FROM the quiz answers (people who chose the same
// meetup spot/time/vibe as the user, see MatchPool.buildShortTermPool),
// so opening a pack without answering anything wouldn't make sense.
//
// Flow: quiz not done -> only a "Take the Quiz" box is shown. Once
// completed (tracked locally via _quizDone, not persisted past this
// screen's lifetime — no backend yet), the quiz box is replaced by the
// "Open a Pack" box, which is itself rate-limited to 2 opens per rolling
// 6-hour window (see MatchLimits.kMaxPacksPerWindow).
//
// guaranteedTier (Silver/Gold/Platinum/Purple pass) is a future
// monetization hook — no purchase flow exists yet, so it's always null
// here. The pack screen itself already supports it; wiring a real pass
// purchase just means passing a non-null PassTier through when opening.
// ---------------------------------------------------------------------------

class ShortTermHubScreen extends StatefulWidget {
  const ShortTermHubScreen({super.key});

  @override
  State<ShortTermHubScreen> createState() => _ShortTermHubScreenState();
}

class _ShortTermHubScreenState extends State<ShortTermHubScreen> {
  bool _quizDone = false;
  final _limits = MatchLimits.instance;

  @override
  void initState() {
    super.initState();
    _limits.addListener(_onLimitsChanged);
  }

  @override
  void dispose() {
    _limits.removeListener(_onLimitsChanged);
    super.dispose();
  }

  void _onLimitsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _takeQuiz(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            QuizScreen(tests: kShortTermQuizTests, title: 'Short Term'),
      ),
    );
    // QuizScreen pops itself after its completion dialog closes — treat
    // returning here as "completed" for now, since there's no real
    // per-question scoring/answer validation yet.
    if (mounted) setState(() => _quizDone = true);
  }

  void _openPack(BuildContext context) {
    if (!_limits.canOpenPack) return;
    _limits.recordPackOpen();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShortTermPackScreen(
          guaranteedTier:
              null, // TODO: pass the user's active PassTier once purchasable.
          onPick: (MatchCandidate picked) {
            CollectionStore.instance.addWonMatch(picked);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    'SHORT TERM',
                    style: TextStyle(
                      color: AppColors.purple,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(child: FloorCardsBackground(seed: 5)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_quizDone)
                          _QuizGateBox(onTap: () => _takeQuiz(context))
                        else ...[
                          _PackBox(
                            onTap: () => _openPack(context),
                            canOpen: _limits.canOpenPack,
                            remaining: _limits.packsRemainingInWindow,
                            countdown: _limits.timeUntilNextPackSlot,
                          ),
                          const SizedBox(height: 12),
                          _RetakeQuizRow(onTap: () => _takeQuiz(context)),
                        ],
                      ],
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

// ── Quiz gate — must be completed before the pack unlocks ────────────────

class _QuizGateBox extends StatelessWidget {
  final VoidCallback onTap;
  const _QuizGateBox({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A1248), Color(0xFF1A0822)],
          ),
          border: Border.all(
            color: AppColors.purple.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withOpacity(0.25),
              blurRadius: 22,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.quiz_outlined, color: AppColors.purple, size: 34),
            const SizedBox(height: 10),
            const Text(
              'TAKE THE QUIZ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.purple,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Answer a few quick questions to unlock your pack',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.85),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackBox extends StatelessWidget {
  final VoidCallback onTap;
  final bool canOpen;
  final int remaining;
  final Duration? countdown;

  const _PackBox({
    required this.onTap,
    required this.canOpen,
    required this.remaining,
    required this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canOpen ? onTap : null,
      child: Opacity(
        opacity: canOpen ? 1.0 : 0.55,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3A1248), Color(0xFF1A0822)],
            ),
            border: Border.all(
              color: AppColors.purple.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withOpacity(0.25),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.bolt, color: AppColors.purple, size: 34),
              const SizedBox(height: 10),
              const Text(
                'OPEN A PACK',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.purple,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                canOpen
                    ? '$remaining of ${MatchLimits.kMaxPacksPerWindow} packs left \u2014 4 cards pulled from people who match your answers'
                    : 'Next pack in ${MatchLimits.formatCountdown(countdown ?? Duration.zero)}',
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

class _RetakeQuizRow extends StatelessWidget {
  final VoidCallback onTap;
  const _RetakeQuizRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.refresh,
            color: AppColors.textSecondary.withOpacity(0.6),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            'Retake the quiz',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
