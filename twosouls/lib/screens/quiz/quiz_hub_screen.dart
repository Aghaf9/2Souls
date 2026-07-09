import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/floor_cards_background.dart';
import '../../models/match_pool.dart';
import '../../models/match_limits.dart';
import '../../ads/ad_manager.dart';
import '../case_opening/case_opening_screen.dart';
import '../top_match/top_match_screen.dart';
import '../messages_screen.dart' show CollectionStore;

// ---------------------------------------------------------------------------
// QuizHubScreen
//
// Shown after picking "Long Term" on RelationshipTypeScreen. Layout:
//   1. TOP MATCH box — randomly reveals a candidate at 80%+ compatibility
//      with a FIFA-style "card unpacked" walkout animation. Limited to
//      once per 7 days (MatchLimits.kTopMatchWindow).
//   2. OPEN CASE box — the original gambling-style draw, limited to 2
//      opens per rolling 24h window (MatchLimits.kMaxCasesPerDay).
//
// The 5-quiz "Completed X/5" box that used to live here has been removed
// permanently — quizzes are only ever started from the checklist sheet on
// the Profile screen now (see profile_screen.dart's
// _CompletionChecklistSheet).
// ---------------------------------------------------------------------------

class QuizHubScreen extends StatefulWidget {
  const QuizHubScreen({super.key});

  @override
  State<QuizHubScreen> createState() => _QuizHubScreenState();
}

class _QuizHubScreenState extends State<QuizHubScreen> {
  final _limits = MatchLimits.instance;

  @override
  void initState() {
    super.initState();
    _limits.addListener(_onChanged);
  }

  @override
  void dispose() {
    _limits.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
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
            // Show interstitial once the user claims their card.
            AdManager.instance.showInterstitial();
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
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.panelBorder),
                ),
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
                        border: Border.all(color: AppColors.accentGlow),
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
                      color: AppColors.accent,
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
                    child: IgnorePointer(child: FloorCardsBackground(seed: 4)),
                  ),
                  SingleChildScrollView(
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
              colors: [AppColors.surface, AppColors.bgDark],
            ),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGlow,
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.accent, size: 34),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
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
      title: 'OPEN SOULMATE',
      subtitle: canOpen
          ? 'Gold+ tier guaranteed \u2014 your closest match this week'
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
