import 'package:flutter/material.dart';
import 'quiz/relationship_type_screen.dart';

// ---------------------------------------------------------------------------
// HomeScreen
//
// The Home tab now IS the relationship-type split screen directly — no
// "Take a Quiz" button, no self-card, no "Today" feed. Tapping a triangle
// goes straight into the matching quiz flow.
//
// Note: RelationshipTypeScreen has its own Scaffold/close button built in
// (designed originally to be pushed on top of something and popped with
// the X). Since it's now the Home tab itself, that close button has
// nowhere meaningful to pop back to within this tab — bottom_nav still
// lets the user switch tabs normally, so this is left as-is for now.
// ---------------------------------------------------------------------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RelationshipTypeScreen(showCloseButton: false);
  }
}
