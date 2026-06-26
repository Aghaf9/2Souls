import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          "Messages",
          style: TextStyle(fontSize: 40),
        ),
      ),
      bottomNavigationBar: BottomNav(currentIndex: 2),
    );
  }
}