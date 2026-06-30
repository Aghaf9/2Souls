import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../theme/app_colors.dart';
import '../models/card_rarity_model.dart';
import '../models/match_pool.dart';
import 'profile_screen.dart' show RarityTierVisuals, wearAdjustedGradient;

// ---------------------------------------------------------------------------
// CollectionsScreen (route/class name MessagesScreen kept for main.dart
// compatibility — this is the screen shown on the "Collections" bottom-nav
// tab.)
//
// Layout:
//   1. CHATS — exactly 3 fixed slots (Priority, 2nd, 3rd). A claimed match
//      is added here via the "Add to Chats" action (see _CardActionSheet),
//      with a Clash Royale-style "slot into the deck" animation. Once in
//      a chat slot, tapping the card opens a menu with "Open Chat" or
//      "Demote" (removes it from the chat slot, pushing it back down into
//      the general Collections pool).
//   2. COLLECTIONS — every other claimed match not yet in a chat slot,
//      grouped by rarity tier. A match claimed but not moved into Chats
//      within 24h is automatically removed (re-entered into the dating
//      pool) — enforced via CollectionStore.sweepExpired(), run on a
//      periodic timer (NOT during build — see _MessagesScreenState).
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

  /// When this match was claimed (won from a case or the Top Match
  /// walkout). Drives the 24h expiry: if not moved into Chats within
  /// kExpiryWindow of claimedAt, it's automatically removed from the
  /// Collections pool and "re-entered into the dating pool" (i.e. simply
  /// discarded here, since there's no real dating pool to return it to).
  final DateTime claimedAt;

  const MatchEntry({
    required this.id,
    required this.name,
    required this.tier,
    required this.wear,
    this.photoUrl,
    required this.claimedAt,
  });

  factory MatchEntry.fromCandidate(MatchCandidate c) {
    return MatchEntry(
      id: c.id,
      name: c.name,
      tier: c.tier,
      wear: c.wear,
      photoUrl: c.photoUrl,
      claimedAt: DateTime.now(),
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
  static const Duration kExpiryWindow = Duration(hours: 24);

  final List<MatchEntry> matches = [];
  // Exactly 3 chat slots, by index 0 (Priority), 1, 2. Null = empty.
  // Moving a match here exempts it from the 24h expiry sweep.
  final List<MatchEntry?> chats = [null, null, null];

  void addWonMatch(MatchCandidate candidate) {
    matches.add(MatchEntry.fromCandidate(candidate));
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'View profile for ${entry.name} (not wired up yet)',
              ),
            ),
          );
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
            MaterialPageRoute(builder: (_) => _GuessChatScreen(match: entry)),
          );
        },
        onDemote: () {
          Navigator.pop(sheetContext);
          CollectionStore.instance.demoteFromChats(entry);
        },
      ),
    );
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ChatsSection(
                      chats: store.chats,
                      justAddedId: _justAddedId,
                      onTapSlot: _showChatActions,
                    ),
                    const SizedBox(height: 22),
                    if (unplacedMatches.isEmpty && store.matches.isEmpty)
                      const _EmptyState()
                    else
                      ...tierOrder
                          .where((t) => grouped.containsKey(t))
                          .map(
                            (tier) => _TierSection(
                              tier: tier,
                              matches: grouped[tier]!,
                              onTapCard: _showUnplacedActions,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
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
        border: Border(bottom: BorderSide(color: Color(0x22B44CFF), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'COLLECTIONS',
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
              border: Border.all(color: const Color(0x33B44CFF)),
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

// ── Chats: 3 fixed slots (tap-driven, no drag-and-drop) ──────────────────
// Drag-and-drop reordering was removed — it was the source of a freeze
// bug caused by DragTarget rebuilding on every pointer-move event while
// also racing with CollectionStore notifications. Tap-based actions (Add
// to Chats / Demote, via action sheets) achieve the same outcome more
// reliably and match the new "Clash Royale add-to-deck" interaction model
// you asked for.

class _ChatsSection extends StatelessWidget {
  final List<MatchEntry?> chats;
  final String? justAddedId;
  final void Function(MatchEntry entry) onTapSlot;

  const _ChatsSection({
    required this.chats,
    required this.justAddedId,
    required this.onTapSlot,
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
                color: AppColors.gold,
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
            'Tap a match below and choose "Add to Chats" \u2014 slot 1 is your top priority.',
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

  const _ChatSlot({
    required this.index,
    required this.label,
    required this.entry,
    required this.justAdded,
    required this.onTap,
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
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: entry != null
                  ? entry!.tier.primaryColor.withOpacity(0.5)
                  : AppColors.panelBorder,
              width: 1.2,
            ),
          ),
          child: AspectRatio(
            aspectRatio: 0.72,
            child: entry == null
                ? const _EmptySlotContent()
                : GestureDetector(
                    onTap: onTap,
                    child: TweenAnimationBuilder<double>(
                      // Clash Royale "slot into the deck" pop: scales up
                      // from 0 with an overshoot bounce when justAdded
                      // flips true, then settles at 1.0.
                      tween: Tween(begin: justAdded ? 0.0 : 1.0, end: 1.0),
                      duration: const Duration(milliseconds: 550),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: _MiniMatchCard(entry: entry!),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
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
                child: Center(
                  child: Icon(
                    Icons.person,
                    color: rc.withOpacity(0.7),
                    size: 24,
                  ),
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
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(aspectRatio: 0.68, child: _MiniMatchCard(entry: match)),
            const SizedBox(height: 4),
            Text(
              match.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              match.wear.label,
              style: TextStyle(
                color: match.tier.primaryColor.withOpacity(0.8),
                fontSize: 8,
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

// ── Placeholder "guess chat" screen — stands in for real messaging ───────
// Opened via "Open Chat" once a match is in a Chats slot. No real
// messaging backend exists yet, so this is a static stub screen.

class _GuessChatScreen extends StatelessWidget {
  final MatchEntry match;
  const _GuessChatScreen({required this.match});

  @override
  Widget build(BuildContext context) {
    final rc = match.tier.primaryColor;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: rc.withOpacity(0.2),
              child: Icon(Icons.person, color: rc, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              match.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: AppColors.textSecondary.withOpacity(0.4),
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Chat with ${match.name} isn\u2019t wired up yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'This screen is a placeholder for the real messaging feature.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
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
