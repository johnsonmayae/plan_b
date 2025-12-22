import 'package:flutter/material.dart';

import '../planb_game.dart';
import '../theme/game_colors.dart';

/// Single circular disc used for rendering a piece.
///
/// NOTE: Board code expects named params `color:` and `size:`.
class PieceDisc extends StatelessWidget {
  final Color color;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final bool shadow;

  const PieceDisc({
    super.key,
    required this.color,
    required this.size,
    this.borderColor,
    this.borderWidth = 1.4,
    this.shadow = true,
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
          color: borderColor ?? const Color(0x33000000),
          width: borderWidth,
        ),
        boxShadow: shadow
            ? const [
                BoxShadow(
                  blurRadius: 10,
                  spreadRadius: 0.6,
                  offset: Offset(0, 4),
                  color: Color(0x33000000),
                ),
              ]
            : null,
      ),
    );
  }
}

/// Renders a vertical stack of pieces in a single board slot.
///
/// This matches the call sites in `board_ring.dart`:
/// - PieceStackWidget(pieces: ..., maxSize: ..., borderWidth: ..., borderColor: ... )
class PieceStackWidget extends StatelessWidget {
  final List<Player> pieces;

  /// Largest disc diameter.
  final double maxSize;

  /// Disc border styling.
  final double borderWidth;
  final Color? borderColor;

  const PieceStackWidget({
    super.key,
    required this.pieces,
    this.maxSize = 44,
    this.borderWidth = 1.4,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final gc = Theme.of(context).extension<GameColors>()!;
    if (pieces.isEmpty) return const SizedBox.shrink();

    // Keep stack tight and readable.
    final count = pieces.length;
    final minSize = (maxSize * 0.62).clamp(14.0, maxSize);
    final step = count <= 1 ? 0.0 : ((maxSize - minSize) / (count - 1));

    // Vertical lift per disc; capped so stacks don't explode outside the slot.
    final lift = (maxSize * 0.20).clamp(6.0, 12.0);

    // Border fallback prefers theme’s neutral border.
    final effectiveBorder = borderColor ?? gc.pieceBorder;

    return SizedBox(
      width: maxSize,
      height: maxSize + (count - 1) * lift,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          for (int i = 0; i < count; i++)
            Positioned(
              bottom: i * lift,
              child: PieceDisc(
                color: pieces[i] == Player.a ? gc.playerA : gc.playerB,
                size: maxSize - (i * step),
                borderColor: effectiveBorder,
                borderWidth: borderWidth,
              ),
            ),
        ],
      ),
    );
  }
}