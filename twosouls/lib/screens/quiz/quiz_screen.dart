import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

// ---------------------------------------------------------------------------
// QuizScreen
//
// A generic quiz runner used by both the Short Term and Long Term flows.
// This build is DISPLAY ONLY: tapping an option visually responds (the
// charcoal-zap elimination animation, the selection highlight) but nothing
// is recorded, computed, or persisted anywhere. Scoring logic comes later
// once the math is decided — see the TODO at the bottom of this file.
//
// Test types built so far:
//   1. ImageEliminationTest — show 6 options; tap the one you like. The
//      OTHER 5 turn to charcoal/ash and crumble away. The winner (the one
//      you tapped) animates by flying down into the bottom progress bar,
//      visually growing it, before the quiz advances to the next test.
//   2. NumberPickerTest — pick a number from a row of options (e.g. how
//      many kids, 0 to 5+).
//
// Add new test types by extending QuizTest and adding a case in
// _QuizTestView's switch.
// ---------------------------------------------------------------------------

abstract class QuizTest {
  String get question;
  String get subtitle;
}

class ImageEliminationTest extends QuizTest {
  @override
  final String question;
  @override
  final String subtitle;
  final List<QuizImageOption> options;

  ImageEliminationTest({
    required this.question,
    required this.subtitle,
    required this.options,
  });
}

class QuizImageOption {
  final String id;
  final String label;
  final IconData icon; // placeholder visual until real photography exists
  final Color tint;

  const QuizImageOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.tint,
  });
}

class NumberPickerTest extends QuizTest {
  @override
  final String question;
  @override
  final String subtitle;
  final int minValue;
  final int maxValue;
  final bool plusOnLast; // shows "5+" instead of "5" on the final option

  NumberPickerTest({
    required this.question,
    required this.subtitle,
    required this.minValue,
    required this.maxValue,
    this.plusOnLast = false,
  });
}

// ── Long Term: core values quiz content (placeholder, display only) ────────

final List<QuizTest> kCoreValuesQuizTests = [
  ImageEliminationTest(
    question: 'Which of these could you see yourself living in?',
    subtitle: 'Tap the one you like \u2014 the rest will turn to ash.',
    options: const [
      QuizImageOption(
        id: 'dark_apartment',
        label: 'Dark Apartment',
        icon: Icons.apartment,
        tint: Color(0xFF37474F),
      ),
      QuizImageOption(
        id: 'quiet_neighbourhood',
        label: 'Quiet Neighbourhood',
        icon: Icons.holiday_village,
        tint: Color(0xFF558B2F),
      ),
      QuizImageOption(
        id: 'bustling_city',
        label: 'Bustling City',
        icon: Icons.location_city,
        tint: Color(0xFF5C6BC0),
      ),
      QuizImageOption(
        id: 'countryside_farm',
        label: 'Countryside Farm',
        icon: Icons.agriculture,
        tint: Color(0xFF8D6E63),
      ),
      QuizImageOption(
        id: 'beachfront',
        label: 'Beachfront',
        icon: Icons.beach_access,
        tint: Color(0xFF26A69A),
      ),
      QuizImageOption(
        id: 'mountain_cabin',
        label: 'Mountain Cabin',
        icon: Icons.cabin,
        tint: Color(0xFF6D4C41),
      ),
    ],
  ),
  NumberPickerTest(
    question: 'How many kids do you want?',
    subtitle: 'Pick the number that feels right for your future.',
    minValue: 0,
    maxValue: 5,
    plusOnLast: true,
  ),
  ImageEliminationTest(
    question: 'Which of these sound like your kind of weekend?',
    subtitle: 'Tap the one you like \u2014 the rest will turn to ash.',
    options: const [
      QuizImageOption(
        id: 'gym_session',
        label: 'Gym Session',
        icon: Icons.fitness_center,
        tint: Color(0xFFEF6C00),
      ),
      QuizImageOption(
        id: 'reading_at_home',
        label: 'Reading at Home',
        icon: Icons.menu_book,
        tint: Color(0xFF5E35B1),
      ),
      QuizImageOption(
        id: 'night_out',
        label: 'Night Out',
        icon: Icons.nightlife,
        tint: Color(0xFFD81B60),
      ),
      QuizImageOption(
        id: 'hiking_trip',
        label: 'Hiking Trip',
        icon: Icons.terrain,
        tint: Color(0xFF43A047),
      ),
      QuizImageOption(
        id: 'family_gathering',
        label: 'Family Gathering',
        icon: Icons.groups,
        tint: Color(0xFF00897B),
      ),
      QuizImageOption(
        id: 'gaming_marathon',
        label: 'Gaming Marathon',
        icon: Icons.sports_esports,
        tint: Color(0xFF3949AB),
      ),
    ],
  ),
  ImageEliminationTest(
    question: 'Which ethnic background do you feel most drawn to in a partner?',
    subtitle:
        'Tap the one you\u2019re most open to \u2014 purely a preference signal, not a filter.',
    options: const [
      QuizImageOption(
        id: 'ethnicity_no_pref',
        label: 'No Preference',
        icon: Icons.public,
        tint: Color(0xFF546E7A),
      ),
      QuizImageOption(
        id: 'ethnicity_asian',
        label: 'Asian',
        icon: Icons.person_outline,
        tint: Color(0xFFD32F2F),
      ),
      QuizImageOption(
        id: 'ethnicity_black',
        label: 'Black',
        icon: Icons.person_outline,
        tint: Color(0xFF6D4C41),
      ),
      QuizImageOption(
        id: 'ethnicity_latino',
        label: 'Latino / Hispanic',
        icon: Icons.person_outline,
        tint: Color(0xFFF9A825),
      ),
      QuizImageOption(
        id: 'ethnicity_middle_eastern',
        label: 'Middle Eastern',
        icon: Icons.person_outline,
        tint: Color(0xFF00897B),
      ),
      QuizImageOption(
        id: 'ethnicity_white',
        label: 'White / Caucasian',
        icon: Icons.person_outline,
        tint: Color(0xFF5C6BC0),
      ),
    ],
  ),
];

