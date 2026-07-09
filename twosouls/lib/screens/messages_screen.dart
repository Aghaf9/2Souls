import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/floor_cards_background.dart';
import '../widgets/identicon_avatar.dart';
import '../ads/ad_banner_widget.dart';
import '../theme/app_colors.dart';
import '../models/card_rarity_model.dart';
import '../models/match_pool.dart';
import 'chat_screen.dart';
import 'match_profile_screen.dart';
import 'profile_screen.dart' show RarityTierVisuals, wearAdjustedGradient;

// ---------------------------------------------------------------------------
// CardsScreen (route/class name MessagesScreen kept for main.dart
// compatibility — this is the screen shown on the "Cards" bottom-nav tab,
// previously labelled "Messages"/"Collections".)
//
// Layout:
//   1. CHATS — exactly 3 fixed slots (Priority, 2nd, 3rd). A claimed match
//      is added here via the "Add to Chats" action (see
//      _UnplacedActionSheet), with a Clash Royale-style "slot into the
//      deck" pop-in animation. Slots can be long-press dragged to reorder
//      between the 3 positions, or dragged from the general Cards pool
//      below to fill an empty slot. Once in a chat slot, tapping the card
//      opens a menu with "Open Chat" or "Demote".
//   2. CARDS — every other claimed match not yet in a chat slot, grouped
//      by rarity tier, also long-press draggable into any chat slot. A
//      match claimed but not moved into Chats within 24h is automatically
//      removed — enforced via CollectionStore.sweepExpired(), run on a
//      periodic timer (never during build()).
//
// Tapping an unplaced card opens a 3-option sheet: Discard, Add to Chats,
// View Profile. Tapping a card already in a Chats slot opens a 2-option
// sheet: Open Chat, Demote.
// ---------------------------------------------------------------------------

class MatchEntry {
  final String id;
  final String name;
  final RarityTier tier;
  final WearFinish wear;
  final String? photoUrl;
  final DateTime claimedAt;

  /// The original candidate this match came from. Kept so "View Profile"
  /// can navigate to the full MatchProfileScreen without losing any data.
  final MatchCandidate? candidate;

  const MatchEntry({
    required this.id,
    required this.name,
    required this.tier,
    required this.wear,
    this.photoUrl,
    required this.claimedAt,
    this.candidate,
  });

  factory MatchEntry.fromCandidate(MatchCandidate c) {
    return MatchEntry(
      // Generate a unique entry ID at claim time. Using the candidate's
      // id (c.id) caused the multi-select bug: the same candidate can
      // appear multiple times in a reel or be won across separate opens,
      // so two MatchEntries would share an id — making _selectedIds.contains()
      // return true for all of them simultaneously.
      id: 'entry_${DateTime.now().microsecondsSinceEpoch}_${c.id}',
      name: c.name,
      tier: c.tier,
      wear: c.wear,
      photoUrl: c.photoUrl,
      claimedAt: DateTime.now(),
      candidate: c,
    );
  }

  bool get isExpired =>
      DateTime.now().difference(claimedAt) >= CollectionStore.kExpiryWindow;

