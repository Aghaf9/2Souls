import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'ads/ad_manager.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';

// Firebase is commented out until flutterfire configure is completed.
// Uncomment once firebase_options.dart has real credentials:
//
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// import 'screens/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdManager.instance.initialize();
  runApp(const TwoSoulsApp());
}

class TwoSoulsApp extends StatelessWidget {
  const TwoSoulsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2Souls',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgDark,
        colorScheme: ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.accentSoft,
          surface: AppColors.surface,
        ),
      ),
      // Start at login screen. LoginScreen has a "Skip for now" link
      // to go to the shell for testing, or sign in to go to the shell.
      home: const _AppRouter(),
    );
  }
}

// Simple router — shows login until the user taps "Skip" or signs in
class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  bool _authed = false;

  @override
  Widget build(BuildContext context) {
    if (_authed) return const MainShell();
    return LoginScreen(onSuccess: () => setState(() => _authed = true));
  }
}
