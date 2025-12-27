import 'planb_sounds.dart';

extension PlanBSoundsCompat on PlanBSounds {
  Future<void> setMusicEnabledCompat(bool value) async {
    final dyn = this as dynamic;
    try { await dyn.setMusicEnabled(value); return; } catch (_) {}
    try { dyn.musicEnabled = value; return; } catch (_) {}
    try { dyn.enableMusic(value); return; } catch (_) {}
  }

  Future<void> setSfxEnabledCompat(bool value) async {
    final dyn = this as dynamic;
    try { await dyn.setSfxEnabled(value); return; } catch (_) {}
    try { dyn.sfxEnabled = value; return; } catch (_) {}
    try { dyn.enableSfx(value); return; } catch (_) {}
  }

  void setMusicVolumeCompat(double value) {
    final dyn = this as dynamic;
    try { dyn.setMusicVolume(value); return; } catch (_) {}
    try { dyn.musicVolume = value; return; } catch (_) {}
  }

  void setSfxVolumeCompat(double value) {
    final dyn = this as dynamic;
    try { dyn.setSfxVolume(value); return; } catch (_) {}
    try { dyn.sfxVolume = value; return; } catch (_) {}
  }

  Future<void> playTapCompat() async {
    final dyn = this as dynamic;
    try { await dyn.playTap(); return; } catch (_) {}
    try { await dyn.debugTestTap(); return; } catch (_) {}
  }
}