import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'ads/ad_manager.dart';
import 'screens/auth/google_login_screen.dart';
import 'screens/main_shell.dart';
import 'widgets/night_sky_background.dart';

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
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.accentSoft,
          surface: const Color(0xFF0D1033),
        ),
      ),
      builder: (context, child) => Stack(
        children: [
          const Positioned.fill(child: NightSkyBackground()),
          if (child != null) child,
        ],
      ),
      home: const _AppRouter(),
    );
  }
}

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
    // GoogleLoginScreen — the only sign-in method now.
    // onResult receives isNewUser but for testing we just go to main.
    return GoogleLoginScreen(
      onResult: (_) => setState(() => _authed = true),
      onSkip: () => setState(() => _authed = true),
    );
  }
}
