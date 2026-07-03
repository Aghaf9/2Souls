import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav.dart';
import 'home_screen.dart';
import 'discover_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

// ---------------------------------------------------------------------------
// MainShell
//
// Root shell holding all 4 tabs in an IndexedStack so state is preserved
// when switching. Uses the existing BottomNav widget (purple glow style)
// rather than a custom nav bar.
// ---------------------------------------------------------------------------

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _tabs = [
    HomeScreen(),
    DiscoverScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
