import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav.dart';
import '../../models/pool_membership.dart';
import '../short_term_pack/short_term_hub_screen.dart';
import 'quiz_hub_screen.dart';

// ---------------------------------------------------------------------------
// RelationshipTypeScreen
//
// Entry point reached via a button on Home (not wired into Home yet by
// this file — see the TODO note at the bottom). Splits the full screen
// diagonally, bottom-left to top-right, into two triangular buttons:
//   - Short Term (bottom triangle)
//   - Long Term  (top triangle)
// Both have a glassy reflective sheen sweep animating across them.
//
// Tap Short Term  -> goes straight into the short-term quiz (single quiz).
// Tap Long Term   -> goes to QuizHubScreen, which lists the 5 long-term
//                    compatibility quizzes as separate buttons.
// ---------------------------------------------------------------------------

class RelationshipTypeScreen extends StatefulWidget {
  /// True when pushed on top of another screen (shows an X to pop back).
  /// False when used as a bottom-nav tab root, like Home — there's nothing
  /// to pop back to within the tab, so the close button is hidden and the
  /// BottomNav is shown instead.
  final bool showCloseButton;

  const RelationshipTypeScreen({super.key, this.showCloseButton = true});

  @override
  State<RelationshipTypeScreen> createState() => _RelationshipTypeScreenState();
}

