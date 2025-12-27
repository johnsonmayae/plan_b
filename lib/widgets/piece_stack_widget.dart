import 'package:flutter/material.dart';
import '../planb_game.dart';
import '../theme/game_colors.dart';

class PieceStackWidget extends StatelessWidget {
  const PieceStackWidget({
    super.key,
    required this.pieces,
    this.highlight = false,
    this.forbidden = false,
  });

  final List<Player> pieces;
  final bool highlight;
  final bool forbidden;

  @override
  Widget build(BuildContext context) {
    final gc = GameColors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;

        // --- Classic sizing targets (smaller than your current build) ---
        // The old screenshot looks like the disc was ~2/3 of the slot diameter.
        final disc = size * 0.66;
        final ringStroke = size * 0.055;

        // Ring color logic (forbidden wins over highlight)
        Color ringColor = gc.slotRing.withOpacity(0.35);
        if (highlight) ringColor = gc.highlightRing.withOpacity(0.55);
        if (forbidden) ringColor = gc.forbiddenRing.withOpacity(0.55);

        // Show up to 3 pieces visually (no counters).
        final shown = pieces.length <= 3
            ? pieces
            : pieces.sublist(pieces.length - 3);

        // Draw bottom -> top with tiny offset so a 3-stack is visible.
        // (Offsets tuned to stay inside the slot like your classic screenshot.)
        final widgets = <Widget>[];

        for (int i = 0; i < shown.length; i++) {
          final p = shown[i];
          final depthFromTop = (shown.length - 1) - i; // 0 = top

          final shrink = 1.0 - (depthFromTop * 0.06); // slightly smaller underneath
          final d = disc * shrink;

          final offset = depthFromTop * (size * 0.045);

          widgets.add(
            Transform.translate(
              offset: Offset(offset, offset),
              child: PieceDisc(
                diameter: d,
                color: gc.playerColor(p),
                borderColor: gc.pieceBorder.withOpacity(depthFromTop == 0 ? 0.70 : 0.45),
              ),
            ),
          );
        }

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Slot ring
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(width: ringStroke, color: ringColor),
                ),
              ),

              // Pieces (stack)
              ...widgets,
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