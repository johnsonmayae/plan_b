// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../planb_game.dart';        // for PlanBMode, game types
import '../ai/planb_ai.dart';      // for Difficulty
import '../audio/planb_sounds.dart';
import 'settings_screen.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ---------- VS CPU bottom sheet with Plan B mode toggle ----------

  void _showCpuDifficultySheet(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Local state for the bottom sheet (difficulty + mode)
    PlanBMode selectedMode = PlanBMode.casual;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  const SizedBox(height: 8),
                  Text(
                    'Play vs Computer',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  // --- Plan B Mode toggle ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan B Mode',
                          style: textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedMode == PlanBMode.casual
                              ? 'Casual: CPU can cancel your winning moves with Plan B.'
                              : 'No Mercy: once you find a winning move, CPU can’t cancel it.',
                          style: textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Casual'),
                              selected: selectedMode == PlanBMode.casual,
                              onSelected: (selected) {
                                if (!selected) return;
                                setModalState(() {
                                  selectedMode = PlanBMode.casual;
                                });
                              },
                              selectedColor:
                                  colorScheme.primary.withOpacity(0.16),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('No Mercy'),
                              selected: selectedMode == PlanBMode.noMercy,
                              onSelected: (selected) {
                                if (!selected) return;
                                setModalState(() {
                                  selectedMode = PlanBMode.noMercy;
                                });
                              },
                              selectedColor:
                                  colorScheme.error.withOpacity(0.16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 16),

                  // --- Difficulty options ---
                  ListTile(
                    title: const Text('Easy'),
                    subtitle: const Text('Random but legal moves'),
                    onTap: () => _startCpuGame(
                      context,
                      Difficulty.easy,
                      selectedMode,
                    ),
                  ),
                  ListTile(
                    title: const Text('Normal'),
                    subtitle: const Text('Greedy + avoids simple traps'),
                    onTap: () => _startCpuGame(
                      context,
                      Difficulty.normal,
                      selectedMode,
                    ),
                  ),
                  ListTile(
                    title: const Text('Hard'),
                    subtitle: const Text('Deeper search, more cautious'),
                    onTap: () => _startCpuGame(
                      context,
                      Difficulty.hard,
                      selectedMode,
                    ),
                  ),
                  ListTile(
                    title: const Text('Expert'),
                    subtitle: const Text('Strongest CPU, most stubborn'),
                    onTap: () => _startCpuGame(
                      context,
                      Difficulty.expert,
                      selectedMode,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _startCpuGame(
    BuildContext context,
    Difficulty level,
    PlanBMode mode,
  ) {
    Navigator.pop(context); // close bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          vsCpu: true,
          cpuDifficulty: level,
          planBMode: mode,
        ),
      ),
    );
  }

  // Test sound helper removed; use the visible test button which calls
  // `PlanBSounds.instance.debugTestTap()` instead.

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Text(
                'PLAN B',
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Abstract strategy for two players.\nMind the second move.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              // Logo blob
              Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF141826),
                      Color(0xFF050814),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.change_circle_outlined,
                    size: 72,
                    color: colorScheme.secondary,
                  ),
                ),
              ),
              const Spacer(),

              // PLAY LOCAL
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GameScreen(
                          vsCpu: false,
                          cpuDifficulty: Difficulty.normal,
                          planBMode: PlanBMode.casual,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    'PLAY LOCAL',
                    style: textTheme.labelLarge,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // PLAY VS COMPUTER
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showCpuDifficultySheet(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    'PLAY VS COMPUTER',
                    style: textTheme.labelLarge,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // HOW TO PLAY
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/how-to-play');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: colorScheme.secondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    'HOW TO PLAY',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // TEST SOUND (small debug button)
              ElevatedButton.icon(
  onPressed: () async {
    await PlanBSounds.instance.debugTestTap();
  },
  icon: const Icon(Icons.volume_up),
  label: const Text('Play test sound'),
),

              const SizedBox(height: 8),

              // SETTINGS
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Settings'),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}