class _RelationshipTypeScreenState extends State<RelationshipTypeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheenCtrl;
  final _membership = PoolMembershipStore.instance;

  @override
  void initState() {
    super.initState();
    _sheenCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _membership.addListener(_onMembershipChanged);
  }

  @override
  void dispose() {
    _sheenCtrl.dispose();
    _membership.removeListener(_onMembershipChanged);
    super.dispose();
  }

  void _onMembershipChanged() {
    if (mounted) setState(() {});
  }

  // ── Pool confirmation dialog ────────────────────────────────────────────

  Future<bool> _confirmJoin(BuildContext context, RelationshipPool pool) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => _PoolConfirmDialog(pool: pool),
    );
    return result == true;
  }

  // ── Navigation with join gate ──────────────────────────────────────────

  Future<void> _goShortTerm(BuildContext context) async {
    if (!_membership.isJoined(RelationshipPool.shortTerm)) {
      final joined = await _confirmJoin(context, RelationshipPool.shortTerm);
      if (!joined) return;
      _membership.join(RelationshipPool.shortTerm);
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShortTermHubScreen()),
    );
  }

  Future<void> _goLongTerm(BuildContext context) async {
    if (!_membership.isJoined(RelationshipPool.longTerm)) {
      final joined = await _confirmJoin(context, RelationshipPool.longTerm);
      if (!joined) return;
      _membership.join(RelationshipPool.longTerm);
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizHubScreen()),
    );
  }

  void _leavePool(RelationshipPool pool) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panelBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Leave ${pool.displayName} pool?',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'You won\'t be unpacked by other users in the ${pool.displayName} pool anymore. You can rejoin anytime.',
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.8),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _membership.leave(pool);
            },
            child: const Text(
              'Leave',
              style: TextStyle(
                color: Color(0xFFE05B5B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inShortTerm = _membership.inShortTerm;
    final inLongTerm = _membership.inLongTerm;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Long Term — upper-left triangle
          Positioned.fill(
            child: ClipPath(
              clipper: _DiagonalClipper(isTop: true),
              child: GestureDetector(
                onTap: () => _goLongTerm(context),
                child: AnimatedBuilder(
                  animation: _sheenCtrl,
                  builder: (context, _) => _GlassPanel(
                    label: 'LONG TERM',
                    subLabel: inLongTerm
                        ? 'In pool \u2014 tap to enter'
                        : 'Find something real',
                    baseColors: const [Color(0xFF0D1033), Color(0xFF112355)],
                    accentColor: AppColors.gold,
                    sheenT: _sheenCtrl.value,
                    icon: Icons.favorite_outline,
                    isTopTriangle: true,
                    inPool: inLongTerm,
                  ),
                ),
              ),
            ),
          ),

          // Short Term — lower-right triangle
          Positioned.fill(
            child: ClipPath(
              clipper: _DiagonalClipper(isTop: false),
              child: GestureDetector(
                onTap: () => _goShortTerm(context),
                child: AnimatedBuilder(
                  animation: _sheenCtrl,
                  builder: (context, _) => _GlassPanel(
                    label: 'SHORT TERM',
                    subLabel: inShortTerm
                        ? 'In pool \u2014 tap to enter'
                        : 'Tonight, no strings',
                    baseColors: const [Color(0xFF2D0A4E), Color(0xFF1A0630)],
                    accentColor: AppColors.purple,
                    sheenT: (_sheenCtrl.value + 0.5) % 1.0,
                    icon: Icons.bolt,
                    isTopTriangle: false,
                    inPool: inShortTerm,
                  ),
                ),
              ),
            ),
          ),

          // Diagonal divider line
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _DividerLinePainter()),
            ),
          ),

          // Close button (only when pushed on top of another screen)
          if (widget.showCloseButton)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
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

          // Leave-pool buttons — shown only when already a member.
          // Upper-left corner = Long Term leave button.
          // Lower-right corner = Short Term leave button.
          SafeArea(
            child: Stack(
              children: [
                if (inLongTerm)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _LeaveButton(
                      label: 'Leave Long Term',
                      onTap: () => _leavePool(RelationshipPool.longTerm),
                    ),
                  ),
                if (inShortTerm)
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: _LeaveButton(
                      label: 'Leave Short Term',
                      onTap: () => _leavePool(RelationshipPool.shortTerm),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }
}

/// Clips the screen into two triangles split by a line from the bottom-left
/// corner (0, h) to the top-right corner (w, 0).
/// isTop=true  -> the triangle ABOVE the line: top-left, top-right, bottom-right
/// isTop=false -> the triangle BELOW the line: top-left, bottom-left, bottom-right
class _DiagonalClipper extends CustomClipper<Path> {
  final bool isTop;
  _DiagonalClipper({required this.isTop});

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // The divider line runs from bottom-left (0, h) to top-right (w, 0).
    // That single diagonal only produces two triangles: upper-left and
    // lower-right — there is no literal "top-right triangle" possible
    // with this exact line, despite the panel being labelled that way.
    if (isTop) {
      // Upper-left triangle (touches top-left and bottom-left corners,
      // bounded by the top edge, left edge, and the diagonal).
      path.moveTo(0, 0);
      path.lineTo(w, 0);
      path.lineTo(0, h);
      path.close();
    } else {
      // Lower-right triangle (touches top-right and bottom-right corners,
      // bounded by the right edge, bottom edge, and the diagonal).
      path.moveTo(w, 0);
      path.lineTo(w, h);
      path.lineTo(0, h);
      path.close();
    }
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DividerLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.gold.withOpacity(0.0),
          AppColors.gold.withOpacity(0.9),
          AppColors.purple.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paint);

    // Soft glow along the line
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(ui.BlurStyle.normal, 6);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Glass reflective panel ──────────────────────────────────────────────

class _GlassPanel extends StatelessWidget {
  final String label;
  final String subLabel;
  final List<Color> baseColors;
  final Color accentColor;
  final double sheenT;
  final IconData icon;
  final bool isTopTriangle;
  final bool inPool;

  const _GlassPanel({
    required this.label,
    required this.subLabel,
    required this.baseColors,
    required this.accentColor,
    required this.sheenT,
    required this.icon,
    required this.isTopTriangle,
    this.inPool = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        const inset = 28.0;

        final anchorAlignment = isTopTriangle
            ? Alignment.topLeft
            : Alignment.bottomRight;
        final contentOffset = isTopTriangle
            ? const Offset(inset, inset)
            : Offset(-inset, -inset);

        // Cap label width so long text never reaches across to the diagonal
        // edge, regardless of viewport size.
        final maxLabelWidth = (w < h ? w : h) * 0.6;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: baseColors,
            ),
          ),
          child: Stack(
            children: [
              // Glass sheen sweep
              Positioned.fill(
                child: CustomPaint(
                  painter: _SheenPainter(t: sheenT, accent: accentColor),
                ),
              ),
              // Content, anchored at the triangle's right-angle corner.
              Align(
                alignment: anchorAlignment,
                child: Transform.translate(
                  offset: contentOffset,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxLabelWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: isTopTriangle
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        Icon(
                          icon,
                          color: accentColor.withOpacity(0.9),
                          size: 30,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          label,
                          textAlign: isTopTriangle
                              ? TextAlign.left
                              : TextAlign.right,
                          softWrap: true,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.5,
                            height: 1.15,
                            shadows: [
                              Shadow(
                                color: accentColor.withOpacity(0.5),
                                blurRadius: 14,
                              ),
                              const Shadow(
                                color: Colors.black54,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subLabel,
                          textAlign: isTopTriangle
                              ? TextAlign.left
                              : TextAlign.right,
                          softWrap: true,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                        ),
                        if (inPool) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF50C878),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'IN POOL',
                                style: TextStyle(
                                  color: Color(0xFF50C878),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheenPainter extends CustomPainter {
  final double t;
  final Color accent;
  _SheenPainter({required this.t, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final sweepWidth = size.width * 0.4;
    final travel = size.width + sweepWidth * 2;
    final x = -sweepWidth + t * travel;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.12),
          accent.withOpacity(0.08),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.3, 0.48, 0.55, 0.7],
      ).createShader(Rect.fromLTWH(x, 0, sweepWidth, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Faint top highlight to sell the "glass" feel
    final topHighlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.3));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.3),
      topHighlight,
    );
  }

  @override
  bool shouldRepaint(covariant _SheenPainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// TODO: wire this screen into Home.
// Add a button on HomeScreen, e.g.:
//   ElevatedButton(
//     onPressed: () => Navigator.push(context,
//       MaterialPageRoute(builder: (_) => const RelationshipTypeScreen())),
//     child: const Text('Take a quiz'),
//   )
// Not added automatically since Home's layout wasn't part of this request.
// ---------------------------------------------------------------------------

// ── Pool confirmation dialog ────────────────────────────────────────────────

class _PoolConfirmDialog extends StatelessWidget {
  final RelationshipPool pool;
  const _PoolConfirmDialog({required this.pool});

  @override
  Widget build(BuildContext context) {
    final isLong = pool == RelationshipPool.longTerm;
    final accentColor = isLong ? AppColors.gold : AppColors.purple;

    return Dialog(
      backgroundColor: AppColors.panelBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: accentColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(pool.emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Text(
              'Join ${pool.displayName}?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accentColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              pool.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.85),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: AppColors.textSecondary.withOpacity(0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Not Now',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Join',
                      style: TextStyle(
                        color: isLong ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Leave pool button ────────────────────────────────────────────────────────

class _LeaveButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LeaveButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.exit_to_app, color: Colors.white70, size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
