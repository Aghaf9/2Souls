import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ---------------------------------------------------------------------------
// FloorCardsBackground
//
// Shared decorative "cards scattered on the floor" texture, used as a
// background layer on every main tab (Home, Discover, Cards, Profile).
// Pure visual texture — wrap usages in IgnorePointer at the call site so
// it never intercepts taps meant for real buttons/content sitting on top.
//
// A fixed seed (default 42, overridable per screen) keeps the scatter
// layout stable across rebuilds rather than jumping around every time
// setState fires elsewhere on the screen. Different screens can pass a
// different seed so each tab's background doesn't look identically
// positioned to the others.
// ---------------------------------------------------------------------------

class FloorCardsBackground extends StatelessWidget {
  final int seed;
  final int cardCount;
  final double opacity;

  const FloorCardsBackground({
    super.key,
    this.seed = 42,
    this.cardCount = 14,
    this.opacity = 0.06,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rng = Random(seed);
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final colors = [AppColors.bronze, AppColors.silver, AppColors.gold, AppColors.purple, AppColors.emerald];

        // Guard against zero/negative available space (e.g. during initial
        // layout passes before constraints are finalized) which would
        // otherwise make nextDouble() ranges invalid.
        if (w <= 70 || h <= 100) return const SizedBox.shrink();

        return Stack(
          children: List.generate(cardCount, (i) {
            final left = rng.nextDouble() * (w - 70);
            final top = rng.nextDouble() * (h - 100);
            final angle = (rng.nextDouble() - 0.5) * 1.4; // up to ~40 degrees either way
            final color = colors[rng.nextInt(colors.length)];
            final scale = 0.7 + rng.nextDouble() * 0.5;

            return Positioned(
              left: left,
              top: top,
              child: Transform.rotate(
                angle: angle,
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 60,
                      height: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color, width: 1.4),
                        color: color.withOpacity(0.15),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
