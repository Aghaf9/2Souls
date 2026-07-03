import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../home_screen.dart';
import '../splash_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.data != null) {
          return FutureBuilder(
            future: UserService.instance.loadCurrentUser(),
            builder: (context, profileSnap) {
              if (profileSnap.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }
              return const HomeScreen();
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}