// ── Short Term: hookup / one-night logistics quiz content ──────────────────

final List<QuizTest> kShortTermQuizTests = [
  ImageEliminationTest(
    question: 'Where would you want to meet up?',
    subtitle: 'Tap your pick \u2014 the rest will turn to ash.',
    options: const [
      QuizImageOption(
        id: 'bar',
        label: 'Bar',
        icon: Icons.local_bar,
        tint: Color(0xFF8E24AA),
      ),
      QuizImageOption(
        id: 'my_place',
        label: 'My Place',
        icon: Icons.home,
        tint: Color(0xFFD81B60),
      ),
      QuizImageOption(
        id: 'park',
        label: 'Park',
        icon: Icons.park,
        tint: Color(0xFF43A047),
      ),
      QuizImageOption(
        id: 'hotel',
        label: 'Hotel',
        icon: Icons.hotel,
        tint: Color(0xFF5C6BC0),
      ),
      QuizImageOption(
        id: 'club',
        label: 'Club',
        icon: Icons.nightlife,
        tint: Color(0xFFE53935),
      ),
      QuizImageOption(
        id: 'their_place',
        label: 'Their Place',
        icon: Icons.door_front_door,
        tint: Color(0xFF6D4C41),
      ),
    ],
  ),
  ImageEliminationTest(
    question: 'What time of night works best?',
    subtitle: 'Tap your pick \u2014 the rest will turn to ash.',
    options: const [
      QuizImageOption(
        id: 'after_dinner',
        label: 'After Dinner',
        icon: Icons.dinner_dining,
        tint: Color(0xFFEF6C00),
      ),
      QuizImageOption(
        id: 'late_night',
        label: 'Late Night',
        icon: Icons.nightlight_round,
        tint: Color(0xFF3949AB),
      ),
      QuizImageOption(
        id: 'spontaneous',
        label: 'Whenever, Spontaneous',
        icon: Icons.bolt,
        tint: Color(0xFFD81B60),
      ),
      QuizImageOption(
        id: 'weekend_only',
        label: 'Weekends Only',
        icon: Icons.weekend,
        tint: Color(0xFF00897B),
      ),
      QuizImageOption(
        id: 'after_work',
        label: 'Right After Work',
        icon: Icons.work_outline,
        tint: Color(0xFF546E7A),
      ),
      QuizImageOption(
        id: 'early_morning',
        label: 'Early Morning',
        icon: Icons.wb_twighlight,
        tint: Color(0xFF8D6E63),
      ),
    ],
  ),
  ImageEliminationTest(
    question: 'What\u2019s your vibe for the night?',
    subtitle: 'Tap your pick \u2014 the rest will turn to ash.',
    options: const [
      QuizImageOption(
        id: 'low_key',
        label: 'Low Key',
        icon: Icons.nightlight,
        tint: Color(0xFF5E35B1),
      ),
      QuizImageOption(
        id: 'wild',
        label: 'Wild & Fun',
        icon: Icons.celebration,
        tint: Color(0xFFE53935),
      ),
      QuizImageOption(
        id: 'drinks_first',
        label: 'Drinks First',
        icon: Icons.wine_bar,
        tint: Color(0xFF8E24AA),
      ),
      QuizImageOption(
        id: 'straight_to_it',
        label: 'Straight To It',
        icon: Icons.bolt,
        tint: Color(0xFFD81B60),
      ),
      QuizImageOption(
        id: 'slow_build',
        label: 'Slow Build',
        icon: Icons.favorite_border,
        tint: Color(0xFF00897B),
      ),
      QuizImageOption(
        id: 'no_talking',
        label: 'Minimal Talking',
        icon: Icons.do_not_disturb_on,
        tint: Color(0xFF546E7A),
      ),
    ],
  ),
];