  Duration get timeUntilExpiry {
    final expiresAt = claimedAt.add(CollectionStore.kExpiryWindow);
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  bool operator ==(Object other) => other is MatchEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ── Shared in-memory store ──────────────────────────────────────────────
// A simple singleton so CaseOpeningScreen / TopMatchScreen (reached from
// QuizHubScreen, a totally different part of the navigation tree) can push
// a won match into the Collections screen without real backend wiring.
// Not persisted across app restarts — see the TODO at the bottom.

class CollectionStore extends ChangeNotifier {
  CollectionStore._();
  static final CollectionStore instance = CollectionStore._();

  /// A claimed match not moved into Chats within this window is removed
  /// from Collections automatically (re-entered into the dating pool).
  static const Duration kExpiryWindow = Duration(days: 14);

  final List<MatchEntry> matches = [];
  // Exactly 3 chat slots, by index 0 (Priority), 1, 2. Null = empty.
  // Moving a match here exempts it from the 24h expiry sweep.
  final List<MatchEntry?> chats = [null, null, null];

  void addWonMatch(MatchCandidate candidate) {
    matches.add(MatchEntry.fromCandidate(candidate));
    _notifySafely();
  }

  /// Adds a specific, already-known MatchEntry directly — used by
  /// DiscoverScreen when accepting someone who unpacked the current user
  /// (not a pool draw, so there's no MatchCandidate to convert).
  void addEntryDirectly(MatchEntry entry) {
    matches.add(entry);
    _notifySafely();
  }

  /// Moves a match into the given chat slot. If that slot already holds
  /// someone, they're simply removed from `chats` (and reappear in the
  /// general Collections pool, still subject to their own 24h expiry).
  void addToChats(MatchEntry entry, {int? preferredSlot}) {
    final slot = preferredSlot ?? chats.indexWhere((c) => c == null);
    if (slot == -1) return; // no empty slot and none specified — no-op
    chats[slot] = entry;
    _notifySafely();
  }

  /// Swaps the contents of two chat slots — used when dragging a card
  /// from one slot directly onto another to reorder them.
  void swapChatSlots(int a, int b) {
    final tmp = chats[a];
    chats[a] = chats[b];
    chats[b] = tmp;
    _notifySafely();
  }

  /// Removes a match from whichever chat slot it's in, pushing it back
  /// down into the general Collections pool. Re-stamps claimedAt to now
  /// so it gets a fresh 24h window rather than being immediately expired
  /// by sweepExpired() on its next run.
  void demoteFromChats(MatchEntry entry) {
    final idx = chats.indexWhere((c) => c == entry);
    if (idx == -1) return;
    chats[idx] = null;
    final refreshed = MatchEntry(
      id: entry.id,
      name: entry.name,
      tier: entry.tier,
      wear: entry.wear,
      photoUrl: entry.photoUrl,
      claimedAt: DateTime.now(),
    );
    final matchIdx = matches.indexWhere((m) => m == entry);
    if (matchIdx != -1) matches[matchIdx] = refreshed;
    _notifySafely();
  }

  void discardMatch(MatchEntry entry) {
    matches.removeWhere((m) => m == entry);
    for (int i = 0; i < chats.length; i++) {
      if (chats[i] == entry) chats[i] = null;
    }
    _notifySafely();
  }

  /// Trade-Up Contract: remove 10 cards of [tier] from the collection
  /// and add 1 randomly-generated card of the next tier up.
  /// Returns the new card if the trade succeeded, null if not enough cards.
  MatchEntry? tradeUp({
    required RarityTier tier,
    required List<MatchEntry> selected,
  }) {
    assert(selected.length == kTradeUpCount);
    final nextTier = _nextTier(tier);
    if (nextTier == null) return null; // Royal is already the highest

    // Remove the traded cards
    for (final card in selected) {
      matches.removeWhere((m) => m == card);
    }

    // Generate a new card at the next tier
    final rng = Random();
    const names = ['Alex', 'Jordan', 'Sam', 'Riley', 'Morgan', 'Quinn', 'Drew'];
    const locations = ['Brisbane, AU', 'Sydney, AU', 'Melbourne, AU'];
    final wears = WearFinish.values;
    final name = names[rng.nextInt(names.length)];
    final newCard = MatchEntry(
      id: 'tradeup_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      tier: nextTier,
      wear: wears[rng.nextInt(wears.length)],
      claimedAt: DateTime.now(),
    );
    matches.add(newCard);
    _notifySafely();
    return newCard;
  }

  /// Number of cards required for a trade-up contract.
  static const int kTradeUpCount = 10;

  static RarityTier? _nextTier(RarityTier tier) {
    switch (tier) {
      case RarityTier.bronze:
        return RarityTier.silver;
      case RarityTier.silver:
        return RarityTier.gold;
      case RarityTier.gold:
        return RarityTier.platinum;
      case RarityTier.platinum:
        return RarityTier.purple;
      case RarityTier.purple:
        return null; // already highest
      case RarityTier.none:
        return null;
    }
  }

  /// Removes any match older than kExpiryWindow that hasn't been moved
  /// into a chat slot. Called from a periodic Timer (see
  /// _MessagesScreenState), never from build() — mutating state during
  /// build() was part of what caused the drag-and-drop freeze.
  void sweepExpired() {
    final chatSet = chats.whereType<MatchEntry>().toSet();
    final before = matches.length;
    matches.removeWhere((m) => !chatSet.contains(m) && m.isExpired);
    if (matches.length != before) {
      _notifySafely();
    }
  }

  /// Safe to call from anywhere, including mid-gesture callbacks: defers
  /// the actual notifyListeners() to after the current frame finishes, so
  /// it never re-enters Flutter's build/layout phase while a gesture
  /// (like a drag-drop) is still being processed.
  void _notifySafely() {
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  Timer? _expirySweepTimer;

  // Tracks the id of a match that just got added to chats, so its slot can
  // play the "slotting into the deck" pop animation once.
  String? _justAddedId;

  @override
  void initState() {
    super.initState();
    CollectionStore.instance.addListener(_onStoreChanged);
    CollectionStore.instance.sweepExpired();
    _expirySweepTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      CollectionStore.instance.sweepExpired();
    });
  }

  @override
  void dispose() {
    CollectionStore.instance.removeListener(_onStoreChanged);
    _expirySweepTimer?.cancel();
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  void _showUnplacedActions(MatchEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _UnplacedActionSheet(
        match: entry,
        onDiscard: () {
          Navigator.pop(sheetContext);
          CollectionStore.instance.discardMatch(entry);
        },
        onAddToChats: () {
          Navigator.pop(sheetContext);
          final hasEmptySlot = CollectionStore.instance.chats.any(
            (c) => c == null,
          );
          if (hasEmptySlot) {
            setState(() => _justAddedId = entry.id);
            CollectionStore.instance.addToChats(entry);
            Future.delayed(const Duration(milliseconds: 900), () {
              if (mounted) setState(() => _justAddedId = null);
            });
          } else {
            _showSlotPicker(entry);
          }
        },
        onViewProfile: () {
          Navigator.pop(sheetContext);
          if (entry.candidate != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MatchProfileScreen(candidate: entry.candidate!),
              ),
            );
          }
        },
      ),
    );
  }

  void _showSlotPicker(MatchEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SlotPickerSheet(
        onPick: (slot) {
          Navigator.pop(sheetContext);
          setState(() => _justAddedId = entry.id);
          CollectionStore.instance.addToChats(entry, preferredSlot: slot);
          Future.delayed(const Duration(milliseconds: 900), () {
            if (mounted) setState(() => _justAddedId = null);
          });
        },
      ),
    );
  }

  void _showChatActions(MatchEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ChatActionSheet(
        match: entry,
        onOpenChat: () {
          Navigator.pop(sheetContext);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen(match: entry)),
          );
        },
        onDemote: () {
          Navigator.pop(sheetContext);
          CollectionStore.instance.demoteFromChats(entry);
        },
      ),
    );
  }

  /// Drag-and-drop: dropping an unplaced card (or a card from another
  /// slot) onto an empty or occupied chat slot. If the slot already has
  /// someone, they're displaced back into the general Cards pool.
  void _handleDropIntoSlot(int slot, MatchEntry entry) {
    setState(() => _justAddedId = entry.id);
    CollectionStore.instance.addToChats(entry, preferredSlot: slot);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _justAddedId = null);
    });
  }

  /// Drag-and-drop: dragging a card from one chat slot directly onto
  /// another chat slot swaps their positions.
  void _handleSwapSlots(int fromSlot, int toSlot) {
    CollectionStore.instance.swapChatSlots(fromSlot, toSlot);
  }

  @override
  Widget build(BuildContext context) {
    final store = CollectionStore.instance;

    final chatSet = store.chats.whereType<MatchEntry>().toSet();
    final unplacedMatches = store.matches
        .where((m) => !chatSet.contains(m))
        .toList();

    final grouped = <RarityTier, List<MatchEntry>>{};
    for (final m in unplacedMatches) {
      grouped.putIfAbsent(m.tier, () => []).add(m);
    }

    const tierOrder = [
      RarityTier.bronze,
      RarityTier.silver,
      RarityTier.gold,
      RarityTier.platinum,
      RarityTier.purple,
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _Header(matchCount: store.matches.length),
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(child: FloorCardsBackground(seed: 2)),
                  ),
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ChatsSection(
                          chats: store.chats,
                          justAddedId: _justAddedId,
                          onTapSlot: _showChatActions,
                          onDropIntoSlot: _handleDropIntoSlot,
                          onSwapSlots: _handleSwapSlots,
                        ),
                        const SizedBox(height: 12),
                        const AdBannerWidget(),
                        const SizedBox(height: 12),
                        if (unplacedMatches.isEmpty && store.matches.isEmpty)
                          const _EmptyState()
                        else ...[
                          ...tierOrder
                              .where((t) => grouped.containsKey(t))
                              .map(
                                (tier) => _TierSection(
                                  tier: tier,
                                  matches: grouped[tier]!,
                                  onTapCard: _showUnplacedActions,
                                ),
                              ),
                          // Trade-Up Contract — always show when user has
                          // any cards, so they can see progress toward 3.
                          if (unplacedMatches.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _TradeUpSection(
                              grouped: grouped,
                              onTradeUp: (tier, selected) {
                                final newCard = CollectionStore.instance
                                    .tradeUp(tier: tier, selected: selected);
                                if (newCard != null && mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => _TradeUpRevealScreen(
                                        newCard: newCard,
                                      ),
                                    ),
                                  ).then((_) {
                                    if (mounted)
                                      setState(() => _justAddedId = newCard.id);
                                    Future.delayed(
                                      const Duration(milliseconds: 900),
                                      () {
                                        if (mounted)
                                          setState(() => _justAddedId = null);
                                      },
                                    );
                                  });
                                }
                              },
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int matchCount;
  const _Header({required this.matchCount});

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
            'CARDS',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.panelBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x331E2D5A)),
            ),
            child: Text(
              '$matchCount matched',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              color: AppColors.textSecondary.withOpacity(0.4),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'No matches yet',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Open a case from Long Term to find your first match.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chats: 3 fixed slots, long-press draggable to reorder ────────────────
// Uses LongPressDraggable (requires a deliberate hold before a drag
// starts) rather than a plain Draggable, so casual taps/scrolls never
// accidentally trigger a drag. DragTarget.onWillAcceptWithDetails only
// returns true for genuinely different sources (not constantly true),
// and all state mutation happens inside onAcceptWithDetails via
// CollectionStore methods that already defer their notifyListeners() to
// the next frame — this combination is what makes the drag safe and
// freeze-free, unlike the earlier unconditional-accept implementation.

class _ChatsSection extends StatelessWidget {
  final List<MatchEntry?> chats;
  final String? justAddedId;
  final void Function(MatchEntry entry) onTapSlot;
  final void Function(int slot, MatchEntry entry) onDropIntoSlot;
  final void Function(int fromSlot, int toSlot) onSwapSlots;

  const _ChatsSection({
    required this.chats,
    required this.justAddedId,
    required this.onTapSlot,
    required this.onDropIntoSlot,
    required this.onSwapSlots,
  });

  static const _slotLabels = ['PRIORITY', '2ND', '3RD'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'CHATS',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            'Hold and drag a card to reorder, or drag one up from below \u2014 slot 1 is your top priority.',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(3, (i) {
            final entry = chats[i];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 2 ? 0 : 10),
                child: _ChatSlot(
                  index: i,
                  label: _slotLabels[i],
                  entry: entry,
                  justAdded: entry != null && entry.id == justAddedId,
                  onTap: entry == null ? null : () => onTapSlot(entry),
                  onAcceptDrop: (payload) {
                    if (payload.fromChatSlot != null) {
                      if (payload.fromChatSlot != i) {
                        onSwapSlots(payload.fromChatSlot!, i);
                      }
                    } else {
                      onDropIntoSlot(i, payload.entry);
                    }
                  },
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ChatSlot extends StatelessWidget {
  final int index;
  final String label;
  final MatchEntry? entry;
  final bool justAdded;
  final VoidCallback? onTap;
  final void Function(_DragPayload payload) onAcceptDrop;

  const _ChatSlot({
    required this.index,
    required this.label,
    required this.entry,
    required this.justAdded,
    required this.onTap,
    required this.onAcceptDrop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: index == 0 ? AppColors.gold : AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        DragTarget<_DragPayload>(
          onWillAcceptWithDetails: (details) {
            // Reject drops from this exact slot onto itself — every other
            // source (another slot, or an unplaced card) is accepted.
            return details.data.fromChatSlot != index;
          },
          onAcceptWithDetails: (details) => onAcceptDrop(details.data),
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isHovering
                      ? AppColors.gold
                      : (entry != null
                            ? entry!.tier.primaryColor.withOpacity(0.5)
                            : AppColors.panelBorder),
                  width: isHovering ? 2.2 : 1.2,
                ),
                color: isHovering
                    ? AppColors.gold.withOpacity(0.08)
                    : Colors.transparent,
              ),
              child: AspectRatio(
                aspectRatio: 0.72,
                child: entry == null
                    ? const _EmptySlotContent()
                    : LongPressDraggable<_DragPayload>(
                        data: _DragPayload(entry: entry!, fromChatSlot: index),
                        delay: const Duration(milliseconds: 250),
                        feedback: Material(
                          color: Colors.transparent,
                          child: SizedBox(
                            width: 90,
                            child: _MiniMatchCard(entry: entry!),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _MiniMatchCard(entry: entry!),
                        ),
                        child: GestureDetector(
                          onTap: onTap,
                          child: TweenAnimationBuilder<double>(
                            // Clash Royale "slot into the deck" pop: scales
                            // up from 0 with an overshoot bounce when
                            // justAdded flips true, then settles at 1.0.
                            tween: Tween(
                              begin: justAdded ? 0.0 : 1.0,
                              end: 1.0,
                            ),
                            duration: const Duration(milliseconds: 550),
                            curve: Curves.elasticOut,
                            builder: (context, scale, child) =>
                                Transform.scale(scale: scale, child: child),
                            child: _MiniMatchCard(entry: entry!),
                          ),
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Carries a dragged match plus which chat slot (if any) it came from, so
/// a DragTarget's onAcceptWithDetails can tell whether this is a reorder
/// (slot -> slot) or a promotion (general Cards pool -> slot).
class _DragPayload {
  final MatchEntry entry;
  final int? fromChatSlot;
  const _DragPayload({required this.entry, this.fromChatSlot});
}

class _EmptySlotContent extends StatelessWidget {
  const _EmptySlotContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.add,
        color: AppColors.textSecondary.withOpacity(0.3),
        size: 22,
      ),
    );
  }
}

// ── Tier-grouped general collection ─────────────────────────────────────

class _TierSection extends StatelessWidget {
  final RarityTier tier;
  final List<MatchEntry> matches;
  final void Function(MatchEntry entry) onTapCard;

  const _TierSection({
    required this.tier,
    required this.matches,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    final rc = tier.primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: rc,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tier.label,
                style: TextStyle(
                  color: rc,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(height: 1, color: rc.withOpacity(0.25)),
              ),
              const SizedBox(width: 8),
              Text(
                '${matches.length}',
                style: TextStyle(
                  color: rc.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: matches
                .map(
                  (m) => _CollectionCard(match: m, onTap: () => onTapCard(m)),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Shared small card visual ────────────────────────────────────────────

class _MiniMatchCard extends StatelessWidget {
  final MatchEntry entry;
  const _MiniMatchCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final rc = entry.tier.primaryColor;
    final sheen = entry.wear.sheenIntensity;
    final gradient = wearAdjustedGradient(entry.tier, sheen);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: Border.all(
          color: rc.withOpacity(0.55 + sheen * 0.35),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: rc.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: rc.withOpacity(0.5)),
              ),
              child: Text(
                entry.tier.label,
                style: TextStyle(
                  color: rc,
                  fontSize: 6,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: rc.withOpacity(0.5)),
                ),
                child: IdenticonAvatar(
                  seed: entry.id,
                  size: double.infinity,
                  borderRadius: 8,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              entry.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final MatchEntry match;
  final VoidCallback onTap;
  const _CollectionCard({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<_DragPayload>(
      data: _DragPayload(entry: match, fromChatSlot: null),
      delay: const Duration(milliseconds: 250),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 90, child: _MiniMatchCard(entry: match)),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _CardLabel(match: match)),
      child: GestureDetector(
        onTap: onTap,
        child: _CardLabel(match: match),
      ),
    );
  }
}

class _CardLabel extends StatefulWidget {
  final MatchEntry match;
  const _CardLabel({required this.match});

  @override
  State<_CardLabel> createState() => _CardLabelState();
}

class _CardLabelState extends State<_CardLabel> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Rebuild every minute so the countdown stays accurate.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _formatCountdown(Duration d) {
    if (d.isNegative || d == Duration.zero) return 'Expiring';
    if (d.inDays >= 1) return '${d.inDays}d left';
    if (d.inHours >= 1) return '${d.inHours}h left';
    return '${d.inMinutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.match.timeUntilExpiry;
    final isUrgent = remaining.inDays < 3;
    final countdownColor = isUrgent
        ? const Color(0xFFE05B5B)
        : AppColors.textSecondary.withOpacity(0.6);

    return SizedBox(
      width: 78,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 0.68,
            child: _MiniMatchCard(entry: widget.match),
          ),
          const SizedBox(height: 4),
          Text(
            widget.match.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            widget.match.wear.label,
            style: TextStyle(
              color: widget.match.tier.primaryColor.withOpacity(0.8),
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Countdown row — clock icon + time remaining
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, color: countdownColor, size: 8),
              const SizedBox(width: 2),
              Text(
                _formatCountdown(remaining),
                style: TextStyle(
                  color: countdownColor,
                  fontSize: 8,
                  fontWeight: isUrgent ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Action sheet: unplaced card (Discard / Add to Chats / View Profile) ──

class _UnplacedActionSheet extends StatelessWidget {
  final MatchEntry match;
  final VoidCallback onDiscard;
  final VoidCallback onAddToChats;
  final VoidCallback onViewProfile;

  const _UnplacedActionSheet({
    required this.match,
    required this.onDiscard,
    required this.onAddToChats,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final rc = match.tier.primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.panelBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: rc.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          _SheetTitleRow(match: match),
          const SizedBox(height: 18),
          _ActionRow(
            icon: Icons.add_card,
            label: 'Add to Chats',
            color: AppColors.gold,
            onTap: onAddToChats,
          ),
          const SizedBox(height: 10),
          _ActionRow(
            icon: Icons.badge_outlined,
            label: 'View Profile',
            color: AppColors.textSecondary,
            onTap: onViewProfile,
          ),
          const SizedBox(height: 10),
          _ActionRow(
            icon: Icons.delete_outline,
            label: 'Discard',
            color: const Color(0xFFE05B5B),
            onTap: onDiscard,
          ),
        ],
      ),
    );
  }
}

// ── Action sheet: card already in a Chats slot (Open Chat / Demote) ──────

class _ChatActionSheet extends StatelessWidget {
  final MatchEntry match;
  final VoidCallback onOpenChat;
  final VoidCallback onDemote;

  const _ChatActionSheet({
    required this.match,
    required this.onOpenChat,
    required this.onDemote,
  });

  @override
  Widget build(BuildContext context) {
    final rc = match.tier.primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.panelBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: rc.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          _SheetTitleRow(match: match),
          const SizedBox(height: 18),
          _ActionRow(
            icon: Icons.chat_bubble_outline,
            label: 'Open Chat',
            color: AppColors.purple,
            onTap: onOpenChat,
          ),
          const SizedBox(height: 10),
          _ActionRow(
            icon: Icons.arrow_downward,
            label: 'Demote',
            color: AppColors.textSecondary,
            onTap: onDemote,
          ),
        ],
      ),
    );
  }
}

// ── Slot picker: when all 3 chat slots are full, choose which to replace ─

class _SlotPickerSheet extends StatelessWidget {
  final void Function(int slot) onPick;
  const _SlotPickerSheet({required this.onPick});

  @override
  Widget build(BuildContext context) {
    const labels = ['Priority', '2nd', '3rd'];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.panelBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          const Text(
            'All 3 chat slots are full. Replace which one?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: i == 2 ? 0 : 10),
              child: _ActionRow(
                icon: Icons.swap_horiz,
                label: labels[i],
                color: AppColors.gold,
                onTap: () => onPick(i),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _SheetTitleRow extends StatelessWidget {
  final MatchEntry match;
  const _SheetTitleRow({required this.match});

  @override
  Widget build(BuildContext context) {
    final rc = match.tier.primaryColor;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: rc.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: rc.withOpacity(0.5)),
          ),
          child: Text(
            match.tier.label,
            style: TextStyle(
              color: rc,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          match.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TODO: persist CollectionStore (matches + chats) to a real backend once
// one exists. Right now everything lives only in the in-memory singleton
// and resets on app restart.
// ---------------------------------------------------------------------------

// ── Trade-Up Contract ─────────────────────────────────────────────────────
// CS:GO-inspired: select 10 cards of the same tier to receive 1 card of
// the next tier up. Bronze×10 → Silver, Silver×10 → Gold, and so on up
// to Platinum×10 → Royal. Royal cards cannot be traded up further.

class _TradeUpSection extends StatelessWidget {
  final Map<RarityTier, List<MatchEntry>> grouped;
  final void Function(RarityTier tier, List<MatchEntry> selected) onTradeUp;

  const _TradeUpSection({required this.grouped, required this.onTradeUp});

  @override
  Widget build(BuildContext context) {
    // Show ALL tiers present in the collection that could potentially
    // trade up (i.e. not already Royal). Eligible ones are tappable;
    // ineligible ones show a "X / 3 cards" progress bar so the user
    // knows exactly how many more they need.
    const tierOrder = [
      RarityTier.bronze,
      RarityTier.silver,
      RarityTier.gold,
      RarityTier.platinum,
    ]; // Royal is excluded — can't trade up further

    final tiersWithCards = tierOrder
        .where((t) => grouped.containsKey(t))
        .toList();

    if (tiersWithCards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'TRADE-UP CONTRACT',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            'Trade ${CollectionStore.kTradeUpCount} cards of the same tier for 1 card of the next tier up.',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...tiersWithCards.map((tier) {
          final cards = grouped[tier]!;
          final rc = tier.primaryColor;
          final next = CollectionStore._nextTier(tier)!;
          final isEligible = cards.length >= CollectionStore.kTradeUpCount;
          final progress = (cards.length / CollectionStore.kTradeUpCount).clamp(
            0.0,
            1.0,
          );

          return GestureDetector(
            onTap: isEligible
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _TradeUpSelectionScreen(
                        tier: tier,
                        cards: cards,
                        onConfirm: (selected) {
                          Navigator.of(context).pop();
                          onTradeUp(tier, selected);
                        },
                      ),
                    ),
                  )
                : null,
            child: Opacity(
              opacity: isEligible ? 1.0 : 0.65,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.panelBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isEligible
                        ? rc.withOpacity(0.6)
                        : rc.withOpacity(0.25),
                    width: isEligible ? 1.4 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: rc.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: rc.withOpacity(0.5)),
                          ),
                          child: Text(
                            '${CollectionStore.kTradeUpCount}×',
                            style: TextStyle(
                              color: rc,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tier.label,
                          style: TextStyle(
                            color: rc,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: AppColors.textSecondary.withOpacity(0.5),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '1×',
                          style: TextStyle(
                            color: next.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          next.label,
                          style: TextStyle(
                            color: next.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (isEligible)
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppColors.emerald,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ready!',
                                style: TextStyle(
                                  color: AppColors.emerald,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            '${cards.length} / ${CollectionStore.kTradeUpCount}',
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (isEligible) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right,
                            color: rc.withOpacity(0.6),
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                    if (!isEligible) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: Colors.white.withOpacity(0.07),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            rc.withOpacity(0.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Need ${CollectionStore.kTradeUpCount - cards.length} more ${tier.label} card${CollectionStore.kTradeUpCount - cards.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Trade-Up Selection Screen ─────────────────────────────────────────────

class _TradeUpSelectionScreen extends StatefulWidget {
  final RarityTier tier;
  final List<MatchEntry> cards;
  final void Function(List<MatchEntry> selected) onConfirm;

  const _TradeUpSelectionScreen({
    required this.tier,
    required this.cards,
    required this.onConfirm,
  });

  @override
  State<_TradeUpSelectionScreen> createState() =>
      _TradeUpSelectionScreenState();
}

class _TradeUpSelectionScreenState extends State<_TradeUpSelectionScreen> {
  final Set<String> _selectedIds = {};

  bool get _canConfirm => _selectedIds.length == CollectionStore.kTradeUpCount;
  bool get _allSelected => _selectedIds.length >= CollectionStore.kTradeUpCount;

  void _toggle(MatchEntry card) {
    final isFull = _selectedIds.length >= CollectionStore.kTradeUpCount;
    setState(() {
      if (_selectedIds.contains(card.id)) {
        _selectedIds.remove(card.id);
      } else if (!isFull) {
        _selectedIds.add(card.id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds.clear();
      // Pick the first kTradeUpCount cards
      for (final card in widget.cards.take(CollectionStore.kTradeUpCount)) {
        _selectedIds.add(card.id);
      }
    });
  }

  void _clearAll() {
    setState(() => _selectedIds.clear());
  }

  void _confirmTrade() {
    if (!_canConfirm) return;
    final selected = widget.cards
        .where((c) => _selectedIds.contains(c.id))
        .toList();
    widget.onConfirm(selected);
  }

  @override
  Widget build(BuildContext context) {
    final rc = widget.tier.primaryColor;
    final next = CollectionStore._nextTier(widget.tier)!;
    final leftoverCount = widget.cards.length - CollectionStore.kTradeUpCount;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0x221E2D5A))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.panelBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x331E2D5A)),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRADE-UP CONTRACT',
                          style: TextStyle(
                            color: rc,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          '${_selectedIds.length} / ${CollectionStore.kTradeUpCount} selected  →  1× ${next.label}',
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Trade Up button
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _canConfirm ? 1.0 : 0.35,
                    child: GestureDetector(
                      onTap: _canConfirm ? _confirmTrade : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: rc.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: rc.withOpacity(0.5)),
                        ),
                        child: Text(
                          'Trade Up',
                          style: TextStyle(
                            color: rc,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Progress bar ───────────────────────────────────────────────
            LinearProgressIndicator(
              value: (_selectedIds.length / CollectionStore.kTradeUpCount)
                  .clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: Colors.white.withOpacity(0.07),
              valueColor: AlwaysStoppedAnimation<Color>(rc),
            ),

            // ── Select All / Clear row ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(
                children: [
                  Text(
                    '${widget.cards.length} ${widget.tier.label} cards',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  // Select All
                  GestureDetector(
                    onTap: _allSelected ? _clearAll : _selectAll,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _allSelected
                            ? rc.withOpacity(0.15)
                            : AppColors.panelBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: rc.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _allSelected ? Icons.deselect : Icons.select_all,
                            color: rc,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _allSelected ? 'Clear All' : 'Select 10',
                            style: TextStyle(
                              color: rc,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Leftover note — shown when more than 10 cards exist
            if (leftoverCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.textSecondary.withOpacity(0.45),
                      size: 12,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$leftoverCount card${leftoverCount == 1 ? '' : 's'} not selected will stay in your collection.',
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Card grid ─────────────────────────────────────────────────
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.68,
                ),
                itemCount: widget.cards.length,
                itemBuilder: (context, index) {
                  final card = widget.cards[index];
                  final isSelected = _selectedIds.contains(card.id);
                  final isFull =
                      _selectedIds.length >= CollectionStore.kTradeUpCount;

                  return GestureDetector(
                    // ValueKey is the critical fix — without it GridView
                    // reuses render objects for different cards as you scroll,
                    // causing tapping card A to visually appear to select
                    // card B. The key forces Flutter to treat each card as
                    // a unique widget that can never be reused for another.
                    key: ValueKey(card.id),
                    onTap: () => _toggle(card),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.gold
                              : rc.withOpacity(
                                  isSelected || !isFull ? 0.3 : 0.15,
                                ),
                          width: isSelected ? 2.2 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.gold.withOpacity(0.45),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Stack(
                          children: [
                            _MiniMatchCard(entry: card),
                            // Gold check badge when selected
                            if (isSelected)
                              Positioned(
                                top: 3,
                                right: 3,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.black,
                                    size: 10,
                                  ),
                                ),
                              ),
                            // Dim overlay when full and this card isn't chosen
                            if (!isSelected && isFull)
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
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

// ── Trade-Up Reveal Screen ────────────────────────────────────────────────
// Full-screen animated reveal after a successful trade-up contract.
// Sequence: background glow fades in → rotating rays → "TRADE UP" label
// → card slams up from below with elastic scale → "Add to Cards" button
// slides up from off-screen.

class _TradeUpRevealScreen extends StatefulWidget {
  final MatchEntry newCard;
  const _TradeUpRevealScreen({required this.newCard});

  @override
  State<_TradeUpRevealScreen> createState() => _TradeUpRevealScreenState();
}

class _TradeUpRevealScreenState extends State<_TradeUpRevealScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _cardCtrl;
  late final AnimationController _particleCtrl;
  late final Animation<double> _slideUp;
  late final Animation<double> _scalePop;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _slideUp = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _cardCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _scalePop =
        TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.22), weight: 55),
          TweenSequenceItem(tween: Tween(begin: 1.22, end: 1.0), weight: 45),
        ]).animate(
          CurvedAnimation(parent: _cardCtrl, curve: const Interval(0.0, 0.90)),
        );

    _cardCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted)
        setState(() => _showButton = true);
    });

    _bgCtrl.forward().then((_) {
      if (mounted) _cardCtrl.forward();
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _cardCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rc = widget.newCard.tier.primaryColor;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Radial glow
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgCtrl,
                builder: (_, __) => Opacity(
                  opacity: _bgCtrl.value,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.12),
                        radius: 0.88,
                        colors: [
                          Color.lerp(Colors.black, rc, 0.38)!,
                          const Color(0xFF070707),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Rotating rays
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_bgCtrl, _particleCtrl]),
                builder: (_, __) => Opacity(
                  opacity: (_bgCtrl.value * 0.75).clamp(0.0, 1.0),
                  child: CustomPaint(
                    painter: _TURevealRayPainter(
                      t: _particleCtrl.value,
                      color: rc,
                    ),
                  ),
                ),
              ),
            ),
            // Particles
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _particleCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _TURevealParticlePainter(
                      t: _particleCtrl.value,
                      color: rc,
                    ),
                  ),
                ),
              ),
            ),
            // Label + card
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _bgCtrl,
                    builder: (_, __) => Opacity(
                      opacity: _bgCtrl.value,
                      child: Column(
                        children: [
                          Text(
                            'TRADE UP',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 5,
                              shadows: [
                                Shadow(
                                  color: AppColors.gold.withOpacity(0.8),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You got a ${widget.newCard.tier.label} card',
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedBuilder(
                    animation: _cardCtrl,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, 280 * _slideUp.value),
                      child: Transform.scale(
                        scale: _scalePop.value,
                        child: child,
                      ),
                    ),
                    child: _TURevealCard(entry: widget.newCard, rc: rc),
                  ),
                ],
              ),
            ),
            // Close
            Padding(
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
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
            // CTA button
            AnimatedPositioned(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              left: 24,
              right: 24,
              bottom: _showButton ? 24 : -100,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: rc,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: rc.withOpacity(0.6),
                  elevation: 12,
                ),
                child: Text(
                  'Add ${widget.newCard.name} to Cards',
                  style: TextStyle(
                    color: widget.newCard.tier == RarityTier.gold
                        ? Colors.black
                        : Colors.white,
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

class _TURevealCard extends StatelessWidget {
  final MatchEntry entry;
  final Color rc;
  const _TURevealCard({required this.entry, required this.rc});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(Colors.black, rc, 0.6)!,
            Color.lerp(Colors.black, rc, 0.25)!,
          ],
        ),
        border: Border.all(color: AppColors.gold, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: rc.withOpacity(0.7),
            blurRadius: 50,
            spreadRadius: 6,
          ),
          BoxShadow(
            color: AppColors.gold.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withOpacity(0.6)),
            ),
            child: const Text(
              'TRADE UP RESULT',
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
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: rc.withOpacity(0.8), width: 1.8),
                color: rc.withOpacity(0.1),
              ),
              child: Center(child: Icon(Icons.person, color: rc, size: 48)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            entry.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: rc.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: rc.withOpacity(0.6)),
            ),
            child: Text(
              '${entry.tier.label} \u2022 ${entry.wear.label}',
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

class _TURevealRayPainter extends CustomPainter {
  final double t;
  final Color color;
  _TURevealRayPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final len = size.width * 1.1;
    final angleOffset = t * 2 * math.pi;
    for (int i = 0; i < 20; i++) {
      final angle = (i / 20) * 2 * math.pi + angleOffset;
      final isWide = i % 2 == 0;
      final end = Offset(
        center.dx + len * math.cos(angle),
        center.dy + len * math.sin(angle),
      );
      canvas.drawLine(
        center,
        end,
        Paint()
          ..shader = LinearGradient(
            colors: [
              color.withOpacity(isWide ? 0.22 : 0.09),
              color.withOpacity(0),
            ],
          ).createShader(Rect.fromPoints(center, end))
          ..strokeWidth = isWide ? 36 : 14
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TURevealRayPainter old) => old.t != t;
}

class _TURevealParticlePainter extends CustomPainter {
  final double t;
  final Color color;
  static final List<_TUParticle> _pts = _build();
  static List<_TUParticle> _build() {
    final rng = Random(99);
    return List.generate(
      28,
      (_) => _TUParticle(
        x: rng.nextDouble(),
        baseY: 0.2 + rng.nextDouble() * 0.65,
        speed: 0.1 + rng.nextDouble() * 0.3,
        size: 1.5 + rng.nextDouble() * 3.5,
        phase: rng.nextDouble(),
      ),
    );
  }

  _TURevealParticlePainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _pts) {
      final lt = ((t + p.phase) % 1.0);
      final y = (p.baseY - lt * p.speed) * size.height;
      if (y < 0 || y > size.height) continue;
      final opacity = (math.sin(lt * math.pi)).clamp(0.0, 1.0) * 0.65;
      canvas.drawCircle(
        Offset(p.x * size.width, y),
        p.size,
        Paint()..color = color.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TURevealParticlePainter old) => old.t != t;
}

class _TUParticle {
  final double x, baseY, speed, size, phase;
  const _TUParticle({
    required this.x,
    required this.baseY,
    required this.speed,
    required this.size,
    required this.phase,
  });
}
