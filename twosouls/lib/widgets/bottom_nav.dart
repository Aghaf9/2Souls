import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ---------------------------------------------------------------------------
// BottomNav
//
// Purple-glow nav bar — the active tab gets a purple glow halo and the
// icon pulses slightly. Inactive tabs are muted. The shell (MainShell)
// owns the IndexedStack and passes currentIndex + onTap through here.
// ---------------------------------------------------------------------------

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int index)? onTap;

  const BottomNav({super.key, required this.currentIndex, this.onTap});

  static const _items = [
    _NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    _NavItemData(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Discover',
    ),
    _NavItemData(
      icon: Icons.style_outlined,
      activeIcon: Icons.style,
      label: 'Cards',
    ),
    _NavItemData(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Dark navy base matching the logo
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.panelBorder, width: 1),
        ),
        boxShadow: [
          // Purple glow bleeding upward from the nav bar
          BoxShadow(
            color: AppColors.purple.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_items.length, (i) {
              return _NavItem(
                data: _items[i],
                isActive: i == currentIndex,
                onTap: () => onTap?.call(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active icon gets a purple glow halo
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: isActive
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: AppColors.purple.withOpacity(0.18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withOpacity(0.35),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
                    )
                  : const BoxDecoration(),
              child: Icon(
                isActive ? data.activeIcon : data.icon,
                color: isActive ? AppColors.purple : AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isActive ? AppColors.purple : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: isActive ? 0.3 : 0,
              ),
              child: Text(data.label),
            ),
          ],
        ),
      ),
    );
  }
}
