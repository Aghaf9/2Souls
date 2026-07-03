import 'dart:math' as math;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// IdenticonAvatar
//
// Deterministic geometric avatar, similar to GitHub's identicons. Given
// any string seed (user id, name, etc.) always produces the same pattern
// — so test candidates always look distinct and consistent across rebuilds.
//
// Pattern: a 5×5 grid mirrored horizontally (so left half = right half)
// giving 15 independent cells. The seed hash drives which cells are "on"
// and the background/foreground colour pair.
//
// Used as placeholder profile pics for test MatchCandidates. Once a real
// photo is uploaded/fetched, replace with Image.memory/Image.network.
// ---------------------------------------------------------------------------

class IdenticonAvatar extends StatelessWidget {
  final String seed;
  final double size;
  final double borderRadius;
  final Color? borderColor;

  const IdenticonAvatar({
    super.key,
    required this.seed,
    this.size = 64,
    this.borderRadius = 12,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null ? Border.all(color: borderColor!, width: 1.6) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CustomPaint(
          painter: _IdenticonPainter(seed: seed),
          size: Size(size, size),
        ),
      ),
    );
  }
}

class _IdenticonPainter extends CustomPainter {
  final String seed;
  _IdenticonPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final hash = _hash(seed);
    final bg = _bgColor(hash);
    final fg = _fgColor(hash, bg);

    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = bg);

    const cols = 5;
    const rows = 5;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < (cols / 2).ceil(); col++) {
        // bit index from hash
        final bitIndex = row * 3 + col;
        final on = ((hash >> bitIndex) & 1) == 1;
        if (!on) continue;

        final mirrorCol = cols - 1 - col;

        // Draw cell and its mirror
        for (final c in [col, mirrorCol]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                c * cellW + 2,
                row * cellH + 2,
                cellW - 4,
                cellH - 4,
              ),
              const Radius.circular(3),
            ),
            Paint()..color = fg,
          );
        }
      }
    }
  }

  int _hash(String s) {
    int h = 0x811c9dc5;
    for (int i = 0; i < s.length; i++) {
      h ^= s.codeUnitAt(i);
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h;
  }

  Color _bgColor(int hash) {
    // Muted dark background — range of deep tones
    final hue = (hash & 0xFFFF) % 360;
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.35, 0.18).toColor();
  }

  Color _fgColor(int hash, Color bg) {
    // Foreground contrasts with background using offset hue
    final hue = ((hash >> 16) & 0xFFFF) % 360;
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.7, 0.62).toColor();
  }

  @override
  bool shouldRepaint(covariant _IdenticonPainter old) => old.seed != seed;
}
