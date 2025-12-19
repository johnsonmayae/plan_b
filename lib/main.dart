// lib/main.dart
import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
// 'game_screen.dart' is imported where needed (screens that navigate to it).
import 'screens/how_to_play_screen.dart';

void main() {
  runApp(const PlanBApp());
}

class PlanBApp extends StatefulWidget {
  const PlanBApp({super.key});

  @override
  State<PlanBApp> createState() => _PlanBAppState();
}

class _PlanBAppState extends State<PlanBApp> {
  @override
  void initState() {
    super.initState();
    // Optionally warm audio system.
    PlanBSounds.instance.init();
  }

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
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            // On-screen debug overlay for audio playback.
            Positioned(
              right: 12,
              top: 12,
              child: ValueListenableBuilder<String?>(
                valueListenable: PlanBSounds.instance.currentSound,
                builder: (context, current, _) {
                  final last = PlanBSounds.instance.lastCompleted.value;
                  if (current == null && last == null) return const SizedBox.shrink();

                  final text = current != null ? 'Playing: $current' : 'Last: $last';

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      text,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

