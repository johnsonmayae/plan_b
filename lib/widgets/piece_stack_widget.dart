import 'package:flutter/material.dart';
import '../planb_game.dart';
import '../theme/game_colors.dart';

class PieceStackWidget extends StatelessWidget {
  const PieceStackWidget({
    super.key,
    required this.pieces,
    this.highlight = false, // kept for compatibility, intentionally unused
    this.forbidden = false, // kept for compatibility, intentionally unused
  });

  final List<Player> pieces;

  // Kept ONLY so your existing calls compile.
  // Slot visuals are handled by _BoardSlot now.
  final bool highlight;
  final bool forbidden;

  @override
  Widget build(BuildContext context) {
    final gc = GameColors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;

        // Smaller disc so 3 can fit and be visible like your screenshot.
        final disc = size * 0.46;

        // Vertical offset between stacked discs.
        final offset = disc * 0.26;

        // Render up to 3 visible discs (top of stack)
        final visibleCount = pieces.length.clamp(0, 3);
        final visiblePieces = pieces.isEmpty
            ? const <Player>[]
            : pieces.sublist(pieces.length - visibleCount);

        // Center the stack vertically within the slot
        final startY = (size - disc) / 2 - ((visibleCount - 1) * offset) / 2;
        final startX = (size - disc) / 2;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < visiblePieces.length; i++)
                Positioned(
                  left: startX,
                  top: startY + i * offset,
                  child: PieceDisc(
                    diameter: disc,
                    color: (visiblePieces[i] == Player.a) ? gc.pieceA : gc.pieceB,
                    borderColor: gc.pieceBorder.withOpacity(0.65),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class PieceDisc extends StatelessWidget {
  const PieceDisc({
    super.key,
    this.size,
    this.diameter,
    required this.color,
    required this.borderColor,
  });

  final double? size;
  final double? diameter;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final d = size ?? diameter;
    assert(d != null && d > 0, 'PieceDisc requires a non-zero size/diameter.');

    final disc = d!;
    return Container(
      width: disc,
      height: disc,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.22),
            blurRadius: disc * 0.18,
            spreadRadius: disc * 0.02,
          ),
        ],
        border: Border.all(width: disc * 0.05, color: borderColor),
      ),
    );
  }
}