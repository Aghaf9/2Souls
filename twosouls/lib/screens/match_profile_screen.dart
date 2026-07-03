import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/match_pool.dart';
import '../models/match_profile.dart';
import '../models/card_rarity_model.dart';
import 'profile_screen.dart' show RarityTierVisuals, wearAdjustedGradient;

// ---------------------------------------------------------------------------
// MatchProfileScreen
//
// Full profile view for another user — opened via "View Profile" from the
// Cards action sheet, Discover accept/deny cards, or the Open Soulmate
// reveal. NOT the logged-in user's own profile (that's ProfileScreen).
//
// Test/placeholder candidates show "—" for every blank field. As real
// backend data arrives, fields populate automatically since the screen
// reads directly from MatchProfile (no local state needed beyond the
// candidate object itself).
// ---------------------------------------------------------------------------

class MatchProfileScreen extends StatelessWidget {
  final MatchCandidate candidate;

  const MatchProfileScreen({super.key, required this.candidate});

  @override
  Widget build(BuildContext context) {
    final rc = candidate.tier.primaryColor;
    final sheen = candidate.wear.sheenIntensity;
    final gradient = wearAdjustedGradient(candidate.tier, sheen);
    final profile = candidate.profile;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          // ── Hero card header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.bgDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Rarity gradient background
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [rc.withOpacity(0.35), AppColors.bgDark],
                      ),
                    ),
                  ),
                  // Card visual centered
                  Center(
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(top: 40),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradient,
                        ),
                        border: Border.all(
                          color: rc.withOpacity(0.7),
                          width: 1.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: rc.withOpacity(0.4),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: rc.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: rc.withOpacity(0.5)),
                            ),
                            child: Text(
                              candidate.tier.label,
                              style: TextStyle(
                                color: rc,
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: rc.withOpacity(0.6)),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.person,
                                  color: rc.withOpacity(0.7),
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            candidate.name,
                            style: TextStyle(
                              color: rc,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${candidate.tier.label} \u2022 ${candidate.wear.label}',
                            style: TextStyle(
                              color: rc.withOpacity(0.7),
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Profile content ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Name + nickname header
                Text(
                  '${candidate.name}, ${candidate.age}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (candidate.nickname != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '"${candidate.nickname}"',
                    style: TextStyle(
                      color: rc,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: rc.withOpacity(0.7),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      candidate.location,
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: rc.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: rc.withOpacity(0.4)),
                      ),
                      child: Text(
                        '${candidate.compatibility}% match',
                        style: TextStyle(
                          color: rc,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Bio
                if (profile?.bio != null) ...[
                  _SectionHeader(title: 'ABOUT', color: rc),
                  const SizedBox(height: 8),
                  _TextCard(text: profile!.bio!),
                  const SizedBox(height: 20),
                ],

                // Quick facts
                _SectionHeader(title: 'QUICK FACTS', color: rc),
                const SizedBox(height: 10),
                _FactGrid(profile: profile, candidate: candidate, rc: rc),
                const SizedBox(height: 20),

                // Languages
                _SectionHeader(title: 'LANGUAGES', color: rc),
                const SizedBox(height: 8),
                _TagsRow(
                  tags: profile?.languages.isNotEmpty == true
                      ? profile!.languages
                      : null,
                  emptyText: 'Not specified',
                  color: rc,
                ),
                const SizedBox(height: 20),

                // Life & values
                _SectionHeader(title: 'LIFE & VALUES', color: rc),
                const SizedBox(height: 10),
                _LifeValuesGrid(profile: profile, rc: rc),
                const SizedBox(height: 20),

                // Personality
                _SectionHeader(title: 'PERSONALITY', color: rc),
                const SizedBox(height: 10),
                _PersonalityGrid(profile: profile, rc: rc),
                const SizedBox(height: 20),

                // Interests
                if (profile?.interests.isNotEmpty == true) ...[
                  _SectionHeader(title: 'INTERESTS', color: rc),
                  const SizedBox(height: 8),
                  _TagsRow(tags: profile!.interests, color: rc),
                  const SizedBox(height: 20),
                ],

                // Compat breakdown
                _SectionHeader(title: 'COMPATIBILITY BREAKDOWN', color: rc),
                const SizedBox(height: 10),
                _CompatGrid(candidate: candidate, rc: rc),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }
}

// ── Text card ────────────────────────────────────────────────────────────────

class _TextCard extends StatelessWidget {
  final String text;
  const _TextCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.panelBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}

// ── Quick facts 2-column grid ─────────────────────────────────────────────────

class _FactGrid extends StatelessWidget {
  final MatchProfile? profile;
  final MatchCandidate candidate;
  final Color rc;
  const _FactGrid({
    required this.profile,
    required this.candidate,
    required this.rc,
  });

  @override
  Widget build(BuildContext context) {
    final facts = [
      ('Career', Icons.work_outline, profile?.career),
      ('From', Icons.home_outlined, profile?.hometown),
      ('Based in', Icons.location_city, candidate.location),
      ('Future home', Icons.explore_outlined, profile?.futureLocation),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: facts.map((f) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 42) / 2,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.panelBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.panelBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(f.$2, color: rc.withOpacity(0.7), size: 14),
                    const SizedBox(width: 5),
                    Text(
                      f.$1,
                      style: TextStyle(
                        color: rc.withOpacity(0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  f.$3 ?? '\u2014',
                  style: TextStyle(
                    color: f.$3 != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary.withOpacity(0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Tags row ──────────────────────────────────────────────────────────────────

class _TagsRow extends StatelessWidget {
  final List<String>? tags;
  final String? emptyText;
  final Color color;
  const _TagsRow({required this.tags, required this.color, this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (tags == null || tags!.isEmpty) {
      return Text(
        emptyText ?? '\u2014',
        style: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.4),
          fontSize: 12,
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags!
          .map(
            (t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.35)),
              ),
              child: Text(
                t,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Life & values grid ────────────────────────────────────────────────────────

class _LifeValuesGrid extends StatelessWidget {
  final MatchProfile? profile;
  final Color rc;
  const _LifeValuesGrid({required this.profile, required this.rc});

  @override
  Widget build(BuildContext context) {
    String kidsLabel = '\u2014';
    final p = profile; // local copy so Dart can promote the nullable type
    if (p != null && p.wantedKids != null) {
      kidsLabel = p.wantedKids == 0
          ? 'No kids'
          : '${p.wantedKids} kid${p.wantedKids == 1 ? '' : 's'}';
    }

    final rows = [
      ('Relationship goal', Icons.favorite_outline, p?.relationshipGoal),
      ('Kids', Icons.child_care, p?.wantedKids != null ? kidsLabel : null),
      ('Religion', Icons.self_improvement, p?.religion),
      ('Politics', Icons.how_to_vote_outlined, p?.politicalLeaning),
      ('Pets', Icons.pets, p?.petPreference),
      ('Drinking', Icons.wine_bar_outlined, p?.drinkingHabit),
      ('Smoking', Icons.smoke_free, p?.smokingHabit),
      ('Exercise', Icons.fitness_center, p?.exerciseFrequency),
      ('Diet', Icons.restaurant_outlined, p?.diet),
      ('Sleep', Icons.bedtime_outlined, p?.sleepSchedule),
    ];

    return Column(
      children: rows
          .map((r) => _InfoRow(label: r.$1, icon: r.$2, value: r.$3, rc: rc))
          .toList(),
    );
  }
}

// ── Personality grid ──────────────────────────────────────────────────────────

class _PersonalityGrid extends StatelessWidget {
  final MatchProfile? profile;
  final Color rc;
  const _PersonalityGrid({required this.profile, required this.rc});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Personality type', Icons.psychology_outlined, profile?.personalityType),
      ('Love language', Icons.favorite, profile?.loveLanguage),
      ('Communication', Icons.chat_bubble_outline, profile?.communicationStyle),
      ('Conflict style', Icons.handshake_outlined, profile?.conflictStyle),
    ];

    return Column(
      children: rows
          .map((r) => _InfoRow(label: r.$1, icon: r.$2, value: r.$3, rc: rc))
          .toList(),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final Color rc;
  const _InfoRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.rc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: rc.withOpacity(0.6), size: 16),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '\u2014',
              style: TextStyle(
                color: value != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withOpacity(0.35),
                fontSize: 12,
                fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compat breakdown ──────────────────────────────────────────────────────────

class _CompatGrid extends StatelessWidget {
  final MatchCandidate candidate;
  final Color rc;
  const _CompatGrid({required this.candidate, required this.rc});

  static const _labels = {
    CompatCategory.hobbies: 'Hobbies',
    CompatCategory.careerEducation: 'Career',
    CompatCategory.looks: 'Looks',
    CompatCategory.lifestyle: 'Lifestyle',
    CompatCategory.coreValues: 'Values',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.panelBorder),
      ),
      child: Column(
        children: CompatCategory.values.map((cat) {
          final score = candidate.compatScores[cat] ?? 0;
          final qualifies = score >= CardRarityModel.kQualifyThreshold;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    _labels[cat]!,
                    style: TextStyle(
                      color: qualifies
                          ? rc
                          : AppColors.textSecondary.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.07),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        qualifies
                            ? rc
                            : AppColors.textSecondary.withOpacity(0.3),
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
                        : AppColors.textSecondary.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
