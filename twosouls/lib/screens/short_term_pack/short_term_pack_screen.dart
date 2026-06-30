import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/card_rarity_model.dart';
import '../../models/match_pool.dart';
import '../profile_screen.dart' show RarityTierVisuals, wearAdjustedGradient;

// ---------------------------------------------------------------------------
// ShortTermPackScreen
//
// A FIFA Ultimate Team-style pack opening for Short Term matches. The pool
// is built from people who answered the SAME short-term quiz choices as
// the user and have a high looks-match score (see
// MatchPool.buildShortTermPool) — narrower and more targeted than the
// general Open Case gambling pool.
//
// Flow: tap the closed pack -> 4 cards flip face-up one after another ->
// user taps ONE of the 4 to keep -> that candidate is handed back via
// onPick.
//
// guaranteedTier is optional and represents a purchased pass's minimum
// tier guarantee (Silver/Gold/Platinum/Purple) — see PassTier in
// match_pool.dart. No real purchase flow exists yet; passing null means
// "no guarantee, normal odds".
// ---------------------------------------------------------------------------

class ShortTermPackScreen extends StatefulWidget {
  final void Function(MatchCandidate picked) onPick;
  final PassTier? guaranteedTier;

  const ShortTermPackScreen({
    super.key,
    required this.onPick,
    this.guaranteedTier,
  });

  @override
  State<ShortTermPackScreen> createState() => _ShortTermPackScreenState();
}

class _ShortTermPackScreenState extends State<ShortTermPackScreen>
    with TickerProviderStateMixin {
  late final List<MatchCandidate> _packCards;

  bool _opened = false;
  int? _selectedIndex;

  late final AnimationController _openCtrl;
  late final List<AnimationController> _flipCtrls;

  @override
  void initState() {
    super.initState();
    final pool = MatchPool.buildShortTermPool(count: 20);
    _packCards = MatchPool.drawPack(
      pool,
      cardCount: 4,
      guaranteedTier: widget.guaranteedTier,
    );

    _openCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipCtrls = List.generate(
      4,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _openCtrl.dispose();
    for (final c in _flipCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _openPack() async {
    if (_opened) return;
    setState(() => _opened = true);
    await _openCtrl.forward();

    // Flip each of the 4 cards face-up in a staggered sequence.
    for (int i = 0; i < _flipCtrls.length; i++) {
      _flipCtrls[i].forward();
      await Future.delayed(const Duration(milliseconds: 180));
    }
  }

  void _selectCard(int index) {
    if (_selectedIndex != null) return;
    setState(() => _selectedIndex = index);
  }

  void _confirmPick() {
    if (_selectedIndex == null) return;
    widget.onPick(_packCards[_selectedIndex!]);
    Navigator.of(context).pop(_packCards[_selectedIndex!]);
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
            if (widget.guaranteedTier != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                ),
                child: Text(
                  '${widget.guaranteedTier!.label} active \u2014 ${widget.guaranteedTier!.minimumTier.label} or higher guaranteed',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              !_opened
                  ? 'Tap the pack to open it'
                  : (_selectedIndex == null
                        ? 'Pick one card to keep'
                        : 'Great choice!'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: !_opened
                    ? _ClosedPack(onTap: _openPack)
                    : _OpenedPackGrid(
                        cards: _packCards,
                        flipCtrls: _flipCtrls,
                        selectedIndex: _selectedIndex,
                        onSelect: _selectCard,
                      ),
              ),
            ),
            if (_selectedIndex != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmPick,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Keep ${_packCards[_selectedIndex!].name}',
                      style: const TextStyle(
                        color: Colors.black,
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
            'SHORT TERM PACK',
            style: TextStyle(
              color: AppColors.purple,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
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
              child: const Icon(
                Icons.close,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Closed pack — tap to open ─────────────────────────────────────────

class _ClosedPack extends StatelessWidget {
  final VoidCallback onTap;
  const _ClosedPack({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A1A5C), Color(0xFF1F0A28)],
          ),
          border: Border.all(color: AppColors.purple, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withOpacity(0.5),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt, color: AppColors.purple, size: 56),
            const SizedBox(height: 12),
            const Text(
              'TAP TO OPEN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Opened pack: 4 cards in a row, flip in sequence ───────────────────

class _OpenedPackGrid extends StatelessWidget {
  final List<MatchCandidate> cards;
  final List<AnimationController> flipCtrls;
  final int? selectedIndex;
  final void Function(int index) onSelect;

  const _OpenedPackGrid({
    required this.cards,
    required this.flipCtrls,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: List.generate(cards.length, (i) {
          return AnimatedBuilder(
            animation: flipCtrls[i],
            builder: (context, child) {
              final t = flipCtrls[i].value;
              // Flip rotation: 0 -> pi/2 shows the back, pi/2 -> pi shows
              // the front (mirrored back to normal reading direction).
              final angle = t * 3.14159;
              final showFront = t > 0.5;

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(angle),
                child: showFront
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(3.14159),
                        child: _PackCardFace(
                          candidate: cards[i],
                          isSelected: selectedIndex == i,
                          isDimmed: selectedIndex != null && selectedIndex != i,
                          onTap: () => onSelect(i),
                        ),
                      )
                    : const _PackCardBack(),
              );
            },
          );
        }),
      ),
    );
  }
}

class _PackCardBack extends StatelessWidget {
  const _PackCardBack();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF3A1248), Color(0xFF1A0822)],
        ),
        border: Border.all(
          color: AppColors.purple.withOpacity(0.6),
          width: 1.4,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.bolt,
          color: AppColors.purple.withOpacity(0.6),
          size: 32,
        ),
      ),
    );
  }
}

class _PackCardFace extends StatelessWidget {
  final MatchCandidate candidate;
  final bool isSelected;
  final bool isDimmed;
  final VoidCallback onTap;

  const _PackCardFace({
    required this.candidate,
    required this.isSelected,
    required this.isDimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rc = candidate.tier.primaryColor;
    final sheen = candidate.wear.sheenIntensity;
    final gradient = wearAdjustedGradient(candidate.tier, sheen);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isDimmed ? 0.35 : 1.0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 250),
          scale: isSelected ? 1.08 : 1.0,
          child: Container(
            width: 130,
            height: 180,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              border: Border.all(
                color: isSelected ? AppColors.gold : rc.withOpacity(0.6),
                width: isSelected ? 2.2 : 1.4,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.5),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: rc.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: rc.withOpacity(0.5)),
                  ),
                  child: Text(
                    candidate.tier.label,
                    style: TextStyle(
                      color: rc,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: rc.withOpacity(0.5)),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person,
                        color: rc.withOpacity(0.7),
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${candidate.name}, ${candidate.age}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${candidate.sharedShortTermAnswers}/3 shared \u2022 ${candidate.looksMatchScore}% looks',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.8),
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
