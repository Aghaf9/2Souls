import 'dart:math' as math;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// NightSkyBackground
//
// A full-bleed night sky backdrop: deep navy gradient, a soft moonlight
// radial glow at top-center, and 120 scattered stars at randomised sizes
// and brightnesses. Sits behind ALL app content via the theme's
// scaffoldBackgroundColor being transparent + this widget in a Stack.
//
// Stars are generated once from a fixed seed so the sky looks the same
// across every screen — the user sees the same constellation regardless
// of which tab they're on, which makes the night feel continuous rather
// than restarting on every navigation.
//
// NOT animated — star twinkle is handled separately by NightSkyScaffold
// only on screens that request it (costs essentially nothing on idle).
// ---------------------------------------------------------------------------

class NightSkyBackground extends StatelessWidget {
  const NightSkyBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _NightSkyPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _NightSkyPainter extends CustomPainter {
  static final List<_Star> _stars = _generateStars();

  static List<_Star> _generateStars() {
    final rng = math.Random(2025); // fixed seed → same sky everywhere
    return List.generate(140, (i) {
      return _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble() * 0.85, // stars mostly upper 85% of screen
        size: 0.6 + rng.nextDouble() * 2.2,
        opacity: 0.3 + rng.nextDouble() * 0.7,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    // ── 1. Base gradient — deep space ──────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF020818), // near-black space at top
            Color(0xFF060D24), // deep navy mid
            Color(0xFF080F2A), // slightly warmer navy at bottom
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // ── 2. Moonlight radial glow — top-center ─────────────────────────────
    final moonCenter = Offset(size.width * 0.62, size.height * 0.08);
    canvas.drawCircle(
      moonCenter,
      size.width * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFE8F0FF).withOpacity(0.12),
            const Color(0xFF6B9FFF).withOpacity(0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: moonCenter, radius: size.width * 0.55)),
    );

    // ── 3. Full moon disc ─────────────────────────────────────────────────
    // Soft glowing moon — doesn't dominate but clearly visible
    canvas.drawCircle(
      moonCenter,
      size.width * 0.065,
      Paint()
        ..color = const Color(0xFFE8F0FF).withOpacity(0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      moonCenter,
      size.width * 0.052,
      Paint()..color = const Color(0xFFF5F8FF).withOpacity(0.95),
    );

    // ── 4. Stars ──────────────────────────────────────────────────────────
    for (final star in _stars) {
      final x = star.x * size.width;
      final y = star.y * size.height;

      // Larger stars get a soft glow halo
      if (star.size > 2.0) {
        canvas.drawCircle(
          Offset(x, y),
          star.size * 2.5,
          Paint()
            ..color = Colors.white.withOpacity(star.opacity * 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }

      canvas.drawCircle(
        Offset(x, y),
        star.size,
        Paint()..color = Colors.white.withOpacity(star.opacity),
      );
    }

    // ── 5. Horizon atmospheric haze — ground-level glow ───────────────────
    final horizonRect = Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF0D1033).withOpacity(0.0),
            const Color(0xFF0D1033).withOpacity(0.6),
          ],
          stops: const [0.0, 0.7, 1.0],
        ).createShader(horizonRect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Star {
  final double x, y, size, opacity;
  const _Star({required this.x, required this.y, required this.size, required this.opacity});
}

// ---------------------------------------------------------------------------
// NightSkyScaffold
//
// Drop-in replacement for Scaffold that puts the night sky behind all
// content. Use this on any screen that should feel "outdoors at night".
// The existing Scaffold background is overridden to transparent so the
// night sky shows through.
// ---------------------------------------------------------------------------

class NightSkyScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? appBar;

  const NightSkyScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          const Positioned.fill(child: NightSkyBackground()),
          body,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Night glass panel — a frosted semi-transparent panel that looks like
// it's floating in front of the night sky, with a faint moonlit border.
// Use instead of plain Container for panels, cards, sheets.
// ---------------------------------------------------------------------------

class NightGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double opacity;
  final Color? borderColor;

  const NightGlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.opacity = 0.55,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(16);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: br,
        color: const Color(0xFF0D1033).withOpacity(opacity),
        border: Border.all(
          color: borderColor ?? const Color(0xFFE8F0FF).withOpacity(0.12),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B9FFF).withOpacity(0.06),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}
