import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          "Home",
          style: TextStyle(fontSize: 40),
        ),
      ),
      bottomNavigationBar: BottomNav(currentIndex: 0),
    );
  }
}