import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/card_rarity_model.dart';
import '../../models/match_pool.dart';
import '../../models/match_profile.dart';
import '../profile_screen.dart' show RarityTierVisuals, wearAdjustedGradient;

// ---------------------------------------------------------------------------
// SoulmateScreen (was TopMatchScreen)
//
// Limited to once per 7 days. Always reveals a Gold+ tier candidate
// (≥ 3 of 5 compat categories at 80+) with overall avg ≥ 80%.
// Tier colour and compatibility % are now consistent because both are
// derived from the same compatScores data.
//
// Reveal sequence (total ~3 seconds before card appears):
//   0.0s  — black screen, "OPEN SOULMATE" pulses in
//   0.6s  — background lights up (radial stadium glow + rays start)
//   1.2s  — "Finding your match..." text and spinning ring
//   2.2s  — suspense peak: screen darkens briefly
//   3.0s  — card slams in from below with scale overshoot + light burst
//   3.8s  — revealed state: compat breakdown + claim button slide up
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
  late List<TeaserFact> _facts;

  // Phase 1: suspense build (3 s)
  late final AnimationController _buildupCtrl;
  // Phase 2: card walkout (0.8 s)
  late final AnimationController _walkoutCtrl;
  late final Animation<double> _slideUp;
  late final Animation<double> _scalePop;
  // Continuous: rays + particles
  late final AnimationController _rayCtrl;
  late final AnimationController _particleCtrl;
  // One-shot: ring burst on landing
  late final AnimationController _pulseCtrl;

  bool _revealed = false;
  bool _cardVisible = false;

  double get _buildupT => _buildupCtrl.value;

  // Facts appear staggered at 0.18, 0.38, 0.56 of the 3s build
  bool _factVisible(int index) => _buildupT > 0.18 + index * 0.19;
  bool get _nicknameVisible => _buildupT > 0.76 && _winner.nickname != null;
  bool get _darkFlash => _buildupT > 0.72 && _buildupT < 0.82;
  double get _backgroundOpacity => (_buildupT * 2.5).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    final pool = MatchPool.buildPool(count: 40);
    _winner = MatchPool.drawSoulmate(pool);

    // Generate teaser facts comparing the placeholder user profile with
    // the winner. TODO: pass the real logged-in UserProfile in once we
    // have a shared state object — for now use placeholder values so the
    // teaser still animates meaningfully.
    _facts = SoulmateTeaser.generate(
      userHometown: 'Brisbane', // TODO: pull from UserProfile
      userCareer: 'Computer Science Student', // TODO: pull from UserProfile
      userLanguages: ['English'], // TODO: pull from UserProfile
      match:
          _winner.profile ??
          MatchProfile.blank(_winner.id, _winner.name, _winner.age),
    );

    _buildupCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _walkoutCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _rayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _slideUp = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _walkoutCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _scalePop =
        TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.22), weight: 55),
          TweenSequenceItem(tween: Tween(begin: 1.22, end: 1.0), weight: 45),
        ]).animate(
          CurvedAnimation(
            parent: _walkoutCtrl,
            curve: const Interval(0.0, 0.9),
          ),
        );

    _buildupCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _buildupCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _cardVisible = true);
        _walkoutCtrl.forward();
      }
    });
    _walkoutCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_revealed) {
        setState(() => _revealed = true);
        _pulseCtrl.forward();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _buildupCtrl.forward();
    });
  }

  @override
  void dispose() {
    _buildupCtrl.dispose();
    _walkoutCtrl.dispose();
    _rayCtrl.dispose();
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _claim() {
    widget.onWin(_winner);
    Navigator.of(context).pop(_winner);
  }

  @override
  Widget build(BuildContext context) {
    final rc = _winner.tier.primaryColor;
    final flashOpacity = _darkFlash
        ? (1.0 - (_buildupT - 0.72) / 0.10).clamp(0.0, 0.8)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Background (fades in during buildup) ──────────────────────
            Positioned.fill(
              child: Opacity(
                opacity: _backgroundOpacity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.15),
                      radius: 0.90,
                      colors: [
                        Color.lerp(Colors.black, rc, 0.32)!,
                        const Color(0xFF080808),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: _backgroundOpacity,
                child: AnimatedBuilder(
                  animation: _rayCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _RayBurstPainter(t: _rayCtrl.value, color: rc),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: _backgroundOpacity,
                  child: AnimatedBuilder(
                    animation: _particleCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _ParticlePainter(
                        t: _particleCtrl.value,
                        color: rc,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _RingPulsePainter(t: _pulseCtrl.value, color: rc),
                ),
              ),
            ),
            if (_cardVisible)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _walkoutCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _GroundGlowPainter(
                      t: _walkoutCtrl.value,
                      color: rc,
                    ),
                  ),
                ),
              ),
            if (flashOpacity > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(flashOpacity),
                    ),
                  ),
                ),
              ),

            // ── Teaser buildup sequence ─────────────────────────────────────
            if (!_cardVisible)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: _buildupT > 0.05 ? 1.0 : 0.0,
                        child: Text(
                          'OPEN SOULMATE',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 5,
                            shadows: [
                              Shadow(
                                color: AppColors.gold.withOpacity(0.8),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Fact 1, 2, 3 — slide/fade in staggered
                      ..._facts.asMap().entries.map((e) {
                        final i = e.key;
                        final fact = e.value;
                        return AnimatedOpacity(
                          duration: const Duration(milliseconds: 600),
                          opacity: _factVisible(i) ? 1.0 : 0.0,
                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            offset: _factVisible(i)
                                ? Offset.zero
                                : const Offset(0, 0.3),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: rc.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: rc.withOpacity(0.4),
                                      ),
                                    ),
                                    child: Icon(
                                      IconData(
                                        fact.iconCodePoint,
                                        fontFamily: 'MaterialIcons',
                                      ),
                                      color: rc,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      fact.text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      // If no facts, show a minimal connecting line
                      if (_facts.isEmpty && _buildupT > 0.2)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Text(
                            'Someone special is about to appear\u2026',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ),

                      // Nickname appears last, right before the flash
                      if (_nicknameVisible)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 400),
                          opacity: _nicknameVisible ? 1.0 : 0.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: rc.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: rc.withOpacity(0.5)),
                            ),
                            child: Text(
                              '"${_winner.nickname}"',
                              style: TextStyle(
                                color: rc,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                fontStyle: FontStyle.italic,
                                shadows: [
                                  Shadow(
                                    color: rc.withOpacity(0.6),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // ── Card walkout ───────────────────────────────────────────────
            if (_cardVisible)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _winner.name.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.4),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'OPEN SOULMATE',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color: AppColors.gold.withOpacity(0.6),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _walkoutCtrl,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, 260 * _slideUp.value),
                        child: Transform.scale(
                          scale: _scalePop.value,
                          child: child,
                        ),
                      ),
                      child: _SoulmateCard(
                        candidate: _winner,
                        glowing: !_revealed,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: _revealed ? 1.0 : 0.0,
                      child: _CompatBreakdown(candidate: _winner),
                    ),
                  ],
                ),
              ),

            // ── Close button ───────────────────────────────────────────────
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
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

            AnimatedPositioned(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              left: 24,
              right: 24,
              bottom: _revealed ? 24 : -100,
              child: ElevatedButton(
                onPressed: _revealed ? _claim : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: AppColors.gold.withOpacity(0.6),
                  elevation: 12,
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
          ],
        ),
      ),
    );
  }
}

