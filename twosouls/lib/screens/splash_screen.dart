import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ---------------------------------------------------------------------------
// SplashScreen
//
// Animated splash screen shown on app launch before Firebase auth resolves.
// Animation sequence (total ~2.8s):
//   0.0s — deep navy background fades in
//   0.3s — logo fades and scales up from 0.6 → 1.0 with ease-out
//   1.0s — "2 SOULS" text slides up and fades in
//   1.6s — tagline fades in ("Find your other half")
//   2.0s — constellation particle ring pulses once around the logo
//   2.4s — subtle shimmer sweep across the logo from left to right
//
// The logo image itself is the PNG from assets/images/logo.png.
// All other visual elements (particle ring, shimmer) are drawn in code
// so the logo stays clean with no extra assets needed.
// ---------------------------------------------------------------------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Logo: fade + scale
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  // Text: slide up + fade
  late final AnimationController _textCtrl;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineFade;

  // Constellation ring pulse
  late final AnimationController _ringCtrl;

  // Shimmer sweep
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmerPos;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoScale = Tween(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic));

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _titleFade = CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _titleSlide = Tween(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _taglineFade = CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _shimmerPos = Tween(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await _logoCtrl.forward();
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 100));
    await _textCtrl.forward();
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 200));
    await _ringCtrl.forward();
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 150));
    await _shimmerCtrl.forward();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _ringCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep, // exact logo background colour
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Logo with ring pulse + shimmer ──────────────────────────────
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Constellation ring — pulses outward on logo arrival
                  AnimatedBuilder(
                    animation: _ringCtrl,
                    builder: (_, __) => CustomPaint(
                      size: const Size(200, 200),
                      painter: _ConstellationRingPainter(t: _ringCtrl.value),
                    ),
                  ),
                  // Logo image
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 160,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  // Shimmer sweep over the logo
                  AnimatedBuilder(
                    animation: _shimmerCtrl,
                    builder: (_, __) {
                      if (_shimmerCtrl.value == 0)
                        return const SizedBox.shrink();
                      return ClipOval(
                        child: SizedBox(
                          width: 160,
                          height: 160,
                          child: CustomPaint(
                            painter: _ShimmerPainter(pos: _shimmerPos.value),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // ── Title ────────────────────────────────────────────────────────
            FadeTransition(
              opacity: _titleFade,
              child: SlideTransition(
                position: _titleSlide,
                child: const Text(
                  '2 SOULS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ── Tagline ───────────────────────────────────────────────────────
            FadeTransition(
              opacity: _taglineFade,
              child: Text(
                'Find your other half',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Constellation ring painter ─────────────────────────────────────────────
// Draws a ring of small star-dots that expands outward and fades as t → 1,
// mimicking the constellation motif in the logo.

class _ConstellationRingPainter extends CustomPainter {
  final double t; // 0 → 1
  _ConstellationRingPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width * 0.56;
    final r = 70.0 + (maxR - 70.0) * Curves.easeOut.transform(t);
    final opacity = (1.0 - t).clamp(0.0, 1.0);

    const starCount = 12;
    for (int i = 0; i < starCount; i++) {
      final angle = (i / starCount) * 2 * math.pi;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      final starSize = (i % 3 == 0) ? 3.0 : 1.8;
      canvas.drawCircle(
        Offset(x, y),
        starSize,
        Paint()
          ..color = Colors.white.withOpacity(
            opacity * (i % 3 == 0 ? 0.9 : 0.55),
          ),
      );
    }

    // Thin ring outline
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = Colors.white.withOpacity(opacity * 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant _ConstellationRingPainter old) => old.t != t;
}

// ── Shimmer sweep painter ─────────────────────────────────────────────────
// A diagonal light sweep left-to-right across the logo.

class _ShimmerPainter extends CustomPainter {
  final double pos; // -1 → 2
  _ShimmerPainter({required this.pos});

  @override
  void paint(Canvas canvas, Size size) {
    final x = pos * size.width;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.0),
              ],
              transform: GradientRotation(0.4),
            ).createShader(
              Rect.fromLTWH(x - size.width, 0, size.width * 3, size.height),
            ),
    );
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) => old.pos != pos;
}
