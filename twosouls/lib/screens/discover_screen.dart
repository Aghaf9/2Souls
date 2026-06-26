import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
 
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          "Discover",
          style: TextStyle(fontSize: 40),
        ),
      ),
      bottomNavigationBar: BottomNav(currentIndex: 1),
    );
  }
}
