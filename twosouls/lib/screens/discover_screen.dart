import '../widgets/identicon_avatar.dart';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../ads/ad_banner_widget.dart';
import '../widgets/floor_cards_background.dart';
import '../theme/app_colors.dart';
import '../models/card_rarity_model.dart';
import '../models/incoming_unpack.dart';
import 'profile_screen.dart' show RarityTierVisuals, wearAdjustedGradient;
import 'messages_screen.dart' show CollectionStore, MatchEntry;

// ---------------------------------------------------------------------------
// DiscoverScreen
//
// Shows people who have unpacked (matched with) the current user from
// THEIR side, Hinge-Likes-You style: only the top card is fully visible,
// the rest of the stack is blurred behind it. Subscription members get a
// lighter blur on the hidden cards (kSubscriptionBlurSigma vs
// kFreeBlurSigma) — no real subscription/paywall flow exists yet, so
// isSubscriber is a local toggle here for testing (see the TODO at the
// bottom of this file).
//
// Each card shows, in text at the top, whether the unpack came from the
// Short Term or Long Term flow (see IncomingUnpack.source).
//
// Accept moves the person into CollectionStore (so they show up on the
// Cards screen). Deny just removes them from the stack.
// ---------------------------------------------------------------------------

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late List<IncomingUnpack> _stack;

  // Local-only testing toggle — no real subscription/paywall exists yet.
  bool _isSubscriber = false;

  static const double kFreeBlurSigma = 18.0;
  static const double kSubscriptionBlurSigma = 6.0;

  @override
  void initState() {
    super.initState();
    _stack = _buildPlaceholderStack();
  }

  List<IncomingUnpack> _buildPlaceholderStack() {
    final rng = Random();
    const names = [
      'Riley',
      'Sam',
      'Jess',
      'Drew',
      'Casey',
      'Morgan',
      'Avery',
      'Quinn',
    ];
    const locations = [
      'Brisbane, AU',
      'Sydney, AU',
      'Melbourne, AU',
      'Gold Coast, AU',
    ];
    final tiers = RarityTier.values.where((t) => t != RarityTier.none).toList();
    final wears = WearFinish.values;
    final sources = UnpackSource.values;

    return List.generate(6, (i) {
      return IncomingUnpack(
        id: 'incoming_$i',
        name: names[rng.nextInt(names.length)],
        age: 20 + rng.nextInt(15),
        location: locations[rng.nextInt(locations.length)],
        tier: tiers[rng.nextInt(tiers.length)],
        wear: wears[rng.nextInt(wears.length)],
        source: sources[rng.nextInt(sources.length)],
      );
    });
  }

  void _accept(IncomingUnpack person) {
    CollectionStore.instance.addEntryDirectly(
      MatchEntry(
        id: 'entry_${DateTime.now().microsecondsSinceEpoch}_${person.id}',
        name: person.name,
        tier: person.tier,
        wear: person.wear,
        photoUrl: person.photoUrl,
        claimedAt: DateTime.now(),
      ),
    );
    setState(() => _stack.removeWhere((p) => p.id == person.id));
  }

  void _deny(IncomingUnpack person) {
    setState(() => _stack.removeWhere((p) => p.id == person.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              count: _stack.length,
              isSubscriber: _isSubscriber,
              onToggleSubscriber: () =>
                  setState(() => _isSubscriber = !_isSubscriber),
            ),
            Expanded(
              child: Stack(
                children: [
                  // Decorative "cards scattered on the floor" background —
                  // purely visual, never interactive (IgnorePointer), sits
                  // behind everything else at low opacity so it reads as
                  // ambient texture rather than competing with the real
                  // stack on top.
                  const Positioned.fill(
                    child: IgnorePointer(child: FloorCardsBackground(seed: 1)),
                  ),
                  _stack.isEmpty
                      ? const _EmptyState()
                      : Padding(
                          padding: const EdgeInsets.all(20),
                          child: _UnpackStack(
                            stack: _stack,
                            blurSigma: _isSubscriber
                                ? kSubscriptionBlurSigma
                                : kFreeBlurSigma,
                            onAccept: _accept,
                            onDeny: _deny,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdBannerWidget(),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  final bool isSubscriber;
  final VoidCallback onToggleSubscriber;

  const _Header({
    required this.count,
    required this.isSubscriber,
    required this.onToggleSubscriber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        border: Border(bottom: BorderSide(color: Color(0x221E2D5A), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'DISCOVER',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          // Local testing toggle for the subscription blur difference —
          // remove once a real subscription/paywall flow exists.
          GestureDetector(
            onTap: onToggleSubscriber,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSubscriber
                    ? AppColors.gold.withOpacity(0.15)
                    : AppColors.panelBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSubscriber
                      ? AppColors.gold.withOpacity(0.6)
                      : const Color(0x331E2D5A),
                ),
              ),
              child: Text(
                isSubscriber ? 'Member \u2713' : '$count likes you',
                style: TextStyle(
                  color: isSubscriber
                      ? AppColors.gold
                      : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite_border,
            color: AppColors.textSecondary.withOpacity(0.4),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'No one new yet',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'When someone unpacks you, they\u2019ll show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hinge-style stack: top card visible, rest blurred behind it ─────────

class _UnpackStack extends StatelessWidget {
  final List<IncomingUnpack> stack;
  final double blurSigma;
  final void Function(IncomingUnpack person) onAccept;
  final void Function(IncomingUnpack person) onDeny;

  const _UnpackStack({
    required this.stack,
    required this.blurSigma,
    required this.onAccept,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    // Stack paints children in list order: LAST child in the list paints
    // ON TOP. So to get the front/interactive card visually on top, it
    // must be the LAST item in the returned children list — i.e. build
    // back-to-front and do NOT reverse afterward. (The previous version
    // had a stray .reversed.toList() here, which put the unblurred top
    // card UNDER the blurred ones — that's why the front card looked
    // blurred too: a blurred card was painted on top of it.)
    final visibleCount = stack.length.clamp(0, 4);

    final children = List.generate(visibleCount, (i) {
      final reverseIndex =
          visibleCount - 1 - i; // i=0 -> deepest, i=last -> front/top
      final person = stack[reverseIndex];
      final isTop = reverseIndex == 0;
      final depth = reverseIndex; // 0 = front, higher = further back

      final card = _UnpackCard(person: person);

      final positioned = Transform.translate(
        offset: Offset(0, depth * -10.0),
        child: Transform.scale(
          scale: 1.0 - (depth * 0.04),
          child: isTop
              ? card // front card: never blurred, always fully sharp
              : ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: Opacity(
                    opacity: 1.0 - (depth * 0.15).clamp(0.0, 0.6),
                    child: card,
                  ),
                ),
        ),
      );

      if (!isTop) return positioned;

      // Only the top card gets Accept/Deny controls and is interactive.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          positioned,
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                icon: Icons.close,
                color: const Color(0xFFE05B5B),
                onTap: () => onDeny(person),
              ),
              const SizedBox(width: 24),
              _ActionButton(
                icon: Icons.favorite,
                color: AppColors.emerald,
                onTap: () => onAccept(person),
              ),
            ],
          ),
        ],
      );
    });

    return Stack(alignment: Alignment.center, children: children);
  }
}

class _UnpackCard extends StatelessWidget {
  final IncomingUnpack person;
  const _UnpackCard({required this.person});

  @override
  Widget build(BuildContext context) {
    final rc = person.tier.primaryColor;
    final sheen = person.wear.sheenIntensity;
    final gradient = wearAdjustedGradient(person.tier, sheen);

    return Container(
      width: 240,
      height: 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: Border.all(color: rc.withOpacity(0.6), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Unpacked-via label, shown in text at the top as requested.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: person.source == UnpackSource.shortTerm
                  ? AppColors.purple.withOpacity(0.15)
                  : AppColors.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: person.source == UnpackSource.shortTerm
                    ? AppColors.purple.withOpacity(0.5)
                    : AppColors.gold.withOpacity(0.5),
              ),
            ),
            child: Text(
              'Unpacked you \u2014 ${person.source.label}',
              style: TextStyle(
                color: person.source == UnpackSource.shortTerm
                    ? AppColors.purple
                    : AppColors.gold,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: rc.withOpacity(0.6), width: 1.6),
              ),
              child: IdenticonAvatar(
                seed: person.id,
                size: double.infinity,
                borderRadius: 16,
                borderColor: rc.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${person.name}, ${person.age}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            person.location,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: rc.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: rc.withOpacity(0.5)),
            ),
            child: Text(
              '${person.tier.label} \u2022 ${person.wear.label}',
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.12),
          border: Border.all(color: color, width: 1.8),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TODO:
// - This file REPLACES whatever discover_screen.dart currently exists in
//   the project. Confirm the route in main.dart still points here
//   correctly (class name DiscoverScreen, unchanged).
// - _isSubscriber is a local UI toggle for testing the blur difference
//   only. Wire this to a real subscription/paywall check once one exists.
// - No real backend detects when another user has unpacked you — _stack
//   is entirely placeholder-generated on screen load.
// ---------------------------------------------------------------------------
