// lib/theme/game_colors.dart
import 'package:flutter/material.dart';

import '../planb_game.dart';

/// Game-specific colors that vary by selected theme.
///
/// Implemented as a ThemeExtension so you can access it with:
/// `final gc = GameColors.of(context);`
@immutable
class GameColors extends ThemeExtension<GameColors> {
  // Dots/labels
  final Color playerA;
  final Color playerB;
  final Color cpu;

  // Pieces
  final Color pieceA;
  final Color pieceB;
  final Color pieceBorder;

  // Slot rings / highlights
  final Color slotRing;
  final Color highlightRing;
  final Color forbiddenRing;

  // Optional fills (kept for future use; safe defaults)
  final Color slotFill;

  const GameColors({
    required this.playerA,
    required this.playerB,
    required this.cpu,
    required this.pieceA,
    required this.pieceB,
    required this.pieceBorder,
    required this.slotRing,
    required this.highlightRing,
    required this.forbiddenRing,
    required this.slotFill,
  });

 /// Classic (original) colorway (matches your screenshot).
const GameColors.classic()
    : this(
        // Header dots/labels
        playerA: const Color(0xFF84B7F9), // sampled from screenshot blue piece
        playerB: const Color(0xFFF5CD7C), // sampled from screenshot yellow piece
        cpu: const Color(0xFFE15241),     // sampled red dot

        // Pieces
        pieceA: const Color(0xFF84B7F9),
        pieceB: const Color(0xFFF5CD7C),
        pieceBorder: const Color(0xFFCED6E4),

        // Slot rings / highlights
        slotRing: const Color(0xFFCED6E4),
        highlightRing: const Color(0xFF7CDEFF),
        forbiddenRing: const Color(0xFFFF6B6B),

        // Slot interior tint (this is that subtle “bubble” fill)
        slotFill: const Color(0xFF191C2C),
      );

  /// Wood theme (warmer pieces)
  const GameColors.wood()
      : this(
          playerA: const Color(0xFFA1C7FF),
          playerB: const Color(0xFFFFD38A),
          cpu: const Color(0xFFD45B52),
          pieceA: const Color(0xFFA1C7FF),
          pieceB: const Color(0xFFFFD38A),
          pieceBorder: const Color(0xFFEFE7DB),
          slotRing: const Color(0xFFEFE7DB),
          highlightRing: const Color(0xFFB8F2FF),
          forbiddenRing: const Color(0xFFFF7A70),
          slotFill: const Color(0xFF1E140C),
        );

  /// Black & White - Dark
  const GameColors.bwDark()
      : this(
          playerA: const Color(0xFFF2F2F2),
          playerB: const Color(0xFFBDBDBD),
          cpu: const Color(0xFFE05A4F),
          pieceA: const Color(0xFFF2F2F2),
          pieceB: const Color(0xFFBDBDBD),
          pieceBorder: const Color(0xFFEAEAEA),
          slotRing: const Color(0xFFEAEAEA),
          highlightRing: const Color(0xFFF2F2F2),
          forbiddenRing: const Color(0xFFFF6B6B),
          slotFill: const Color(0xFF0B0B0B),
        );

  /// Black & White - Light
  const GameColors.bwLight()
      : this(
          playerA: const Color(0xFF1A1A1A),
          playerB: const Color(0xFF4D4D4D),
          cpu: const Color(0xFFD44F45),
          pieceA: const Color(0xFF1A1A1A),
          pieceB: const Color(0xFF4D4D4D),
          pieceBorder: const Color(0xFF111111),
          slotRing: const Color(0xFF111111),
          highlightRing: const Color(0xFF1A1A1A),
          forbiddenRing: const Color(0xFFCC3B32),
          slotFill: const Color(0xFFF7F7F7),
        );

  static GameColors of(BuildContext context) {
    return Theme.of(context).extension<GameColors>() ?? const GameColors.classic();
  }

  /// Backwards-compatible API (older code expects these names).
  Color get highlight => highlightRing;
  Color get forbidden => forbiddenRing;

  /// Piece color for the given player.
  Color playerColor(Player p) {
    switch (p) {
      case Player.a:
        return pieceA;
      case Player.b:
        return pieceB;
    }
  }

  @override
  GameColors copyWith({
    Color? playerA,
    Color? playerB,
    Color? cpu,
    Color? pieceA,
    Color? pieceB,
    Color? pieceBorder,
    Color? slotRing,
    Color? highlightRing,
    Color? forbiddenRing,
    Color? slotFill,
  }) {
    return GameColors(
      playerA: playerA ?? this.playerA,
      playerB: playerB ?? this.playerB,
      cpu: cpu ?? this.cpu,
      pieceA: pieceA ?? this.pieceA,
      pieceB: pieceB ?? this.pieceB,
      pieceBorder: pieceBorder ?? this.pieceBorder,
      slotRing: slotRing ?? this.slotRing,
      highlightRing: highlightRing ?? this.highlightRing,
      forbiddenRing: forbiddenRing ?? this.forbiddenRing,
      slotFill: slotFill ?? this.slotFill,
    );
  }

  @override
  GameColors lerp(ThemeExtension<GameColors>? other, double t) {
    if (other is! GameColors) return this;
    return GameColors(
      playerA: Color.lerp(playerA, other.playerA, t) ?? playerA,
      playerB: Color.lerp(playerB, other.playerB, t) ?? playerB,
      cpu: Color.lerp(cpu, other.cpu, t) ?? cpu,
      pieceA: Color.lerp(pieceA, other.pieceA, t) ?? pieceA,
      pieceB: Color.lerp(pieceB, other.pieceB, t) ?? pieceB,
      pieceBorder: Color.lerp(pieceBorder, other.pieceBorder, t) ?? pieceBorder,
      slotRing: Color.lerp(slotRing, other.slotRing, t) ?? slotRing,
      highlightRing: Color.lerp(highlightRing, other.highlightRing, t) ?? highlightRing,
      forbiddenRing: Color.lerp(forbiddenRing, other.forbiddenRing, t) ?? forbiddenRing,
      slotFill: Color.lerp(slotFill, other.slotFill, t) ?? slotFill,
    );
  }
}