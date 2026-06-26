import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../avatar/avatar_config.dart';
import '../avatar/avatar_renderer.dart';
import '../avatar/avatar_creator_screen.dart';

// ---------------------------------------------------------------------------
// Placeholder profile data.
//
// All numeric scores (looks, intelligence, ambition, kindness, humor,
// compatibility, hobbiesScore, careerScore) are HARDCODED PLACEHOLDERS.
// Replace `_currentUser` below with real values once the matching /
// scoring algorithm exists — every field here is just a sample so the UI
// can be wired up and tested now.
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
  final AvatarConfig avatar;

  // FUT-card style attribute scores, out of 100.
  final int looks;
  final int intelligence;
  final int ambition;
  final int kindness;
  final int humor;

  // "Direction in life" / match scoring, out of 100.
  final int compatibility;
  final int hobbiesScore;
  final int careerScore;
  final int looksScore;

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
    required this.avatar,
    required this.looks,
    required this.intelligence,
    required this.ambition,
    required this.kindness,
    required this.humor,
    required this.compatibility,
    required this.hobbiesScore,
    required this.careerScore,
    required this.looksScore,
  });

  int get overall =>
      ((looks + intelligence + ambition + kindness + humor) / 5).round();
}

// PLACEHOLDER — swap for the logged-in user's real profile.
const _currentUser = UserProfile(
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
  avatar: AvatarConfig(
    skinTone: 'tone_2',
    face: 'face_1',
    hairStyle: 'hair_3',
    hairColor: 'color_brown',
    outfit: 'outfit_2',
    accessory: 'none',
  ),
  looks: 80,
  intelligence: 85,
  ambition: 88,
  kindness: 82,
  humor: 78,
  compatibility: 72,
  hobbiesScore: 80,
  careerScore: 65,
  looksScore: 70,
);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Holds the in-memory avatar config so edits show immediately.
  // Swap this for a real fetch/save against your backend once available.
  AvatarConfig _avatarConfig = _currentUser.avatar;

  Future<void> _openAvatarCreator() async {
    final result = await Navigator.push<AvatarConfig>(
      context,
      MaterialPageRoute(
        builder: (_) => AvatarCreatorScreen(initialConfig: _avatarConfig),
      ),
    );
    if (result != null) {
      setState(() => _avatarConfig = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F1F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: Color(0xFFD4AF6A)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              _PlayerCard(
                user: user,
                avatarConfig: _avatarConfig,
                onEditAvatar: _openAvatarCreator,
              ),
              const SizedBox(height: 20),
              _AboutSection(user: user),
              const SizedBox(height: 16),
              _DirectionInLifeSection(user: user),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 3),
    );
  }
}

// ---------------------------------------------------------------------------
// FUT-style player card
// ---------------------------------------------------------------------------

class _PlayerCard extends StatelessWidget {
  final UserProfile user;
  final AvatarConfig avatarConfig;
  final VoidCallback onEditAvatar;

  const _PlayerCard({
    required this.user,
    required this.avatarConfig,
    required this.onEditAvatar,
  });

  static const gold = Color(0xFFD4AF6A);
  static const goldDark = Color(0xFF8A6A2F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold, width: 1.4),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF101C3F), Color(0xFF0A1330)],
        ),
        boxShadow: [
          BoxShadow(
            color: gold.withAlpha(40),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    color: const Color(0xFF1A2A5C),
                    child: AvatarRenderer(config: avatarConfig),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: onEditAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(150),
                      shape: BoxShape.circle,
                      border: Border.all(color: gold, width: 1.2),
                    ),
                    child: const Icon(Icons.edit, size: 16, color: gold),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user.overall}',
                      style: const TextStyle(
                        color: gold,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const Text(
                      'OVR',
                      style: TextStyle(
                        color: gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${user.age} · ${user.location}',
                style: const TextStyle(
                  color: Color(0xFF9EC5FF),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              Text(user.countryFlagEmoji, style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${user.heightCm.toStringAsFixed(0)} cm',
            style: const TextStyle(
              color: Color(0xFF6E84B8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AttrStat(label: 'LOOKS', value: user.looks),
              _AttrStat(label: 'INTELLIGENCE', value: user.intelligence),
              _AttrStat(label: 'AMBITION', value: user.ambition),
              _AttrStat(label: 'KINDNESS', value: user.kindness),
              _AttrStat(label: 'HUMOR', value: user.humor),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttrStat extends StatelessWidget {
  final String label;
  final int value;
  const _AttrStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFD4AF6A),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// About / career / hobbies section
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101830),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33B44CFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFD4AF6A), size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFD4AF6A),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final UserProfile user;
  const _AboutSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(
          title: 'ABOUT ME',
          icon: Icons.auto_awesome,
          child: Text(
            user.bio,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'CAREER',
          icon: Icons.work_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.career,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.institution,
                style: const TextStyle(color: Color(0xFF9EC5FF), fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'HOBBIES',
          icon: Icons.theater_comedy_outlined,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.hobbies
                .map((h) => Chip(
                      label: Text(h, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      backgroundColor: const Color(0xFF1B2748),
                      side: const BorderSide(color: Color(0x33B44CFF)),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "Direction in life" / compatibility section
// ---------------------------------------------------------------------------

class _DirectionInLifeSection extends StatelessWidget {
  final UserProfile user;
  const _DirectionInLifeSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101830),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x55B44CFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: Color(0xFFB44CFF), size: 16),
              const SizedBox(width: 8),
              const Text(
                'DIRECTION IN LIFE',
                style: TextStyle(
                  color: Color(0xFFB44CFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _CompatibilityRing(value: user.compatibility),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _ScoreBar(
                      icon: Icons.sports_esports_outlined,
                      label: 'Hobbies',
                      value: user.hobbiesScore,
                      color: const Color(0xFF3D74FF),
                    ),
                    const SizedBox(height: 10),
                    _ScoreBar(
                      icon: Icons.work_outline,
                      label: 'Career',
                      value: user.careerScore,
                      color: const Color(0xFF9EC5FF),
                    ),
                    const SizedBox(height: 10),
                    _ScoreBar(
                      icon: Icons.auto_awesome,
                      label: 'Looks',
                      value: user.looksScore,
                      color: const Color(0xFFB44CFF),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompatibilityRing extends StatelessWidget {
  final int value;
  const _CompatibilityRing({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: CircularProgressIndicator(
              value: value / 100,
              strokeWidth: 9,
              backgroundColor: Colors.white.withAlpha(20),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB44CFF)),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'COMPATIBILITY',
                style: TextStyle(
                  color: Color(0xFF9EC5FF),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _ScoreBar({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withAlpha(180)),
        const SizedBox(width: 6),
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withAlpha(20),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}