import 'package:flutter/material.dart';

import 'theme/app_colors.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/signup_dob_screen.dart';

import 'package:flutter/material.dart';
 
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/signup_dob_screen.dart';
import 'screens/home_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/profile_screen.dart';
 
void main() {
  runApp(const TwoSoulsApp());
}
 
class TwoSoulsApp extends StatelessWidget {
  const TwoSoulsApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2souls',
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/signup-dob': (context) => const SignupDobScreen(),
 
        // Bottom-nav destinations — each MUST point to its OWN screen class,
        // not a copy-pasted duplicate. If two routes ever render identically,
        // check that the screen file wasn't duplicated from another one.
        '/home': (context) => const HomeScreen(),
        '/discover': (context) => const DiscoverScreen(),
        '/messages': (context) => const MessagesScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
 