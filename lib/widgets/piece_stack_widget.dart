// lib/widgets/piece_stack_widget.dart
import 'package:flutter/material.dart';
import '../planb_game.dart';   // for Player

class PieceStackWidget extends StatelessWidget {
  final List<Player> pieces;   // was List<String>

  const PieceStackWidget({
    super.key,
    required this.pieces,
  });

  @override
  Widget build(BuildContext context) {
    if (pieces.isEmpty) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];

    for (var i = 0; i < pieces.length; i++) {
      final p = pieces[i];
      final isTop = i == pieces.length - 1;

      final color = p == Player.a
          ? const Color(0xFFFDCB6E)   // Player A
          : const Color(0xFF74B9FF);  // Player B

      children.add(
        Align(
          alignment: Alignment(0, 1 - i * 0.7),
          child: _PieceDisc(
            color: color,
            isTop: isTop,
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: children,
    );
  }
}

class _PieceDisc extends StatelessWidget {
  final Color color;
  final bool isTop;

  const _PieceDisc({
    required this.color,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isTop ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 150),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: const Color(0xFF1E1E1E),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

/// Public single-piece disc widget used for overlays/animations.
class PieceDisc extends StatelessWidget {
  final Color color;
  final double size;

  const PieceDisc({
    super.key,
    required this.color,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: const Color(0xFF1E1E1E),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
