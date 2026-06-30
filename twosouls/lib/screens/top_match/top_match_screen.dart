import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/card_rarity_model.dart';
import '../../models/match_pool.dart';
import '../profile_screen.dart' show RarityTierVisuals, wearAdjustedGradient;

// ---------------------------------------------------------------------------
// TopMatchScreen
//
// The rare "find your strongest match" walkout — limited to once per 7
// days (see MatchLimits.kTopMatchWindow). Always reveals a candidate at
// or above 80% compatibility (MatchPool.kTopMatchThreshold), with a
// FIFA Ultimate Team-style "card unpacked" reveal: the card flies in from
// off-screen bottom, slams into place with a scale overshoot, and a burst
// of light/rays plays behind it.
// ---------------------------------------------------------------------------

class TopMatchScreen extends StatefulWidget {
  final void Function(MatchCandidate winner) onWin;

  const TopMatchScreen({super.key, required this.onWin});

  @override
  State<TopMatchScreen> createState() => _TopMatchScreenState();
}

class _TopMatchScreenState extends State<TopMatchScreen>
    with TickerProviderStateMixin {
  late final MatchCandidate _winner;

  late final AnimationController _walkoutCtrl;
  late final Animation<double> _slideUp;
  late final Animation<double> _scalePop;
  late final Animation<double> _fadeIn;

  late final AnimationController _rayCtrl;

  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    final pool = MatchPool.buildPool(count: 30);
    _winner = MatchPool.drawTopMatch(pool);

    _walkoutCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _slideUp = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _walkoutCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _scalePop =
        TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.15), weight: 60),
          TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 40),
        ]).animate(
          CurvedAnimation(
            parent: _walkoutCtrl,
            curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
          ),
        );
    _fadeIn = CurvedAnimation(
      parent: _walkoutCtrl,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    );

    _rayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _walkoutCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _revealed = true);
      }
    });

    // Auto-start the walkout shortly after the screen opens.
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _walkoutCtrl.forward();
    });
  }

  @override
  void dispose() {
    _walkoutCtrl.dispose();
    _rayCtrl.dispose();
    super.dispose();
  }

  void _claim() {
    widget.onWin(_winner);
    Navigator.of(context).pop(_winner);
  }

  @override
  Widget build(BuildContext context) {
    final rc = _winner.tier.primaryColor;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Rotating light-ray burst behind the card
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _rayCtrl,
                builder: (context, _) => CustomPaint(
                  painter: _RayBurstPainter(t: _rayCtrl.value, color: rc),
                ),
              ),
            ),

            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'TOP MATCH',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          color: AppColors.gold.withOpacity(0.6),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _walkoutCtrl,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeIn.value,
                        child: Transform.translate(
                          offset: Offset(0, 220 * _slideUp.value),
                          child: Transform.scale(
                            scale: _scalePop.value,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: _TopMatchCard(
                      candidate: _winner,
                      glowing: !_revealed,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_revealed)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: 1.0,
                      child: Column(
                        children: [
                          Text(
                            '${_winner.compatibility}% Compatibility',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your strongest match this week',
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            if (_revealed)
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _claim,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Add to Collections',
                      style: TextStyle(
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

class _TopMatchCard extends StatelessWidget {
  final MatchCandidate candidate;
  final bool glowing;
  const _TopMatchCard({required this.candidate, required this.glowing});

  @override
  Widget build(BuildContext context) {
    final rc = candidate.tier.primaryColor;
    final sheen = candidate.wear.sheenIntensity;
    final gradient = wearAdjustedGradient(candidate.tier, sheen);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: Border.all(color: AppColors.gold, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(glowing ? 0.7 : 0.4),
            blurRadius: 36,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withOpacity(0.6)),
            ),
            child: const Text(
              'TOP MATCH',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: rc.withOpacity(0.7), width: 1.8),
              ),
              child: Center(child: Icon(Icons.person, color: rc, size: 48)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${candidate.name}, ${candidate.age}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            candidate.location,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: rc.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: rc.withOpacity(0.5)),
            ),
            child: Text(
              '${candidate.tier.label} \u2022 ${candidate.wear.label}',
              style: TextStyle(
                color: rc,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RayBurstPainter extends CustomPainter {
  final double t;
  final Color color;
  _RayBurstPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    const rayCount = 16;
    final angleOffset = t * 2 * math.pi;

    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 2 * math.pi + angleOffset;
      final length = size.width * 0.7;
      final p1 = center;
      final p2 = Offset(
        center.dx + length * math.cos(angle),
        center.dy + length * math.sin(angle),
      );
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [color.withOpacity(0.18), color.withOpacity(0.0)],
        ).createShader(Rect.fromPoints(p1, p2))
        ..strokeWidth = 28
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RayBurstPainter old) => old.t != t;
}
