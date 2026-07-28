import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_colors.dart';
import 'ads/ad_manager.dart';
import 'services/auth_service.dart';
import 'screens/auth/google_login_screen.dart';
import 'screens/auth/post_auth_onboarding_screen.dart';
import 'screens/main_shell.dart';
import 'widgets/night_sky_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthService.instance.initializeGoogleSignIn();
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
        // Keep dark (not transparent) so Scaffolds without explicit
        // backgroundColor still look correct — only MainShell/NightSkyScaffold
        // explicitly go transparent to let the sky through.
        scaffoldBackgroundColor: AppColors.bgDark,
        colorScheme: ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.accentSoft,
          surface: const Color(0xFF0D1033),
        ),
      ),
      // NightSkyBackground rendered once here, behind every route in the
      // entire app — login screen, dialogs, sheets, everything.
      // Each Scaffold's own backgroundColor on top of this is set to
      // Colors.transparent in screens that want the sky to show through,
      // or left as AppColors.bgDark (which is almost identical) for screens
      // that just want a flat dark background.
      builder: (context, child) {
        return Stack(
          children: [
            // Night sky — root of the entire widget tree
            const Positioned.fill(child: NightSkyBackground()),
            // App content on top
            if (child != null) child,
          ],
        );
      },
      home: const _AppRouter(),
    );
  }
}

class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

enum _AppState { loggedOut, onboarding, main }

class _AppRouterState extends State<_AppRouter> {
  _AppState _state = _AppState.loggedOut;

  void _handleLoginResult(bool isNewUser) {
    setState(() => _state = isNewUser ? _AppState.onboarding : _AppState.main);
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _AppState.loggedOut:
        return GoogleLoginScreen(onResult: _handleLoginResult);
      case _AppState.onboarding:
        return PostAuthOnboardingScreen(
          needsDob: true,
          onDone: () => setState(() => _state = _AppState.main),
        );
      case _AppState.main:
        return const MainShell();
    }
  }
}
