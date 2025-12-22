import 'package:flutter/material.dart';

import '../planb_game.dart';

/// ThemeExtension that holds ALL board/piece colors.
///
/// Keep this centralized so swapping themes automatically updates:
/// - board/ring colors
/// - piece colors
/// - highlight/forbidden colors
@immutable
class GameColors extends ThemeExtension<GameColors> {
  final Color playerA;
  final Color playerB;
  final Color cpu;
  final Color highlight;
  final Color forbidden;

  const GameColors({
    required this.playerA,
    required this.playerB,
    required this.cpu,
    required this.highlight,
    required this.forbidden,
  });

  static GameColors of(BuildContext context) {
  final gc = Theme.of(context).extension<GameColors>();
  assert(gc != null, 'GameColors extension missing from ThemeData.extensions');
  return gc!;
}

  /// Convenience: pick the correct color for a player.
  /// If vsCpu is true, Player.b is treated as CPU.
  Color playerColor(Player player, {bool vsCpu = false}) {
    if (vsCpu && player == Player.b) return cpu;
    return player == Player.a ? playerA : playerB;
  }

  // --- Backward-compatible helper getters used by some widgets ---
  Color get slotRing => highlight.withOpacity(0.25);
  Color get highlightRing => highlight.withOpacity(0.55);
  Color get forbiddenRing => forbidden.withOpacity(0.55);

  /// Neutral border for pieces/slots when not highlighted/forbidden.
  Color get pieceBorder => const Color(0x33000000);

  @override
  GameColors copyWith({
    Color? playerA,
    Color? playerB,
    Color? cpu,
    Color? highlight,
    Color? forbidden,
  }) {
    return GameColors(
      playerA: playerA ?? this.playerA,
      playerB: playerB ?? this.playerB,
      cpu: cpu ?? this.cpu,
      highlight: highlight ?? this.highlight,
      forbidden: forbidden ?? this.forbidden,
    );
  }

  @override
  GameColors lerp(ThemeExtension<GameColors>? other, double t) {
    if (other is! GameColors) return this;
    return GameColors(
      playerA: Color.lerp(playerA, other.playerA, t) ?? playerA,
      playerB: Color.lerp(playerB, other.playerB, t) ?? playerB,
      cpu: Color.lerp(cpu, other.cpu, t) ?? cpu,
      highlight: Color.lerp(highlight, other.highlight, t) ?? highlight,
      forbidden: Color.lerp(forbidden, other.forbidden, t) ?? forbidden,
    );
  }
}