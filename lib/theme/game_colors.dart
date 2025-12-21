import 'package:flutter/material.dart';

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
    final ext = Theme.of(context).extension<GameColors>();
    assert(ext != null, 'GameColors theme extension not found. Add it to ThemeData.extensions.');
    return ext!;
  }

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