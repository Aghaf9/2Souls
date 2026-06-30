import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;

  const BottomNav({super.key, required this.currentIndex});

  static const _glowColor = Color(0xFFB44CFF); // purple-pink glow
  static const _glowColorSoft = Color(0xFFE085FF);

  static const _items = [
    (
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
      route: '/home',
    ),
    (
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      label: 'Discover',
      route: '/discover',
    ),
    (
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      label: 'Messages',
      route: '/messages',
    ),
    (
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
      route: '/profile',
    ),
  ];

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    Navigator.pushReplacementNamed(context, _items[index].route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B0F1F),
        border: Border(top: BorderSide(color: Color(0x33B44CFF), width: 0.6)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (index) {
              final isSelected = index == currentIndex;
              final item = _items[index];

              return Expanded(
                child: _NavButton(
                  icon: isSelected ? item.selectedIcon : item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  glowColor: _glowColor,
                  glowColorSoft: _glowColorSoft,
                  onTap: () => _onTap(context, index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color glowColor;
  final Color glowColorSoft;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.glowColor,
    required this.glowColorSoft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: glowColor.withAlpha(40),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 52,
              height: 34,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // outer soft halo - always present, just fades in/out
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: isSelected ? 1.0 : 0.0,
                    child: Container(
                      width: 52,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: RadialGradient(
                          colors: [
                            glowColor.withAlpha(110),
                            glowColor.withAlpha(0),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withAlpha(160),
                            blurRadius: 22,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: glowColorSoft.withAlpha(90),
                            blurRadius: 10,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: Icon(
                      icon,
                      key: ValueKey('$icon-$isSelected'),
                      size: 26,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withAlpha(160),
                      shadows: isSelected
                          ? [
                              Shadow(color: glowColor, blurRadius: 16),
                              Shadow(color: glowColorSoft, blurRadius: 8),
                            ]
                          : [],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? glowColorSoft : Colors.white.withAlpha(140),
                shadows: isSelected
                    ? [Shadow(color: glowColor.withAlpha(180), blurRadius: 10)]
                    : [],
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
