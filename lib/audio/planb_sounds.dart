// lib/audio/planb_sounds.dart
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Central audio manager for Plan B.
///
/// Paths are relative to the assets folder (do NOT include "assets/").
/// Example: audio/planb_sounds/tap.mp3, audio/music/background.wav
class PlanBSounds {
  PlanBSounds._();
  static final PlanBSounds instance = PlanBSounds._();

  // UI-bindable toggles + volumes
  final ValueNotifier<bool> musicEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> sfxEnabled = ValueNotifier<bool>(true);

  final ValueNotifier<double> musicVolume = ValueNotifier<double>(0.35);
  final ValueNotifier<double> sfxVolume = ValueNotifier<double>(0.85);

  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'music');
  final AudioPlayer _sfxPlayer = AudioPlayer(playerId: 'sfx');

  String _bgmAsset = 'audio/music/background.wav';
  bool _inited = false;

  Future<void> init({String? backgroundMusicAsset}) async {
    if (_inited) return;
    _inited = true;

    if (backgroundMusicAsset != null && backgroundMusicAsset.isNotEmpty) {
      _bgmAsset = backgroundMusicAsset;
    }

    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(musicEnabled.value ? musicVolume.value : 0.0);
    await _sfxPlayer.setVolume(sfxEnabled.value ? sfxVolume.value : 0.0);

    if (musicEnabled.value) {
      await playMusic(_bgmAsset);
    }
  }

  /// Called from GameScreen early. Safe to call repeatedly.
  Future<void> ensureMusicPlaying(String asset) async {
    if (!_inited) {
      await init(backgroundMusicAsset: asset);
      return;
    }
    _bgmAsset = asset;

    if (!musicEnabled.value) return;

    final state = _musicPlayer.state;
    if (state != PlayerState.playing) {
      await playMusic(_bgmAsset);
    }
  }

  // -------- Settings hooks --------

  Future<void> setMusicEnabled(bool enabled) async {
    musicEnabled.value = enabled;
    if (!enabled) {
      await stopMusic();
      return;
    }
    await _musicPlayer.setVolume(musicVolume.value);
    await playMusic(_bgmAsset);
  }

  Future<void> setSfxEnabled(bool enabled) async {
    sfxEnabled.value = enabled;
    await _sfxPlayer.setVolume(enabled ? sfxVolume.value : 0.0);
  }

  Future<void> setMusicVolume(double v) async {
  musicVolume.value = v.clamp(0.0, 1.0);
  await _musicPlayer.setVolume(musicEnabled.value ? musicVolume.value : 0.0);
}

Future<void> setSfxVolume(double v) async {
  sfxVolume.value = v.clamp(0.0, 1.0);
  await _sfxPlayer.setVolume(sfxEnabled.value ? sfxVolume.value : 0.0);
}

  // -------- Music + SFX playback --------

  Future<void> playMusic(String asset) async {
    if (!_inited) await init(backgroundMusicAsset: asset);
    if (!musicEnabled.value) return;

    try {
      await _musicPlayer.stop();
      await _musicPlayer.play(
        AssetSource(asset),
        volume: musicVolume.value,
      );
      debugPrint('[PlanBSounds] music play started: $asset');
    } catch (e) {
      debugPrint('[PlanBSounds] music play error: $e');
    }
  }

  Future<void> stopMusic() async {
    try {
      await _musicPlayer.stop();
    } catch (_) {}
  }

  Future<void> _playSfx(String asset) async {
    if (!_inited) await init();
    if (!sfxEnabled.value) return;

    try {
      await _sfxPlayer.stop(); // keep sfx snappy; avoids stacking chaos
      await _sfxPlayer.play(
        AssetSource(asset),
        volume: sfxVolume.value,
      );
      debugPrint('[PlanBSounds] play() started for $asset');
    } catch (e) {
      debugPrint('[PlanBSounds] sfx play error: $e');
    }
  }

  // Methods GameScreen expects
  void tap() => unawaited(_playSfx('audio/planb_sounds/tap.mp3'));
  void movePiece() => unawaited(_playSfx('audio/planb_sounds/move.mp3'));
  void planB() => unawaited(_playSfx('audio/planb_sounds/planB.mp3'));
  void win() => unawaited(_playSfx('audio/planb_sounds/win.mp3'));
  void error() => unawaited(_playSfx('audio/planb_sounds/error.mp3'));

  // Your debug button calls this
  Future<void> debugTestTap() async {
    await _playSfx('audio/planb_sounds/tap.mp3');
  }
}