// ===========================================================================
// QuizScreen
// ===========================================================================

class QuizScreen extends StatefulWidget {
  final List<QuizTest> tests;
  final String title;

  QuizScreen({super.key, List<QuizTest>? tests, this.title = 'Quiz'})
    : tests = tests ?? kCoreValuesQuizTests;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentIndex < widget.tests.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _showCompletion();
    }
  }

  void _showCompletion() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _CompletionDialog(
        onClose: () {
          Navigator.of(context).pop(); // close dialog
          Navigator.of(context).pop(); // leave quiz
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _QuizHeader(
              title: widget.title,
              currentIndex: _currentIndex,
              total: widget.tests.length,
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // forward-only via taps
                itemCount: widget.tests.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, index) {
                  return _QuizTestView(
                    test: widget.tests[index],
                    onAnswered: _goNext,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header: title + progress bar + close button ─────────────────────────

class _QuizHeader extends StatelessWidget {
  final String title;
  final int currentIndex;
  final int total;
  final VoidCallback onClose;

  const _QuizHeader({
    required this.title,
    required this.currentIndex,
    required this.total,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
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
              const SizedBox(width: 10),
              Expanded(
                child: _AnimatedProgressBar(
                  currentIndex: currentIndex,
                  total: total,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${currentIndex + 1}/$total',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Progress bar whose filled segments grow in with a little overshoot bounce
/// each time a new segment completes, selling the "winner adds into the bar"
/// moment.
class _AnimatedProgressBar extends StatelessWidget {
  final int currentIndex;
  final int total;

  const _AnimatedProgressBar({required this.currentIndex, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isDone = i <= currentIndex;
        return Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: isDone ? 1 : 0),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            builder: (context, t, _) {
              return Container(
                height: 5,
                margin: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: t.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.purple,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withOpacity(0.6 * t),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

// ── Routes a test to its display widget ─────────────────────────────────

class _QuizTestView extends StatelessWidget {
  final QuizTest test;
  final VoidCallback onAnswered;

  const _QuizTestView({required this.test, required this.onAnswered});

  @override
  Widget build(BuildContext context) {
    if (test is ImageEliminationTest) {
      return _ImageEliminationView(
        test: test as ImageEliminationTest,
        onAnswered: onAnswered,
      );
    }
    if (test is NumberPickerTest) {
      return _NumberPickerView(
        test: test as NumberPickerTest,
        onAnswered: onAnswered,
      );
    }
    return const SizedBox.shrink();
  }
}

// ===========================================================================
// Test 1: Image Elimination — pick one, the rest turn to ash
// ===========================================================================

class _ImageEliminationView extends StatefulWidget {
  final ImageEliminationTest test;
  final VoidCallback onAnswered;

  const _ImageEliminationView({required this.test, required this.onAnswered});

  @override
  State<_ImageEliminationView> createState() => _ImageEliminationViewState();
}

class _ImageEliminationViewState extends State<_ImageEliminationView> {
  String? _winnerId;
  bool _ashing = false; // losers are mid charcoal-crumble animation

  void _onTap(String id) {
    if (_winnerId != null) return; // already answered
    setState(() {
      _winnerId = id;
      _ashing = true;
    });

    // Let the ash-crumble play out on the losers, then advance.
    Future.delayed(const Duration(milliseconds: 850), () {
      if (mounted) widget.onAnswered();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.test.question,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.test.subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Compute tile height from the ACTUAL space available,
                // rather than a fixed aspect ratio. A fixed ratio (e.g.
                // 1.05) made tiles overflow or shrink unpredictably
                // depending on how much vertical space the question text
                // above took up on different screen sizes — this is what
                // made the grid look like it "didn't fit" or had oddly
                // shaped, disconnected tiles. Computing the exact height
                // for 3 rows of 2 columns guarantees all 6 tiles always
                // fit within the available space, edge to edge, on any
                // screen.
                const crossAxisCount = 2;
                const spacing = 10.0;
                final rows = (widget.test.options.length / crossAxisCount)
                    .ceil();
                final tileWidth =
                    (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                    crossAxisCount;
                final tileHeight =
                    (constraints.maxHeight - spacing * (rows - 1)) / rows;

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    // mainAxisExtent (not childAspectRatio) pins the exact
                    // pixel height per row, so the whole grid always sums
                    // to exactly constraints.maxHeight — no overflow, no
                    // odd shapes, no clipping.
                    mainAxisExtent: tileHeight,
                  ),
                  itemCount: widget.test.options.length,
                  itemBuilder: (context, index) {
                    final option = widget.test.options[index];
                    final isWinner = _winnerId == option.id;
                    final isLoser = _winnerId != null && !isWinner;

                    return _EliminationTile(
                      option: option,
                      isWinner: isWinner,
                      isLoser: isLoser,
                      ashing: _ashing,
                      onTap: () => _onTap(option.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EliminationTile extends StatefulWidget {
  final QuizImageOption option;
  final bool isWinner;
  final bool isLoser;
  final bool ashing;
  final VoidCallback onTap;

  const _EliminationTile({
    required this.option,
    required this.isWinner,
    required this.isLoser,
    required this.ashing,
    required this.onTap,
  });

  @override
  State<_EliminationTile> createState() => _EliminationTileState();
}

class _EliminationTileState extends State<_EliminationTile> {
  @override
  Widget build(BuildContext context) {
    // CRITICAL: the tile's box must fill its entire grid cell edge-to-edge
    // (SizedBox.expand) so all 6 tiles sit flush against each other with
    // no invisible gaps — gaps were the actual cause of tiles looking
    // "disconnected" and "randomly placed". The Center+ClipRect approach
    // previously used let the AnimatedContainer shrink to wrap only its
    // icon+text content, leaving large empty margins inside each grid
    // cell. Transform.scale (paint-only, doesn't affect layout bounds) is
    // used for the winner/loser pulse instead of AnimatedScale, so the
    // visual pop never changes the cell's actual occupied space.
    return GestureDetector(
      onTap: widget.isWinner || widget.isLoser ? null : widget.onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(
          begin: 1.0,
          end: widget.isWinner ? 1.06 : (widget.isLoser ? 0.94 : 1.0),
        ),
        duration: const Duration(milliseconds: 400),
        curve: widget.isWinner ? Curves.easeOutBack : Curves.easeIn,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: SizedBox.expand(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Base tile — desaturates and darkens toward charcoal when it loses.
              AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: widget.isLoser
                      ? const Color(0xFF1A1A1A)
                      : widget.option.tint.withOpacity(
                          widget.isWinner ? 0.5 : 0.22,
                        ),
                  border: Border.all(
                    color: widget.isWinner
                        ? AppColors.gold
                        : (widget.isLoser
                              ? const Color(0xFF2A2A2A)
                              : widget.option.tint.withOpacity(0.5)),
                    width: widget.isWinner ? 2.6 : 1.2,
                  ),
                  boxShadow: widget.isWinner
                      ? [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.55),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 750),
                  curve: Curves.easeIn,
                  opacity: widget.isLoser ? 0.0 : 1.0,
                  child: ColorFiltered(
                    colorFilter: widget.isLoser
                        ? const ColorFilter.matrix(<double>[
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ]) // greyscale, the first step toward "charcoal"
                        : const ColorFilter.matrix(<double>[
                            1,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ]),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.option.icon,
                          color: Colors.white.withOpacity(0.92),
                          size: 38,
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            widget.option.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Ash/ember particles drifting up off losing tiles as they crumble.
              if (widget.isLoser && widget.ashing)
                Positioned.fill(child: IgnorePointer(child: _AshParticles())),

              // Gold "winner" check mark
              if (widget.isWinner)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.6),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.black,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Drifting ash/ember specks animated upward and fading out, layered over a
/// losing tile to sell the "turning to ash and crumbling away" effect.
class _AshParticles extends StatefulWidget {
  @override
  State<_AshParticles> createState() => _AshParticlesState();
}

class _AshParticlesState extends State<_AshParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward();

    final rng = _seededRandom(
      DateTime.now().microsecondsSinceEpoch & 0x7fffffff,
    );
    _particles = List.generate(14, (i) {
      return _Particle(
        startX: rng(),
        startY: 0.4 + rng() * 0.5,
        driftX: (rng() - 0.5) * 0.3,
        size: 2 + rng() * 3,
        delay: rng() * 0.3,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlePainter(particles: _particles, t: _ctrl.value),
        );
      },
    );
  }
}

class _Particle {
  final double startX;
  final double startY;
  final double driftX;
  final double size;
  final double delay;

  _Particle({
    required this.startX,
    required this.startY,
    required this.driftX,
    required this.size,
    required this.delay,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;

  _ParticlePainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final localT = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (localT <= 0) continue;

      final x = (p.startX + p.driftX * localT) * size.width;
      final y = (p.startY - localT * 0.6) * size.height;
      final opacity = (1.0 - localT);

      canvas.drawCircle(
        Offset(x, y),
        p.size * (1.0 - localT * 0.4),
        Paint()..color = const Color(0xFF3A3A3A).withOpacity(opacity * 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}

double Function() _seededRandom(int seed) {
  int state = seed == 0 ? 1 : seed;
  return () {
    state = (state * 1103515245 + 12345) & 0x7fffffff;
    return (state % 1000) / 1000.0;
  };
}

// ===========================================================================
// Test 2: Number Picker
// ===========================================================================

class _NumberPickerView extends StatefulWidget {
  final NumberPickerTest test;
  final VoidCallback onAnswered;

  const _NumberPickerView({required this.test, required this.onAnswered});

  @override
  State<_NumberPickerView> createState() => _NumberPickerViewState();
}

class _NumberPickerViewState extends State<_NumberPickerView> {
  int? _selected;

  void _onTap(int value) {
    if (_selected != null) return;
    setState(() => _selected = value);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) widget.onAnswered();
    });
  }

  @override
  Widget build(BuildContext context) {
    final values = List.generate(
      widget.test.maxValue - widget.test.minValue + 1,
      (i) => widget.test.minValue + i,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.test.question,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.test.subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: values.map((v) {
                final isLast = v == widget.test.maxValue;
                final label = (isLast && widget.test.plusOnLast) ? '$v+' : '$v';
                final isSelected = _selected == v;
                final isFaded = _selected != null && !isSelected;

                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  opacity: isFaded ? 0.25 : 1.0,
                  child: GestureDetector(
                    onTap: () => _onTap(v),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      scale: isSelected ? 1.1 : 1.0,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.purple.withOpacity(0.25)
                              : AppColors.panelBg,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.purple
                                : const Color(0x33B44CFF),
                            width: isSelected ? 2.4 : 1.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.purple.withOpacity(0.4),
                                    blurRadius: 16,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Completion dialog ────────────────────────────────────────────────────

class _CompletionDialog extends StatelessWidget {
  final VoidCallback onClose;
  const _CompletionDialog({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.panelBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.purple.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.purple, size: 48),
            const SizedBox(height: 14),
            const Text(
              'Quiz Complete',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This is a preview build \u2014 answers are not saved yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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

// ---------------------------------------------------------------------------
// TODO (next session): scoring math
//
// Once the scoring approach is decided, this file should:
//   1. Accept a callback (e.g. onComplete: (Map<String, dynamic> answers))
//      that fires with the raw answers collected during the quiz.
//   2. Each ImageEliminationTest answer = the WINNING option's id (the
//      one the user tapped/liked).
//   3. Each NumberPickerTest answer = the selected int value.
//   4. A separate scoring module (NOT this file) should turn raw answers
//      into category scores (0-100) used by CardRarityModel /
//      CompatCategory, and ethnic preference answers into a separate
//      preference field used for discovery filtering (not for scoring
//      Core Values itself).
// No state is persisted in this build — every answer is held only in
// each test view's local widget state and discarded on screen exit.
// ---------------------------------------------------------------------------
