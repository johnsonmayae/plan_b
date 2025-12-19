// lib/audio/planb_sounds.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class PlanBSounds {
  PlanBSounds._();

  static final PlanBSounds instance = PlanBSounds._();

  // Single lightweight player for all SFX
  final AudioPlayer _player = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop)
    ..setVolume(0.9);

  /// Optional init hook – safe to call, even if nothing is preloaded.
  Future<void> init() async {
    // If we ever want to pre-warm audio, we can do it here.
    // For now, just log so we know it was called.
    debugPrint('[PlanBSounds] init() called');
  }

  Future<void> _play(String file) async {
    final assetPath = 'audio/planb_sounds/$file';
    debugPrint('[PlanBSounds] Trying to play: $assetPath');

    try {
      // Avoid overlapping sounds
      await _player.stop();
      await _player.play(AssetSource(assetPath));
      debugPrint('[PlanBSounds] play() completed for $assetPath');
    } catch (e, st) {
      debugPrint('[PlanBSounds] ERROR playing $assetPath: $e');
      debugPrint('$st');
    }
  }

  Future<void> tap() => _play('tap.mp3');
  Future<void> movePiece() => _play('move.mp3');
  Future<void> planB() => _play('planb.mp3');
  Future<void> win() => _play('win.mp3');
  Future<void> error() => _play('error.mp3');

  /// Simple test helper you can call from a button.
  Future<void> debugTestTap() async {
    debugPrint('[PlanBSounds] debugTestTap() pressed');
    await tap();
  }
}
