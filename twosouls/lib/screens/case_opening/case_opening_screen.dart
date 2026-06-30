import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/card_rarity_model.dart';
import '../../models/match_pool.dart';
import '../profile_screen.dart' show RarityTierVisuals, wearAdjustedGradient;

// ---------------------------------------------------------------------------
// CaseOpeningScreen
//
// A CS:GO-style case-opening draw. A horizontal reel of small profile
// cards scrolls rapidly past a fixed center indicator line, decelerating
// until it lands precisely on the winning candidate (drawn with weighted
// odds — mostly Bronze/Silver, rare Gold/Platinum/Purple, see
// MatchPool.drawWeighted).
//
// On landing, the winning candidate is "won" and handed back via
// onWin — the caller (e.g. QuizHubScreen) is responsible for adding it
// into the Collection/Messages list.
// ---------------------------------------------------------------------------

class CaseOpeningScreen extends StatefulWidget {
  final void Function(MatchCandidate winner) onWin;

  const CaseOpeningScreen({super.key, required this.onWin});

  @override
  State<CaseOpeningScreen> createState() => _CaseOpeningScreenState();
}

class _CaseOpeningScreenState extends State<CaseOpeningScreen>
    with SingleTickerProviderStateMixin {
  static const double _tileWidth = 110;
  static const double _tileGap = 10;
  static const int _reelLength = 60; // total tiles shown in the reel

  late final List<MatchCandidate> _pool;
  late final List<MatchCandidate> _reel;
  late final MatchCandidate _winner;
  late final int _winnerIndex;

  late final AnimationController _ctrl;
  late final Animation<double> _scrollAnim;
  final ScrollController _scrollController = ScrollController();

  bool _spinning = false;
  bool _revealed = false;
  double _targetOffset = 0;

  @override
  void initState() {
    super.initState();
    _pool = MatchPool.buildPool(count: 24);
    _winner = MatchPool.drawWeighted(_pool);

    // Build a long reel of random pool entries, then force a specific
    // index near the end to be the winner so the deceleration lands on it.
    final rng = Random();
    _reel = List.generate(_reelLength, (i) => _pool[rng.nextInt(_pool.length)]);
    _winnerIndex = _reelLength - 8; // leaves a few tiles of "overshoot" room
    _reel[_winnerIndex] = _winner;

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );

    // Ease-out cubic-ish curve so it starts fast and decelerates hard
    // toward the end, like a real case opening.
    _scrollAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuart);

    _scrollAnim.addListener(() {
      if (!_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.hasContentDimensions
          ? _scrollController.position.maxScrollExtent
          : double.infinity;
      final offset = (_scrollAnim.value * _targetOffset).clamp(0.0, maxExtent);
      _scrollController.jumpTo(offset);
    });

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_revealed) {
        setState(() {
          _revealed = true;
          _spinning = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startSpin() {
    if (_spinning || _revealed) return;
    setState(() => _spinning = true);

    // Compute target scroll offset now that the screen's width is known.
    final screenW = MediaQuery.of(context).size.width;
    final centerX = screenW / 2;
    final tileStride = _tileWidth + _tileGap;
    _targetOffset = (_winnerIndex * tileStride + _tileWidth / 2) - centerX;

    _ctrl.forward(from: 0);
  }

  void _claim() {
    widget.onWin(_winner);
    Navigator.of(context).pop(_winner);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onClose: () => Navigator.of(context).pop()),
            const SizedBox(height: 8),
            Text(
              _revealed ? 'You matched with ${_winner.name}!' : 'Open the case to find a match',
              style: TextStyle(
                color: _revealed ? AppColors.gold : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // ── Reel ──────────────────────────────────────────────────
            SizedBox(
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _scrollController,
                    child: Row(
                      children: List.generate(_reel.length, (i) {
                        final candidate = _reel[i];
                        final isWinnerTile = i == _winnerIndex;
                        return Padding(
                          padding: const EdgeInsets.only(right: _tileGap),
                          child: _ReelTile(
                            candidate: candidate,
                            width: _tileWidth,
                            highlight: _revealed && isWinnerTile,
                          ),
                        );
                      }),
                    ),
                  ),

                  // Center indicator line
                  IgnorePointer(
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(color: AppColors.gold.withOpacity(0.7), blurRadius: 12, spreadRadius: 1),
                        ],
                      ),
                    ),
                  ),
                  // Top/bottom arrow markers on the indicator
                  const Positioned(
                    top: 0,
                    child: Icon(Icons.arrow_drop_down, color: AppColors.gold, size: 28),
                  ),
                  const Positioned(
                    bottom: 0,
                    child: Icon(Icons.arrow_drop_up, color: AppColors.gold, size: 28),
                  ),

                  // Fade edges so tiles don't look like they're cut off harshly
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.bgDark, AppColors.bgDark.withOpacity(0)],
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.bgDark.withOpacity(0), AppColors.bgDark],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            if (_revealed)
              _WinnerCard(candidate: _winner)
            else
              const SizedBox.shrink(),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _revealed ? _claim : (_spinning ? null : _startSpin),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _revealed ? AppColors.gold : AppColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _revealed ? 'Add to Collection' : (_spinning ? 'Opening\u2026' : 'Open Case'),
                    style: TextStyle(
                      color: _revealed ? Colors.black : Colors.white,
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

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'CASE OPENING',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.panelBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x33B44CFF)),
              ),
              child: const Icon(Icons.close, color: AppColors.textSecondary, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelTile extends StatelessWidget {
  final MatchCandidate candidate;
  final double width;
  final bool highlight;

  const _ReelTile({required this.candidate, required this.width, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final rc = candidate.tier.primaryColor;
    final sheen = candidate.wear.sheenIntensity;
    final gradient = wearAdjustedGradient(candidate.tier, sheen);

    return AnimatedScale(
      duration: const Duration(milliseconds: 300),
      scale: highlight ? 1.08 : 1.0,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          border: Border.all(
            color: highlight ? AppColors.gold : rc.withOpacity(0.5 + sheen * 0.3),
            width: highlight ? 2.4 : 1.2,
          ),
          boxShadow: highlight
              ? [BoxShadow(color: AppColors.gold.withOpacity(0.6), blurRadius: 20, spreadRadius: 2)]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: rc.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: rc.withOpacity(0.5)),
                ),
                child: Text(
                  candidate.tier.label,
                  style: TextStyle(color: rc, fontSize: 6, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: rc.withOpacity(0.5)),
                  ),
                  child: Center(child: Icon(Icons.person, color: rc.withOpacity(0.7), size: 24)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                candidate.name,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WinnerCard extends StatelessWidget {
  final MatchCandidate candidate;
  const _WinnerCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final rc = candidate.tier.primaryColor;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rc.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: rc, width: 1.6),
            ),
            child: Icon(Icons.person, color: rc, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${candidate.name}, ${candidate.age}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${candidate.tier.label} \u2022 ${candidate.wear.label}',
                  style: TextStyle(color: rc, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
