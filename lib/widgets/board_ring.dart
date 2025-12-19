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

/// Small value object describing a moving piece animation request.
class MovingPiece {
  final int fromIndex;
  final int toIndex;
  final Player player;
  final Duration duration;
  final bool fromReserve;

  const MovingPiece({
    required this.fromIndex,
    required this.toIndex,
    required this.player,
    this.duration = const Duration(milliseconds: 550),
    this.fromReserve = false,
  });
}

class BoardRing extends StatefulWidget {
  final List<SlotData> slots;
  final SlotTapCallback onSlotTap;
  final MovingPiece? movingPiece;
  final VoidCallback? onMoveAnimationComplete;

  const BoardRing({
    super.key,
    required this.slots,
    required this.onSlotTap,
    this.movingPiece,
    this.onMoveAnimationComplete,
  }) : assert(slots.length == 8);

  @override
  State<BoardRing> createState() => _BoardRingState();
}

class _BoardRingState extends State<BoardRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<Offset>? _positionAnim;
  Offset? _startOffset;
  Offset? _endOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BoardRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If a new movingPiece was provided while we already have computed offsets,
    // start the animation. Offsets are computed during build (LayoutBuilder)
    // and will kick off the controller there when available.
    if (widget.movingPiece == null) {
      _controller.stop();
    }
  }

  void _startAnimationIfReady(Duration duration) {
    if (_startOffset == null || _endOffset == null || widget.movingPiece == null) return;

    _controller.duration = duration;
    _positionAnim = Tween<Offset>(begin: _startOffset!, end: _endOffset!).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward(from: 0).whenComplete(() {
      widget.onMoveAnimationComplete?.call();
    });
  }

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
          final slotCenters = <int, Offset>{};

          for (final slot in widget.slots) {
            final angle = (2 * pi * slot.index) / 8 - pi / 2;
            final dx = center.dx + radius * cos(angle);
            final dy = center.dy + radius * sin(angle);

            slotCenters[slot.index] = Offset(dx, dy);

            children.add(
              Positioned(
                left: dx - size * 0.09,
                top: dy - size * 0.09,
                width: size * 0.18,
                height: size * 0.18,
                child: _BoardSlot(
                  data: slot,
                  onTap: () => widget.onSlotTap(slot.index),
                ),
              ),
            );
          }

          // If a movingPiece request exists, compute start/end offsets and
          // create the animated floating piece on top of the stack.
          if (widget.movingPiece != null) {
            final mp = widget.movingPiece!;
            // Destination must exist inside the ring.
            if (slotCenters.containsKey(mp.toIndex)) {
              final to = slotCenters[mp.toIndex]!;
              final pieceSize = size * 0.18;

              // Compute start: either a slot center or a reserve anchor
              if (!mp.fromReserve && slotCenters.containsKey(mp.fromIndex)) {
                final from = slotCenters[mp.fromIndex]!;
                _startOffset = Offset(from.dx - pieceSize / 2, from.dy - pieceSize / 2);
              } else {
                // reserve anchor: pick a point outside the ring depending on player
                final dy = mp.player == Player.a ? center.dy + radius * 1.4 : center.dy - radius * 1.4;
                final dx = center.dx + (mp.player == Player.a ? -radius * 0.9 : radius * 0.9);
                _startOffset = Offset(dx - pieceSize / 2, dy - pieceSize / 2);
              }

              _endOffset = Offset(to.dx - pieceSize / 2, to.dy - pieceSize / 2);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _startAnimationIfReady(mp.duration);
              });

              children.add(
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final pos = _positionAnim?.value ?? _startOffset ?? Offset.zero;
                    return Positioned(
                      left: pos.dx,
                      top: pos.dy,
                      width: pieceSize,
                      height: pieceSize,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.98,
                          child: PieceDisc(
                            color: mp.player == Player.a
                                ? const Color(0xFFFDCB6E)
                                : const Color(0xFF74B9FF),
                            size: pieceSize,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }
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

