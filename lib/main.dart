import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const TwoSoulsApp());
}

class TwoSoulsApp extends StatelessWidget {
  const TwoSoulsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '2souls',
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const Placeholder(),
      },
    );
  }
}