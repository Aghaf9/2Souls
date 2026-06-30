import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/bottom_nav.dart';
import '../theme/app_colors.dart';
import '../models/card_rarity_model.dart';
import '../models/profile_completion.dart';
import 'quiz/quiz_screen.dart';

// ---------------------------------------------------------------------------
// UserProfile model
// ---------------------------------------------------------------------------

class UserProfile {
  final String name;
  final int age;
  final double heightCm;
  final String location;
  final String countryFlagEmoji;
  final String bio;
  final String career;
  final String institution;
  final List<String> hobbies;
  final List<String> commonInterests;
  final String? photoUrl;

  // FIFA-style card attributes
  final int looks;
  final int intelligence;
  final int ambition;
  final int kindness;
  final int humor;

  // The 5 compatibility categories that drive rarity tier + wear.
  // Each is 0-100. 80+ in a category makes it "qualify" toward the tier.
  final Map<CompatCategory, int> compatScores;

  const UserProfile({
    required this.name,
    required this.age,
    required this.heightCm,
    required this.location,
    required this.countryFlagEmoji,
    required this.bio,
    required this.career,
    required this.institution,
    required this.hobbies,
    required this.commonInterests,
    this.photoUrl,
    required this.looks,
    required this.intelligence,
    required this.ambition,
    required this.kindness,
    required this.humor,
    required this.compatScores,
  });

  int get overall =>
      ((looks + intelligence + ambition + kindness + humor) / 5).round();

  String get firstName => name.split(' ').first;

  /// Overall compatibility = average of all 5 category scores.
  int get compatibilityOverall =>
      (compatScores.values.reduce((a, b) => a + b) / compatScores.length)
          .round();

  int scoreFor(CompatCategory c) => compatScores[c] ?? 0;

  UserProfile copyWith({
    String? bio,
    String? career,
    String? institution,
    String? location,
    String? photoUrl,
  }) {
    return UserProfile(
      name: name,
      age: age,
      heightCm: heightCm,
      location: location ?? this.location,
      countryFlagEmoji: countryFlagEmoji,
      bio: bio ?? this.bio,
      career: career ?? this.career,
      institution: institution ?? this.institution,
      hobbies: hobbies,
      commonInterests: commonInterests,
      photoUrl: photoUrl ?? this.photoUrl,
      looks: looks,
      intelligence: intelligence,
      ambition: ambition,
      kindness: kindness,
      humor: humor,
      compatScores: compatScores,
    );
  }
}

// ── Rarity tier visuals (colour + gradient per tier) ────────────────────────

extension RarityTierVisuals on RarityTier {
  Color get primaryColor {
    switch (this) {
      case RarityTier.none:
        return AppColors.bronze.withOpacity(0.6);
      case RarityTier.bronze:
        return AppColors.bronze;
      case RarityTier.silver:
        return AppColors.silver;
      case RarityTier.gold:
        return AppColors.gold;
      case RarityTier.platinum:
        return AppColors.platinum;
      case RarityTier.purple:
        return AppColors.rarityPurple;
    }
  }

  /// Base gradient for the tier, before wear-based darkening/brightening
  /// is applied (see wearAdjustedGradient). These are tinted with the
  /// tier's actual colour so the card body itself reads as that rarity,
  /// not just the border/glow.
  List<Color> get baseGradient {
    switch (this) {
      case RarityTier.none:
        return [const Color(0xFF3D2812), const Color(0xFF1F1408)];
      case RarityTier.bronze:
        return [const Color(0xFF8A5A2A), const Color(0xFF3D2410)];
      case RarityTier.silver:
        return [const Color(0xFF7E8C96), const Color(0xFF2A3138)];
      case RarityTier.gold:
        return [const Color(0xFF8A6A1E), const Color(0xFF3A2C0A)];
      case RarityTier.platinum:
        return [const Color(0xFFAEB8C2), const Color(0xFF3A4047)];
      case RarityTier.purple:
        return [const Color(0xFF6A1FB8), const Color(0xFF24073D)];
    }
  }
}

/// Adjusts a tier's base gradient according to wear sheen:
/// low sheen (Battle-Scarred) -> desaturated, muddy, flatter colour.
/// high sheen (Factory New)   -> richer, more saturated, deeper contrast,
/// mimicking a pristine CS:GO Factory New skin vs a scuffed one.
List<Color> wearAdjustedGradient(RarityTier tier, double sheen) {
  final base = tier.baseGradient;
  final top = base[0];
  final bottom = base[1];

  final topHsl = HSLColor.fromColor(top);
  final bottomHsl = HSLColor.fromColor(bottom);

  // Low sheen -> pull saturation down and lightness toward grey (worn look).
  // High sheen -> push saturation up and add lightness/contrast (pristine).
  final satBoost = (sheen - 0.5) * 0.35; // -0.175 .. +0.175
  final lightBoostTop = (sheen - 0.5) * 0.12; // top gets brighter when pristine
  final lightDropBottom = (1.0 - sheen) * 0.06; // bottom gets muddier when worn

  final adjustedTop = topHsl
      .withSaturation((topHsl.saturation + satBoost).clamp(0.0, 1.0))
      .withLightness((topHsl.lightness + lightBoostTop).clamp(0.0, 1.0))
      .toColor();

  final adjustedBottom = bottomHsl
      .withSaturation((bottomHsl.saturation + satBoost * 0.6).clamp(0.0, 1.0))
      .withLightness((bottomHsl.lightness - lightDropBottom).clamp(0.0, 1.0))
      .toColor();

  return [adjustedTop, adjustedBottom];
}

