// lib/screens/how_to_play_screen.dart
import 'package:flutter/material.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Play'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan B',
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Plan B is an abstract strategy game for two players. '
                'You win by lining up four of your pieces around the ring, '
                'or stacking three of your own pieces on a single space. '
                'The twist: your opponent can cancel your move once per turn by calling “Plan B.”',
                style: textTheme.bodyMedium,
              ),

              const SizedBox(height: 24),
              _SectionTitle('Goals'),
              _Bullet(
                'Get 4 of your pieces in a row around the ring.',
                textTheme,
              ),
              _Bullet(
                'OR build a stack of 3 of your own pieces on one space.',
                textTheme,
              ),

              const SizedBox(height: 24),
              _SectionTitle('Turn Basics'),
              _Bullet(
                'If you still have pieces in reserve, place one on any legal space (stacks up to 3 tall).',
                textTheme,
              ),
              _Bullet(
                'Once your reserve is empty, move one of your top pieces to another space according to the game rules.',
                textTheme,
              ),
              _Bullet(
                'After your move, the game checks for a win: 4-in-a-row or a 3-piece stack of your color.',
                textTheme,
              ),
              _Bullet(
                'If it’s your turn and you have no legal moves, you lose.',
                textTheme,
              ),

              const SizedBox(height: 24),
              _SectionTitle('Plan B'),
              _Bullet(
                'Once per turn, the non-moving player can call “Plan B”.',
                textTheme,
              ),
              _Bullet(
                'Plan B undoes the last move and forces the mover to choose a different move.',
                textTheme,
              ),
              _Bullet(
                'The original move becomes illegal for that turn – you can’t repeat it.',
                textTheme,
              ),
              _Bullet(
                'Each side can only use Plan B once per opponent turn – no spamming.',
                textTheme,
              ),

              const SizedBox(height: 24),
              _SectionTitle('Modes: Casual vs No Mercy'),
              Row(
                children: [
                  Icon(Icons.sports_esports, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('Casual Mode', style: textTheme.titleSmall),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Plan B can cancel any legal move, even a move that would immediately win the game. '
                'If your “perfect” move gets cancelled, you must find another way to win.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.local_fire_department, size: 18, color: colorScheme.error),
                  const SizedBox(width: 6),
                  Text('No Mercy Mode', style: textTheme.titleSmall),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'If a move would immediately win the game, Plan B cannot cancel it. '
                'A winning move is final. Plan B still works on all non-winning moves.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'You choose the mode when starting a game against the computer.',
                style: textTheme.bodySmall,
              ),

              const SizedBox(height: 24),
              _SectionTitle('CPU Difficulty'),
              _Bullet(
                'Easy – plays legal moves but doesn’t think ahead. Good for learning.',
                textTheme,
              ),
              _Bullet(
                'Normal – looks for simple wins and avoids obvious traps.',
                textTheme,
              ),
              _Bullet(
                'Hard – searches several moves ahead and respects stack threats.',
                textTheme,
              ),
              _Bullet(
                'Expert – deepest search, more protective, uses Plan B more aggressively.',
                textTheme,
              ),

              const SizedBox(height: 24),
              _SectionTitle('Tips'),
              _Bullet(
                'Watch for 2-piece stacks – they are one move away from a 3-stack win.',
                textTheme,
              ),
              _Bullet(
                'Look at what your opponent can do after your move, not just your own threat.',
                textTheme,
              ),
              _Bullet(
                'In Casual mode, assume your most obvious winning move might get hit with Plan B.',
                textTheme,
              ),
              _Bullet(
                'Try to build positions where almost any move is good for you – that’s how you beat Plan B.',
                textTheme,
              ),

              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Ready? Go test your second-best moves.',
                  style: textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text(
      text,
      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final TextTheme textTheme;

  const _Bullet(this.text, this.textTheme, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}