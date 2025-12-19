// lib/widgets/board_ring.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../planb_game.dart';
import 'piece_stack_widget.dart';

class SlotData {
  final int index;
  final List<Player> stackPieces;
  final bool isHighlighted;   // legal move / hint
  final bool isSelected;      // currently selected source square

  // NEW:
  final bool isLastFrom;      // origin of last move
  final bool isLastTo;        // destination of last move

  SlotData({
    required this.index,
    required this.stackPieces,
    required this.isHighlighted,
    required this.isSelected,
    required this.isLastFrom,
    required this.isLastTo,
  });
}


typedef SlotTapCallback = void Function(int index);

class BoardRing extends StatelessWidget {
  final List<SlotData> slots;
  final SlotTapCallback onSlotTap;

  const BoardRing({
    super.key,
    required this.slots,
    required this.onSlotTap,
  }) : assert(slots.length == 8);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF141826),
            Color(0xFF050814),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest.shortestSide;
          final center = Offset(size / 2, size / 2);
          final radius = size * 0.35;

          final children = <Widget>[];

          for (final slot in slots) {
            final angle = (2 * pi * slot.index) / 8 - pi / 2;
            final dx = center.dx + radius * cos(angle);
            final dy = center.dy + radius * sin(angle);

            children.add(
              Positioned(
                left: dx - size * 0.09,
                top: dy - size * 0.09,
                width: size * 0.18,
                height: size * 0.18,
                child: _BoardSlot(
                  data: slot,
                  onTap: () => onSlotTap(slot.index),
                ),
              ),
            );
          }

          return Stack(children: children);
        },
      ),
    );
  }
}

// lib/widgets/board_ring.dart

class _BoardSlot extends StatelessWidget {
  final SlotData data;
  final VoidCallback onTap;

  const _BoardSlot({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHighlighted = data.isHighlighted;
    final isSelected = data.isSelected;

    const baseBorder = Color(0xFF2F354B);
    const highlight = Color(0xFF6C5CE7); // purple legal move
    const selected = Color(0xFF00CEC9);  // teal selected source

    final borderColor = isSelected
        ? selected
        : (isHighlighted ? highlight : baseBorder);

    final boxShadows = <BoxShadow>[];
    if (isSelected) {
      boxShadows.add(
        BoxShadow(
          color: selected.withOpacity(0.7),
          blurRadius: 12,
          spreadRadius: 3,
        ),
      );
    } else if (isHighlighted) {
      boxShadows.add(
        BoxShadow(
          color: highlight.withOpacity(0.6),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      );
    }

    // Target scale for last move destination
    final targetScale = data.isLastTo ? 1.10 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        scale: isSelected ? 1.05 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF181C2D),
            border: Border.all(
              color: borderColor,
              width: isSelected
                  ? 3.0
                  : (isHighlighted ? 2.5 : 1.5),
            ),
            boxShadow: boxShadows,
          ),
          padding: const EdgeInsets.all(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1.0, end: targetScale),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            // Child is the contents of the slot (pieces + markers)
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Pieces
                PieceStackWidget(
                  pieces: data.stackPieces,
                ),

                // Last move origin marker (bottom-left)
                if (data.isLastFrom)
                  const Align(
                    alignment: Alignment.bottomLeft,
                    child: _LastMoveDot(
                      color: Color(0xFFFFC048), // warm origin
                    ),
                  ),

                // Last move destination marker (bottom-right)
                if (data.isLastTo)
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: _LastMoveDot(
                      color: Color(0xFF00E676), // green destination
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _LastMoveDot extends StatelessWidget {
  final Color color;

  const _LastMoveDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(bottom: 2, right: 2, left: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.7),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