// ── Placeholder data ────────────────────────────────────────────────────────

const _defaultUser = UserProfile(
  name: 'Ali Ghaffari',
  age: 22,
  heightCm: 178,
  location: 'Brisbane, Australia',
  countryFlagEmoji: '🇦🇺',
  bio:
      'Computer Science student who loves deep conversations, adventures, '
      'and discovering new places. Looking for someone to build something '
      'meaningful with.',
  career: 'Computer Science Student',
  institution: 'University of Queensland',
  hobbies: ['Gym', 'Jiu-Jitsu', 'Space', 'Gaming', 'Reading', 'Coding'],
  commonInterests: ['Gym', 'Gaming', 'Space'],
  photoUrl: null,
  looks: 80,
  intelligence: 85,
  ambition: 88,
  kindness: 82,
  humor: 78,
  // Example: 3 categories qualify (>=80) -> GOLD tier.
  // Their average is (91 + 88 + 94) / 3 = 91 -> Field-Tested finish.
  compatScores: {
    CompatCategory.hobbies: 91,
    CompatCategory.careerEducation: 88,
    CompatCategory.looks: 65, // below 80, doesn't qualify
    CompatCategory.lifestyle: 94,
    CompatCategory.coreValues: 72, // below 80, doesn't qualify
  },
);

