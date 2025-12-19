// lib/audio/planb_sounds.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class PlanBSounds {
  PlanBSounds._();

  static final PlanBSounds instance = PlanBSounds._();

  /// Current playing sound filename (or null when idle).
  final ValueNotifier<String?> currentSound = ValueNotifier<String?>(null);

  /// Last completed sound filename (for brief debug display).
  final ValueNotifier<String?> lastCompleted = ValueNotifier<String?>(null);
  
  /// Mute flag for SFX. When true, `_play` will not start audio playback.
  final ValueNotifier<bool> muted = ValueNotifier<bool>(false);

  void setMuted(bool value) => muted.value = value;
  void toggleMuted() => muted.value = !muted.value;

  // Using short-lived players for each SFX; no shared player needed.

  /// Optional init hook – safe to call, even if nothing is preloaded.
  Future<void> init() async {
    // If we ever want to pre-warm audio, we can do it here.
    // For now, just log so we know it was called.
    debugPrint('[PlanBSounds] init() called');
  }

  Future<void> _play(String file) async {
    final assetPath = 'audio/planb_sounds/$file';
    debugPrint('[PlanBSounds] Trying to play: $assetPath');

    // Use a short-lived player for each short SFX to avoid races when multiple
    // sounds are requested in quick succession (e.g. tap + move). This ensures
    // each sound has its own playback instance and won't be stopped by later
    // requests.
    final player = AudioPlayer();
    try {
      player.setReleaseMode(ReleaseMode.stop);
      // Start near-maximum volume; allow user/system to control final level.
      player.setVolume(1.0);
      // Use low-latency mode for short UI sounds when supported.
      // If muted, do not start playback; update lastCompleted for debug.
      if (muted.value) {
        debugPrint('[PlanBSounds] muted, skipping $assetPath');
        lastCompleted.value = 'muted';
        Future.delayed(const Duration(milliseconds: 600), () {
          lastCompleted.value = null;
        });
        return;
      }

      // Announce current sound for UI/debug overlays.
      currentSound.value = file;

      await player.play(AssetSource(assetPath), mode: PlayerMode.lowLatency);
      debugPrint('[PlanBSounds] play() started for $assetPath');

      // Wait until playback completes before disposing so the sound actually
      // finishes. `play` returns once playback starts, not when it ends.
      await player.onPlayerComplete.first;
      debugPrint('[PlanBSounds] playback completed for $assetPath');

      // Update last completed and clear current after a short delay to make
      // the overlay visible briefly.
      lastCompleted.value = file;
      Future.delayed(const Duration(milliseconds: 600), () {
        lastCompleted.value = null;
      });
      currentSound.value = null;
    } catch (e, st) {
      debugPrint('[PlanBSounds] ERROR playing $assetPath: $e');
      debugPrint('$st');
    } finally {
      try {
        await player.dispose();
      } catch (_) {}
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