// ── Compat breakdown — shows each category score after reveal ──────────────

class _CompatBreakdown extends StatelessWidget {
  final MatchCandidate candidate;
  const _CompatBreakdown({required this.candidate});

  static const _labels = {
    CompatCategory.hobbies: 'Hobbies',
    CompatCategory.careerEducation: 'Career',
    CompatCategory.looks: 'Looks',
    CompatCategory.lifestyle: 'Lifestyle',
    CompatCategory.coreValues: 'Values',
  };

  @override
  Widget build(BuildContext context) {
    final rc = candidate.tier.primaryColor;
    final scores = candidate.compatScores;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rc.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '${candidate.compatibility}% Overall',
            style: TextStyle(
              color: rc,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...CompatCategory.values.map((cat) {
            final score = scores[cat] ?? 0;
            final qualifies = score >= CardRarityModel.kQualifyThreshold;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      _labels[cat]!,
                      style: TextStyle(
                        color: qualifies
                            ? rc
                            : AppColors.textSecondary.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: score / 100,
                        minHeight: 5,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          qualifies
                              ? rc
                              : AppColors.textSecondary.withOpacity(0.35),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$score',
                    style: TextStyle(
                      color: qualifies
                          ? rc
                          : AppColors.textSecondary.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Soulmate card visual ─────────────────────────────────────────────────────

class _SoulmateCard extends StatelessWidget {
  final MatchCandidate candidate;
  final bool glowing;
  const _SoulmateCard({required this.candidate, required this.glowing});

  @override
  Widget build(BuildContext context) {
    final rc = candidate.tier.primaryColor;
    final sheen = candidate.wear.sheenIntensity;
    final gradient = wearAdjustedGradient(candidate.tier, sheen);

    return Container(
      width: 210,
      padding: const EdgeInsets.all(16),
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
            color: AppColors.gold.withOpacity(glowing ? 0.8 : 0.45),
            blurRadius: glowing ? 56 : 28,
            spreadRadius: glowing ? 8 : 2,
          ),
          if (glowing)
            BoxShadow(
              color: rc.withOpacity(0.35),
              blurRadius: 90,
              spreadRadius: 12,
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withOpacity(0.6)),
                ),
                child: const Text(
                  'SOULMATE',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: rc.withOpacity(0.7), width: 1.8),
                color: rc.withOpacity(0.08),
              ),
              child: Center(child: Icon(Icons.person, color: rc, size: 44)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${candidate.name}, ${candidate.age}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            candidate.location,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.8),
              fontSize: 10,
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

// ── Background painters ─────────────────────────────────────────────────────

class _RayBurstPainter extends CustomPainter {
  final double t;
  final Color color;
  _RayBurstPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    const rayCount = 24;
    final angleOffset = t * 2 * math.pi;
    final length = size.width * 1.1;

    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 2 * math.pi + angleOffset;
      final isWide = i % 2 == 0;
      final p2 = Offset(
        center.dx + length * math.cos(angle),
        center.dy + length * math.sin(angle),
      );
      canvas.drawLine(
        center,
        p2,
        Paint()
          ..shader = LinearGradient(
            colors: [
              color.withOpacity(isWide ? 0.25 : 0.10),
              color.withOpacity(0),
            ],
          ).createShader(Rect.fromPoints(center, p2))
          ..strokeWidth = isWide ? 44 : 16
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RayBurstPainter old) => old.t != t;
}

class _RingPulsePainter extends CustomPainter {
  final double t;
  final Color color;
  _RingPulsePainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final center = Offset(size.width / 2, size.height * 0.42);
    final maxRadius = size.width * 0.8;
    final radius = maxRadius * Curves.easeOut.transform(t);
    final opacity = (1.0 - t).clamp(0.0, 1.0);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withOpacity(opacity * 0.6)
        ..strokeWidth = 3 + (1 - t) * 8
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withOpacity(opacity * 0.22)
        ..strokeWidth = 28
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPulsePainter old) => old.t != t;
}

class _GroundGlowPainter extends CustomPainter {
  final double t;
  final Color color;
  _GroundGlowPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = Curves.easeIn.transform(t.clamp(0.0, 1.0)) * 0.45;
    if (opacity < 0.01) return;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.83),
      width: size.width * 0.85,
      height: size.height * 0.08,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withOpacity(opacity), color.withOpacity(0)],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
  }

  @override
  bool shouldRepaint(covariant _GroundGlowPainter old) => old.t != t;
}

class _ParticlePainter extends CustomPainter {
  final double t;
  final Color color;
  _ParticlePainter({required this.t, required this.color});

  static final List<_Particle> _particles = _build();
  static List<_Particle> _build() {
    final rng = math.Random(31);
    return List.generate(
      32,
      (i) => _Particle(
        x: rng.nextDouble(),
        baseY: 0.3 + rng.nextDouble() * 0.6,
        speed: 0.12 + rng.nextDouble() * 0.3,
        size: 1.5 + rng.nextDouble() * 3.5,
        phase: rng.nextDouble(),
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final lt = ((t + p.phase) % 1.0);
      final y = (p.baseY - lt * p.speed) * size.height;
      if (y < 0 || y > size.height) continue;
      final opacity = (math.sin(lt * math.pi)).clamp(0.0, 1.0) * 0.7;
      canvas.drawCircle(
        Offset(p.x * size.width, y),
        p.size,
        Paint()..color = color.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}

class _Particle {
  final double x, baseY, speed, size, phase;
  const _Particle({
    required this.x,
    required this.baseY,
    required this.speed,
    required this.size,
    required this.phase,
  });
}
