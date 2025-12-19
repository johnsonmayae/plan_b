// lib/main.dart
import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
// 'game_screen.dart' is imported where needed (screens that navigate to it).
import 'screens/how_to_play_screen.dart';

void main() {
  runApp(const PlanBApp());
}

class PlanBApp extends StatelessWidget {
  const PlanBApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plan B',
      debugShowCheckedModeBanner: false,
      theme: buildPlanBTheme(),
      initialRoute: '/',
      routes: {
        '/how-to-play': (context) => const HowToPlayScreen(),
        '/': (context) => const HomeScreen(),
        },
    );
  }
}

