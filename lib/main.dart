// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'theme.dart';
import 'audio/planb_sounds.dart';
import 'screens/settings_screen.dart';
import 'screens/home_screen.dart';
import 'screens/how_to_play_screen.dart';
import 'theme/game_colors.dart';

final ThemeData base = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
);

final ThemeData appTheme = base.copyWith(
  extensions: <ThemeExtension<dynamic>>[
    const GameColors(
      playerA: Colors.blue,
      playerB: Colors.red,
      cpu: Colors.red,
      highlight: Colors.amber,
      forbidden: Colors.grey,
    ),
  ],
);

MaterialApp(
  theme: appTheme,
  // ...
);


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
        '/settings': (context) => const SettingsScreen(),
        '/': (context) => const HomeScreen(),
      },
      builder: (context, child) {
        final core = child ?? const SizedBox.shrink();
        return Stack(
          children: [
            core,
            // On-screen debug overlay for audio playback (hidden in release builds).
            if (!kReleaseMode)
              Positioned(
                right: 12,
                top: 12,
                child: Row(
                  children: [
                    // Mute toggle
                    ValueListenableBuilder<bool>(
                      valueListenable: PlanBSounds.instance.muted,
                      builder: (context, muted, _) {
                        return IconButton(
                          onPressed: () => PlanBSounds.instance.toggleMuted(),
                          icon: Icon(
                            muted ? Icons.volume_off : Icons.volume_up,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    ValueListenableBuilder<String?>(
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
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