// ===========================================================================
// ProfileScreen
// ===========================================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  bool _expanded = false;

  // Mutable copy of the profile so the edit sheet can update it in place.
  // Seeded from _defaultUser; nothing is persisted to a backend yet — see
  // the TODO near _EditProfileSheet.
  late UserProfile _user;

  // Photo gallery — separate from UserProfile.photoUrl (which is the card's
  // main display photo). XFile.path works for both local file paths
  // (mobile/desktop) and blob URLs (web), so Image logic below branches on
  // kIsWeb to pick the right widget.
  final List<XFile> _galleryPhotos = [];

  late final AnimationController _cardCtrl;
  late final Animation<double> _cardScale;
  late final Animation<Alignment> _cardAlign;

  late final AnimationController _panelCtrl;
  late final Animation<double> _panelSlide;
  late final Animation<double> _panelFade;

  late final AnimationController _statCtrl;

  late final AnimationController _glowCtrl;
  late final Animation<double> _glowPulse;

  late final AnimationController _rotateCtrl;
  double _dragStartX = 0;
  double _rotationAtDragStart = 0;

  late final AnimationController _bgCtrl;

  // Continuous shine-sweep animation across the card, speed tied to wear.
  late final AnimationController _shineCtrl;

  late final CardRarityResult _rarity;

  final _completion = ProfileCompletionStore.instance;

  @override
  void initState() {
    super.initState();

    _user = _defaultUser;
    _rarity = CardRarityModel.compute(_user.compatScores);
    _completion.addListener(_onCompletionChanged);

    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardScale = Tween<double>(
      begin: 1.0,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeInOutCubic));
    _cardAlign = AlignmentTween(
      begin: Alignment.center,
      end: Alignment.topLeft,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeInOutCubic));

    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _panelSlide = CurvedAnimation(
      parent: _panelCtrl,
      curve: Curves.easeOutCubic,
    );
    _panelFade = CurvedAnimation(parent: _panelCtrl, curve: Curves.easeIn);

    _statCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _glowPulse = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOut));

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 0,
      lowerBound: -math.pi * 4,
      upperBound: math.pi * 4,
    );

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    // Higher wear sheen -> faster, more frequent shine sweep.
    final shineDurationMs = (3200 - (_rarity.sheenIntensity * 1800)).round();
    _shineCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: shineDurationMs),
    )..repeat();
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    _panelCtrl.dispose();
    _statCtrl.dispose();
    _glowCtrl.dispose();
    _rotateCtrl.dispose();
    _bgCtrl.dispose();
    _shineCtrl.dispose();
    _completion.removeListener(_onCompletionChanged);
    super.dispose();
  }

  void _onCompletionChanged() {
    if (mounted) setState(() {});
  }

  /// Fraction (0.0-1.0) of basic profile fields that are filled in:
  /// bio, career, institution, location, and at least one gallery photo.
  /// Used alongside quiz completion to compute the overall Hinge-style
  /// progress bar.
  double get _fieldCompletionFraction {
    int filled = 0;
    const totalFields = 5;
    if (_user.bio.trim().isNotEmpty) filled++;
    if (_user.career.trim().isNotEmpty) filled++;
    if (_user.institution.trim().isNotEmpty) filled++;
    if (_user.location.trim().isNotEmpty) filled++;
    if (_galleryPhotos.isNotEmpty) filled++;
    return filled / totalFields;
  }

  void _openCompletionChecklist() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CompletionChecklistSheet(
        user: _user,
        hasPhotos: _galleryPhotos.isNotEmpty,
        completion: _completion,
        onEditProfile: () {
          Navigator.of(sheetContext).pop();
          _openEditSheet();
        },
      ),
    );
  }

  Future<void> _expand() async {
    setState(() => _expanded = true);
    await _glowCtrl.forward();
    _glowCtrl.reverse();
    _cardCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _panelCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 120));
    _statCtrl.forward();
  }

  Future<void> _collapse() async {
    await _panelCtrl.reverse();
    _statCtrl.reset();
    await _cardCtrl.reverse();
    setState(() => _expanded = false);
  }

  void _onCardTap() {
    if (_expanded) {
      _collapse();
    } else {
      _expand();
    }
  }

  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        // StatefulBuilder lets the sheet's own controls (photo grid, text
        // fields) update live without rebuilding the whole ProfileScreen
        // until "Save" is pressed.
        return _EditProfileSheet(
          user: _user,
          galleryPhotos: _galleryPhotos,
          onPickPhoto: _pickPhoto,
          onRemovePhoto: _removePhoto,
          onSave: (updated) {
            setState(() => _user = updated);
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _galleryPhotos.add(picked));
    }
  }

  void _removePhoto(XFile photo) {
    setState(() => _galleryPhotos.remove(photo));
  }

  void _onDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _rotationAtDragStart = _rotateCtrl.value;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final dx = details.globalPosition.dx - _dragStartX;
    final newRotation = _rotationAtDragStart + (dx / 280) * 2 * math.pi;
    _rotateCtrl.value = newRotation.clamp(
      _rotateCtrl.lowerBound,
      _rotateCtrl.upperBound,
    );
  }

  void _onDragEnd(DragEndDetails details) {
    final current = _rotateCtrl.value;
    final nearest = (current / (2 * math.pi)).round() * (2 * math.pi);
    _rotateCtrl.animateTo(
      nearest,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final screenW = MediaQuery.of(context).size.width;
    final cardFullW = math.min(screenW * 0.42, 190.0);
    final cardSmallW = 118.0;
    final rc = AppColors.selfAccent;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(
              expanded: _expanded,
              onCollapse: _collapse,
              onEdit: _openEditSheet,
            ),
            Expanded(
              child: Stack(
                children: [
                  if (!_expanded)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _bgCtrl,
                        builder: (context, _) => CustomPaint(
                          painter: _AmbientBackgroundPainter(
                            t: _bgCtrl.value,
                            rarityColor: rc,
                          ),
                        ),
                      ),
                    ),

                  if (_expanded)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _panelSlide,
                        builder: (context, child) => FadeTransition(
                          opacity: _panelFade,
                          child: Transform.translate(
                            offset: Offset(30 * (1 - _panelSlide.value), 0),
                            child: child,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: cardSmallW + 12,
                            right: 14,
                            top: 12,
                            bottom: 24,
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                _AboutPanel(user: user),
                                _CareerPanel(user: user),
                                _HobbiesPanel(user: user),
                                _CompatibilityPanel(
                                  user: user,
                                  rarity: _rarity,
                                ),
                                _CommonPanel(user: user),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _cardCtrl,
                      _glowCtrl,
                      _rotateCtrl,
                    ]),
                    builder: (context, child) {
                      final align = _cardAlign.value;
                      final cardW =
                          cardFullW +
                          (cardSmallW - cardFullW) * _cardCtrl.value;

                      final rotY = _rotateCtrl.value;
                      final perspective = Matrix4.identity()
                        ..setEntry(3, 2, 0.0014)
                        ..rotateY(rotY);

                      return Align(
                        alignment: align,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: _expanded ? 14 : 0,
                            top: _expanded ? 12 : 0,
                          ),
                          child: GestureDetector(
                            onTap: _onCardTap,
                            onHorizontalDragStart: _onDragStart,
                            onHorizontalDragUpdate: _onDragUpdate,
                            onHorizontalDragEnd: _onDragEnd,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: perspective,
                              child: Transform.scale(
                                scale: _glowPulse.value,
                                child: SizedBox(
                                  width: cardW,
                                  child: _PlayerCard(
                                    user: user,
                                    rarity: _rarity,
                                    statProgress: _statCtrl,
                                    glowIntensity: _glowPulse.value - 1.0,
                                    shineProgress: _shineCtrl,
                                    isSelf: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  if (!_expanded)
                    Positioned(
                      bottom: 32,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.touch_app_outlined,
                                color: AppColors.gold.withOpacity(0.45),
                                size: 13,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'TAP TO EXPAND',
                                style: TextStyle(
                                  color: AppColors.gold.withOpacity(0.45),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.swipe_outlined,
                                color: AppColors.purple.withOpacity(0.4),
                                size: 13,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'DRAG TO SPIN',
                                style: TextStyle(
                                  color: AppColors.purple.withOpacity(0.4),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Profile completion square — moved here from Home.
                  // Disappears entirely once everything is done.
                  if (!_expanded && !_completion.allQuizzesComplete)
                    Positioned(
                      bottom: 20,
                      left: 16,
                      child: _CompletionSquare(
                        completedQuizzes: _completion.completedQuizzes.length,
                        totalQuizzes: ProfileCompletionStore.totalQuizzes,
                        progress: _completion.overallCompletion(
                          fieldCompletionFraction: _fieldCompletionFraction,
                        ),
                        onTap: _openCompletionChecklist,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 3),
    );
  }
}

// ── Ambient background painter ─────────────────────────────────────────────

class _AmbientBackgroundPainter extends CustomPainter {
  final double t;
  final Color rarityColor;

  _AmbientBackgroundPainter({required this.t, required this.rarityColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final angle = t * 2 * math.pi;

    final glow1Center =
        center + Offset(math.cos(angle) * 70, math.sin(angle) * 40);
    canvas.drawCircle(
      glow1Center,
      160,
      Paint()
        ..shader = RadialGradient(
          colors: [rarityColor.withOpacity(0.10), rarityColor.withOpacity(0.0)],
        ).createShader(Rect.fromCircle(center: glow1Center, radius: 160)),
    );

    final glow2Center =
        center +
        Offset(math.cos(angle + math.pi) * 90, math.sin(angle + math.pi) * 60);
    canvas.drawCircle(
      glow2Center,
      140,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.purple.withOpacity(0.06),
            AppColors.purple.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: glow2Center, radius: 140)),
    );

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        90.0 * i,
        Paint()
          ..color = rarityColor.withOpacity(0.035 / i)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1 + 2 * ((t + 0.0) % 1.0), -1),
        end: Alignment(-1 + 2 * ((t + 0.3) % 1.0), 1),
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.015),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _AmbientBackgroundPainter old) =>
      old.t != t || old.rarityColor != rarityColor;
}

// ── App bar ─────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final bool expanded;
  final VoidCallback onCollapse;
  final VoidCallback onEdit;
  const _AppBar({
    required this.expanded,
    required this.onCollapse,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        border: Border(bottom: BorderSide(color: Color(0x22B44CFF), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'PROFILE',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          Row(
            children: expanded
                ? [_IconBtn(icon: Icons.keyboard_arrow_down, onTap: onCollapse)]
                : [
                    _IconBtn(icon: Icons.edit_outlined, onTap: onEdit),
                    const SizedBox(width: 8),
                    _IconBtn(icon: Icons.settings_outlined, onTap: () {}),
                  ],
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.panelBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x33B44CFF)),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
    );
  }
}

// ===========================================================================
// Player Card — rarity tier + wear-driven finish
// ===========================================================================

class _PlayerCard extends StatelessWidget {
  final UserProfile user;
  final CardRarityResult rarity;
  final AnimationController statProgress;
  final double glowIntensity;
  final AnimationController shineProgress;

  /// True for the logged-in user's own card. A self-card is never a
  /// "match", so it uses a distinct identity colour (teal) instead of
  /// any rarity tier colour, and skips the wear/scratch overlay entirely.
  final bool isSelf;

  const _PlayerCard({
    required this.user,
    required this.rarity,
    required this.statProgress,
    required this.glowIntensity,
    required this.shineProgress,
    this.isSelf = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color rc = isSelf ? AppColors.selfAccent : rarity.tier.primaryColor;
    final sheen = isSelf ? 1.0 : rarity.sheenIntensity;
    final extraGlow = glowIntensity * 30;
    final gradient = isSelf
        ? const [Color(0xFF0F3D38), Color(0xFF06201D)]
        : wearAdjustedGradient(rarity.tier, sheen);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: Border.all(
          color: rc.withOpacity(0.55 + sheen * 0.35),
          width: 1.4,
        ),
        boxShadow: [
          // Base rarity glow, intensified by wear sheen (Factory New pops more)
          BoxShadow(
            color: rc.withOpacity((0.2 + sheen * 0.3) + glowIntensity * 0.5),
            blurRadius: 16 + sheen * 14 + extraGlow,
            spreadRadius: 1 + sheen * 3 + glowIntensity * 4,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            _Corner(color: rc, top: true, left: true),
            _Corner(color: rc, top: true, left: false),
            _Corner(color: rc, top: false, left: true),
            _Corner(color: rc, top: false, left: false),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 11, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isSelf ? _SelfBadge(color: rc) : _RarityBadge(rarity: rarity),
                  const SizedBox(height: 6),

                  AspectRatio(
                    aspectRatio: 1.05,
                    child: Stack(
                      children: [
                        _ProfilePhoto(
                          photoUrl: user.photoUrl,
                          initial: user.firstName[0],
                          rarityColor: rc,
                        ),
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${user.overall}',
                                style: TextStyle(
                                  color: rc,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 6),
                                  ],
                                ),
                              ),
                              Text(
                                'OVR',
                                style: TextStyle(
                                  color: rc,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 4),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 7),
                  Text(
                    user.firstName,
                    style: TextStyle(
                      color: rc,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Age ${user.age}',
                    style: TextStyle(
                      color: rc.withOpacity(0.7),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _GoldDivider(color: rc),
                  const SizedBox(height: 5),
                  _CardMeta(
                    icon: Icons.location_on,
                    label: user.location,
                    color: rc,
                  ),
                  const SizedBox(height: 2),
                  _CardMeta(
                    icon: Icons.work_outline,
                    label: user.career,
                    color: rc,
                  ),
                  const SizedBox(height: 7),
                  _GoldDivider(color: rc),
                  const SizedBox(height: 7),

                  _FifaStatGrid(user: user, rc: rc, progress: statProgress),
                ],
              ),
            ),

            // ── Wear overlay: scratches at low sheen, shine sweep at high ──
            // Skipped for the self card — wear describes match quality,
            // which doesn't apply to your own profile.
            if (!isSelf)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: shineProgress,
                  builder: (context, _) => CustomPaint(
                    size: Size.infinite,
                    painter: _WearOverlayPainter(
                      sheen: sheen,
                      shineT: shineProgress.value,
                      rarityColor: rc,
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

/// Paints the wear finish on top of the card:
/// - Low sheen (Battle-Scarred/Well-Worn): random scratch lines + dirt specks.
/// - High sheen (Minimal Wear/Factory New): a bright diagonal shine sweep.
class _WearOverlayPainter extends CustomPainter {
  final double sheen; // 0.0 (Battle-Scarred) -> 1.0 (Factory New)
  final double shineT; // 0-1 looping, drives the sweep position
  final Color rarityColor;

  _WearOverlayPainter({
    required this.sheen,
    required this.shineT,
    required this.rarityColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scratchOpacity = (1.0 - sheen).clamp(0.0, 1.0);

    // Scratches: more visible the lower the sheen.
    if (scratchOpacity > 0.05) {
      final rng = math.Random(7); // fixed seed -> stable scratch pattern
      final scratchPaint = Paint()
        ..color = Colors.black.withOpacity(0.25 * scratchOpacity)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;

      final scratchCount = (10 * scratchOpacity).round();
      for (int i = 0; i < scratchCount; i++) {
        final x1 = rng.nextDouble() * size.width;
        final y1 = rng.nextDouble() * size.height;
        final len = 8 + rng.nextDouble() * 22;
        final angle = rng.nextDouble() * math.pi;
        final x2 = x1 + math.cos(angle) * len;
        final y2 = y1 + math.sin(angle) * len;
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), scratchPaint);
      }

      // Dirt/dust specks
      final speckPaint = Paint()
        ..color = Colors.black.withOpacity(0.18 * scratchOpacity);
      final speckCount = (16 * scratchOpacity).round();
      for (int i = 0; i < speckCount; i++) {
        final x = rng.nextDouble() * size.width;
        final y = rng.nextDouble() * size.height;
        canvas.drawCircle(
          Offset(x, y),
          0.8 + rng.nextDouble() * 1.2,
          speckPaint,
        );
      }

      // Slight overall desaturating haze for very worn cards
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.black.withOpacity(0.06 * scratchOpacity),
      );
    }

    // Shine sweep: more visible / sharper the higher the sheen.
    if (sheen > 0.2) {
      final sweepWidth = size.width * 0.35;
      final travel = size.width + sweepWidth * 2;
      final sweepX = -sweepWidth + shineT * travel;

      final shinePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.05 + sheen * 0.22),
            Colors.white.withOpacity(0.0),
          ],
          stops: const [0.35, 0.5, 0.65],
        ).createShader(Rect.fromLTWH(sweepX, 0, sweepWidth, size.height));

      canvas.save();
      canvas.translate(0, 0);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), shinePaint);
      canvas.restore();

      // Crisp highlight edge for Factory New / Minimal Wear
      if (sheen > 0.7) {
        final edgePaint = Paint()
          ..color = Colors.white.withOpacity((sheen - 0.7) * 0.5)
          ..strokeWidth = 1.5;
        canvas.drawLine(
          Offset(sweepX + sweepWidth / 2, 0),
          Offset(sweepX + sweepWidth / 2, size.height),
          edgePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WearOverlayPainter old) =>
      old.shineT != shineT || old.sheen != sheen;
}

// ── FIFA stat grid ──────────────────────────────────────────────────────────

class _FifaStatGrid extends StatelessWidget {
  final UserProfile user;
  final Color rc;
  final AnimationController progress;

  const _FifaStatGrid({
    required this.user,
    required this.rc,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('LKS', user.looks),
      ('INT', user.intelligence),
      ('AMB', user.ambition),
      ('HUM', user.humor),
      ('KND', user.kindness),
      ('OVR', user.overall),
    ];

    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        return Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  _FifaStat(
                    label: stats[0].$1,
                    value: stats[0].$2,
                    rc: rc,
                    t: progress.value,
                  ),
                  const SizedBox(height: 4),
                  _FifaStat(
                    label: stats[1].$1,
                    value: stats[1].$2,
                    rc: rc,
                    t: progress.value,
                  ),
                  const SizedBox(height: 4),
                  _FifaStat(
                    label: stats[2].$1,
                    value: stats[2].$2,
                    rc: rc,
                    t: progress.value,
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    rc.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _FifaStat(
                    label: stats[3].$1,
                    value: stats[3].$2,
                    rc: rc,
                    t: progress.value,
                  ),
                  const SizedBox(height: 4),
                  _FifaStat(
                    label: stats[4].$1,
                    value: stats[4].$2,
                    rc: rc,
                    t: progress.value,
                  ),
                  const SizedBox(height: 4),
                  _FifaStat(
                    label: stats[5].$1,
                    value: stats[5].$2,
                    rc: rc,
                    t: progress.value,
                    highlight: true,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FifaStat extends StatelessWidget {
  final String label;
  final int value;
  final Color rc;
  final double t;
  final bool highlight;

  const _FifaStat({
    required this.label,
    required this.value,
    required this.rc,
    required this.t,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final animated = (value * t).round();
    final textColor = highlight ? rc : Colors.white;
    final labelColor = highlight ? rc.withOpacity(0.8) : rc.withOpacity(0.55);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$animated',
          style: TextStyle(
            color: textColor,
            fontSize: highlight ? 16 : 13,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: highlight ? 8 : 7,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

// ── Card sub-widgets ────────────────────────────────────────────────────────

class _SelfBadge extends StatelessWidget {
  final Color color;
  const _SelfBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        'YOU',
        style: TextStyle(
          color: color,
          fontSize: 7,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.5,
        ),
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  final CardRarityResult rarity;
  const _RarityBadge({required this.rarity});

  @override
  Widget build(BuildContext context) {
    final Color rc = rarity.tier.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: rc.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: rc.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rarity.tier.label,
            style: TextStyle(
              color: rc,
              fontSize: 7,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 4),
          Container(width: 1, height: 7, color: rc.withOpacity(0.3)),
          const SizedBox(width: 4),
          Text(
            rarity.wear.label,
            style: TextStyle(
              color: rc.withOpacity(0.75),
              fontSize: 6,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  final String? photoUrl;
  final String initial;
  final Color rarityColor;
  const _ProfilePhoto({
    required this.photoUrl,
    required this.initial,
    required this.rarityColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rarityColor.withOpacity(0.6), width: 1.6),
        boxShadow: [
          BoxShadow(color: rarityColor.withOpacity(0.25), blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: photoUrl != null
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) =>
                    _PhotoPlaceholder(initial: initial, color: rarityColor),
              )
            : _PhotoPlaceholder(initial: initial, color: rarityColor),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final String initial;
  final Color color;
  const _PhotoPlaceholder({required this.initial, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1A2A5C),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _GoldDivider extends StatelessWidget {
  final Color color;
  const _GoldDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            color.withOpacity(0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _CardMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _CardMeta({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color.withOpacity(0.65), size: 9),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _Corner extends StatelessWidget {
  final Color color;
  final bool top;
  final bool left;
  const _Corner({required this.color, required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: CustomPaint(
        size: const Size(14, 14),
        painter: _CornerPainter(color: color, top: top, left: left),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final bool top;
  final bool left;
  _CornerPainter({required this.color, required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final double ax = left ? 3 : size.width - 3;
    final double ay = top ? 3 : size.height - 3;
    final double bx = left ? size.width - 1 : 1;
    final double by = top ? size.height - 1 : 1;

    canvas.drawLine(Offset(ax, ay), Offset(bx, ay), p);
    canvas.drawLine(Offset(ax, ay), Offset(ax, by), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ===========================================================================
// Panels
// ===========================================================================

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? accentColor;

  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = accentColor ?? AppColors.gold;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.panelBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 13,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 7),
              Icon(icon, color: accent, size: 13),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ── Rarity info panel (new) — explains the tier + wear to the viewer ───────

class _RarityInfoPanel extends StatelessWidget {
  final UserProfile user;
  final CardRarityResult rarity;
  const _RarityInfoPanel({required this.user, required this.rarity});

  @override
  Widget build(BuildContext context) {
    final rc = rarity.tier.primaryColor;
    return _Panel(
      title: 'CARD RARITY',
      icon: Icons.diamond_outlined,
      accentColor: rc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: rc.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: rc.withOpacity(0.4)),
                ),
                child: Text(
                  rarity.tier.label,
                  style: TextStyle(
                    color: rc,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                rarity.wear.label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${rarity.qualifyingCategories.length} of 5 categories at 80%+ '
            '\u2022 avg ${rarity.wearAverage.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutPanel extends StatelessWidget {
  final UserProfile user;
  const _AboutPanel({required this.user});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'ABOUT ME',
      icon: Icons.auto_awesome,
      child: Text(
        user.bio,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          height: 1.6,
        ),
      ),
    );
  }
}

class _CareerPanel extends StatelessWidget {
  final UserProfile user;
  const _CareerPanel({required this.user});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'CAREER',
      icon: Icons.work_outline,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withOpacity(0.22)),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: AppColors.gold,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.career,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.institution,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HobbiesPanel extends StatelessWidget {
  final UserProfile user;
  const _HobbiesPanel({required this.user});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'HOBBIES',
      icon: Icons.theater_comedy_outlined,
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: user.hobbies.map((h) => _Chip(label: h)).toList(),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2748),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.panelBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Compatibility panel — now driven by the 5 real categories ─────────────

class _CompatibilityPanel extends StatelessWidget {
  final UserProfile user;
  final CardRarityResult rarity;
  const _CompatibilityPanel({required this.user, required this.rarity});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'COMPATIBILITY',
      icon: Icons.favorite,
      accentColor: AppColors.purple,
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: 86,
              height: 86,
              child: CustomPaint(
                painter: _RingPainter(value: user.compatibilityOverall / 100),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${user.compatibilityOverall}%',
                        style: const TextStyle(
                          color: AppColors.purple,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'MATCH',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _CompatBar(
            icon: Icons.sports_esports_outlined,
            label: 'Hobbies',
            value: user.scoreFor(CompatCategory.hobbies),
            color: const Color(0xFF3D74FF),
          ),
          const SizedBox(height: 8),
          _CompatBar(
            icon: Icons.work_outline,
            label: 'Career / Edu',
            value: user.scoreFor(CompatCategory.careerEducation),
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          _CompatBar(
            icon: Icons.face_outlined,
            label: 'Looks',
            value: user.scoreFor(CompatCategory.looks),
            color: AppColors.gold,
          ),
          const SizedBox(height: 8),
          _CompatBar(
            icon: Icons.fitness_center_outlined,
            label: 'Lifestyle',
            value: user.scoreFor(CompatCategory.lifestyle),
            color: AppColors.emerald,
          ),
          const SizedBox(height: 8),
          _CompatBar(
            icon: Icons.auto_awesome,
            label: 'Core Values',
            value: user.scoreFor(CompatCategory.coreValues),
            color: AppColors.purple,
          ),
        ],
      ),
    );
  }
}

class _CompatBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  const _CompatBar({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final qualifies = value >= CardRarityModel.kQualifyThreshold;
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.white.withOpacity(0.6)),
        const SizedBox(width: 5),
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 5,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 36,
          child: Row(
            children: [
              Text(
                '$value%',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (qualifies) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.star,
                  size: 9,
                  color: AppColors.gold.withOpacity(0.8),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  _RingPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = Colors.white.withOpacity(0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );

    final sweep = 2 * math.pi * value;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + sweep,
          colors: const [AppColors.purple, AppColors.purpleSoft],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _CommonPanel extends StatelessWidget {
  final UserProfile user;
  const _CommonPanel({required this.user});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'THINGS IN COMMON',
      icon: Icons.star_outline,
      accentColor: AppColors.gold,
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: user.commonInterests
            .map((item) => _GoldChip(label: item))
            .toList(),
      ),
    );
  }
}

class _GoldChip extends StatelessWidget {
  final String label;
  const _GoldChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: AppColors.gold.withOpacity(0.7), size: 9),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Edit Profile Sheet — photo upload + editable profile fields
// ===========================================================================
//
// Opened from the pencil icon in the app bar. Lets the user:
//   - Add/remove photos to their gallery (image_picker, gallery source).
//   - Edit bio, career, institution, and location as free text.
// "Save" applies the edited text fields back to the UserProfile via
// copyWith and closes the sheet. The photo gallery itself is held in
// ProfileScreen's state (_galleryPhotos) and updates immediately as
// photos are added/removed — it doesn't wait for "Save".
//
// TODO: persist both the gallery and edited fields to a real backend
// once one exists. Right now everything lives only in widget state and
// resets if the screen is rebuilt from scratch (e.g. app restart).
// ---------------------------------------------------------------------------

class _EditProfileSheet extends StatefulWidget {
  final UserProfile user;
  final List<XFile> galleryPhotos;
  final Future<void> Function() onPickPhoto;
  final void Function(XFile) onRemovePhoto;
  final void Function(UserProfile updated) onSave;

  const _EditProfileSheet({
    required this.user,
    required this.galleryPhotos,
    required this.onPickPhoto,
    required this.onRemovePhoto,
    required this.onSave,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _bioCtrl;
  late final TextEditingController _careerCtrl;
  late final TextEditingController _institutionCtrl;
  late final TextEditingController _locationCtrl;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _bioCtrl = TextEditingController(text: widget.user.bio);
    _careerCtrl = TextEditingController(text: widget.user.career);
    _institutionCtrl = TextEditingController(text: widget.user.institution);
    _locationCtrl = TextEditingController(text: widget.user.location);
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _careerCtrl.dispose();
    _institutionCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePickPhoto() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    await widget.onPickPhoto();
    if (mounted) setState(() => _isPicking = false);
  }

  void _handleSave() {
    final updated = widget.user.copyWith(
      bio: _bioCtrl.text.trim(),
      career: _careerCtrl.text.trim(),
      institution: _institutionCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
    );
    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: AppColors.panelBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'EDIT PROFILE',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SheetSectionLabel(label: 'PHOTOS'),
                    const SizedBox(height: 10),
                    _PhotoGrid(
                      photos: widget.galleryPhotos,
                      isPicking: _isPicking,
                      onAdd: _handlePickPhoto,
                      onRemove: widget.onRemovePhoto,
                    ),
                    const SizedBox(height: 22),
                    _SheetSectionLabel(label: 'ABOUT ME'),
                    const SizedBox(height: 8),
                    _EditField(
                      controller: _bioCtrl,
                      hint: 'Tell people about yourself',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 18),
                    _SheetSectionLabel(label: 'CAREER'),
                    const SizedBox(height: 8),
                    _EditField(
                      controller: _careerCtrl,
                      hint: 'Your occupation',
                    ),
                    const SizedBox(height: 10),
                    _EditField(
                      controller: _institutionCtrl,
                      hint: 'Company / institution',
                    ),
                    const SizedBox(height: 18),
                    _SheetSectionLabel(label: 'LOCATION'),
                    const SizedBox(height: 8),
                    _EditField(
                      controller: _locationCtrl,
                      hint: 'City, Country',
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
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
    );
  }
}

class _SheetSectionLabel extends StatelessWidget {
  final String label;
  const _SheetSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.gold,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _EditField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.5),
          fontSize: 13,
        ),
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.panelBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.panelBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.gold.withOpacity(0.7)),
        ),
      ),
    );
  }
}

// ── Photo grid: existing photos + an "Add" tile ────────────────────────────

class _PhotoGrid extends StatelessWidget {
  final List<XFile> photos;
  final bool isPicking;
  final VoidCallback onAdd;
  final void Function(XFile) onRemove;

  const _PhotoGrid({
    required this.photos,
    required this.isPicking,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: photos.length + 1, // +1 for the "Add" tile
      itemBuilder: (context, index) {
        if (index == photos.length) {
          return _AddPhotoTile(isPicking: isPicking, onTap: onAdd);
        }
        return _PhotoTile(
          photo: photos[index],
          onRemove: () => onRemove(photos[index]),
        );
      },
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final bool isPicking;
  final VoidCallback onTap;
  const _AddPhotoTile({required this.isPicking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPicking ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surfaceDark,
          border: Border.all(
            color: AppColors.gold.withOpacity(0.4),
            width: 1.4,
          ),
        ),
        child: Center(
          child: isPicking
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.gold.withOpacity(0.85),
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        color: AppColors.gold.withOpacity(0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final XFile photo;
  final VoidCallback onRemove;
  const _PhotoTile({required this.photo, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            // Reading bytes works identically across web, mobile, and
            // desktop (unlike dart:io File, which isn't usable on web).
            child: FutureBuilder<Uint8List>(
              future: photo.readAsBytes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    color: AppColors.surfaceDark,
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  );
                }
                return Image.memory(snapshot.data!, fit: BoxFit.cover);
              },
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Profile Completion — square box + checklist sheet
// ===========================================================================
//
// Moved here from the Home/Long Term quiz hub per request — this now lives
// entirely on the user's own Profile screen. Tapping the square opens a
// checklist sheet listing exactly what's left: profile fields (bio,
// career, etc, via the existing edit sheet) and each of the 5 Long Term
// quizzes, each with a real "Start"/"Done" button that actually opens
// that quiz (previously this button just navigated to /profile with
// nothing to complete there — that's fixed now since the quizzes
// themselves are reachable from this sheet).
// ---------------------------------------------------------------------------

class _CompletionSquare extends StatefulWidget {
  final int completedQuizzes;
  final int totalQuizzes;
  final double progress; // 0.0-1.0
  final VoidCallback onTap;

  const _CompletionSquare({
    required this.completedQuizzes,
    required this.totalQuizzes,
    required this.progress,
    required this.onTap,
  });

  @override
  State<_CompletionSquare> createState() => _CompletionSquareState();
}

class _CompletionSquareState extends State<_CompletionSquare>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _pressCtrl.forward();
    widget.onTap();
    if (mounted) _pressCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          alignment: Alignment.bottomLeft,
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          width: 110,
          height: 110,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // "Square with small edges" — minimal corner radius.
            borderRadius: BorderRadius.circular(10),
            color: AppColors.panelBg,
            border: Border.all(
              color: AppColors.purple.withOpacity(0.5),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HingeProgressBar(progress: widget.progress),
              const SizedBox(height: 8),
              Text(
                'COMPLETE',
                style: TextStyle(
                  color: AppColors.purple.withOpacity(0.9),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.completedQuizzes}/${widget.totalQuizzes} quizzes',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${(widget.progress * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hinge-style segmented progress bar — small rounded-pill segments
/// filling left to right, instead of one continuous bar.
class _HingeProgressBar extends StatelessWidget {
  final double progress;
  static const int segments = 8;

  const _HingeProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final filledSegments = (progress * segments).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(segments, (i) {
        final isFilled = i < filledSegments;
        return Padding(
          padding: EdgeInsets.only(right: i == segments - 1 ? 0 : 3),
          child: Container(
            width: 7,
            height: 5,
            decoration: BoxDecoration(
              color: isFilled
                  ? AppColors.purple
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

class _CompletionQuizInfo {
  final String title;
  final IconData icon;
  final Color color;

  const _CompletionQuizInfo({
    required this.title,
    required this.icon,
    required this.color,
  });
}

const _completionQuizzes = [
  _CompletionQuizInfo(
    title: 'Hobbies',
    icon: Icons.sports_esports_outlined,
    color: Color(0xFF3D74FF),
  ),
  _CompletionQuizInfo(
    title: 'Career & Education',
    icon: Icons.work_outline,
    color: AppColors.textSecondary,
  ),
  _CompletionQuizInfo(
    title: 'Looks',
    icon: Icons.face_outlined,
    color: AppColors.gold,
  ),
  _CompletionQuizInfo(
    title: 'Lifestyle',
    icon: Icons.fitness_center_outlined,
    color: AppColors.emerald,
  ),
  _CompletionQuizInfo(
    title: 'Core Values',
    icon: Icons.auto_awesome,
    color: AppColors.purple,
  ),
];

class _CompletionChecklistSheet extends StatefulWidget {
  final UserProfile user;
  final bool hasPhotos;
  final ProfileCompletionStore completion;
  final VoidCallback onEditProfile;

  const _CompletionChecklistSheet({
    required this.user,
    required this.hasPhotos,
    required this.completion,
    required this.onEditProfile,
  });

  @override
  State<_CompletionChecklistSheet> createState() =>
      _CompletionChecklistSheetState();
}

class _CompletionChecklistSheetState extends State<_CompletionChecklistSheet> {
  Future<void> _startQuiz(int index, _CompletionQuizInfo info) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            QuizScreen(tests: kCoreValuesQuizTests, title: info.title),
      ),
    );
    widget.completion.markQuizComplete(index);
    if (mounted) setState(() {});
  }

  bool get _bioDone => widget.user.bio.trim().isNotEmpty;
  bool get _careerDone => widget.user.career.trim().isNotEmpty;
  bool get _locationDone => widget.user.location.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.panelBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COMPLETE YOUR PROFILE',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PROFILE DETAILS',
                    style: TextStyle(
                      color: AppColors.purple,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ChecklistRow(
                    icon: Icons.edit_note,
                    label: 'Bio, career, location & photos',
                    color: AppColors.purple,
                    isDone:
                        _bioDone &&
                        _careerDone &&
                        _locationDone &&
                        widget.hasPhotos,
                    onTap: widget.onEditProfile,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'LONG TERM QUIZZES',
                    style: TextStyle(
                      color: AppColors.purple,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_completionQuizzes.length, (index) {
                    final info = _completionQuizzes[index];
                    final isDone = widget.completion.completedQuizzes.contains(
                      index,
                    );
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _completionQuizzes.length - 1 ? 0 : 10,
                      ),
                      child: _ChecklistRow(
                        icon: info.icon,
                        label: info.title,
                        color: info.color,
                        isDone: isDone,
                        onTap: () => _startQuiz(index, info),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDone;
  final VoidCallback onTap;

  const _ChecklistRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(isDone ? 0.5 : 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (isDone)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.emerald.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, color: AppColors.emerald, size: 12),
                    const SizedBox(width: 3),
                    Text(
                      'Done',
                      style: TextStyle(
                        color: AppColors.emerald.withOpacity(0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
