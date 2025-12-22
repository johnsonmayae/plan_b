import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/planb_sounds.dart';
import '../theme/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Pref keys
  static const _kMusicEnabled = 'music_enabled';
  static const _kSfxEnabled = 'sfx_enabled';
  static const _kMusicVolume = 'music_volume';
  static const _kSfxVolume = 'sfx_volume';

  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  double _musicVolume = 0.65;
  double _sfxVolume = 0.85;

  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _applyAudioNow() {
    // Your PlanBSounds setters return void -> do NOT await.
    final musicVol = _musicEnabled ? _musicVolume : 0.0;
    final sfxVol = _sfxEnabled ? _sfxVolume : 0.0;

    PlanBSounds.instance.setMusicVolume(musicVol);
    PlanBSounds.instance.setSfxVolume(sfxVol);
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _musicEnabled = prefs.getBool(_kMusicEnabled) ?? true;
      _sfxEnabled = prefs.getBool(_kSfxEnabled) ?? true;
      _musicVolume = prefs.getDouble(_kMusicVolume) ?? 0.65;
      _sfxVolume = prefs.getDouble(_kSfxVolume) ?? 0.85;
      _loaded = true;
    });

    _applyAudioNow();
  }

  Future<void> _setMusicEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMusicEnabled, value);
    setState(() => _musicEnabled = value);
    _applyAudioNow();
  }

  Future<void> _setSfxEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSfxEnabled, value);
    setState(() => _sfxEnabled = value);
    _applyAudioNow();

    // Audible confirmation (you DO have this method)
    if (value) {
      await PlanBSounds.instance.debugTestTap();
    }
  }

  Future<void> _setMusicVolume(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kMusicVolume, value);
    setState(() => _musicVolume = value);
    _applyAudioNow();
  }

  Future<void> _setSfxVolume(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kSfxVolume, value);
    setState(() => _sfxVolume = value);
    _applyAudioNow();

    if (_sfxEnabled) {
      await PlanBSounds.instance.debugTestTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final ctrl = ThemeControllerScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Appearance', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),

                Card(
                  elevation: 0,
                  color: cs.surface,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Theme preset'),
                          subtitle: Text(
                            switch (ctrl.preset) {
                              ThemePreset.classic => 'Classic (original)',
                              ThemePreset.wood => 'Wood',
                              ThemePreset.blackWhite => 'Black & White',
                            },
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Classic'),
                              selected: ctrl.preset == ThemePreset.classic,
                              onSelected: (v) {
                                if (!v) return;
                                ctrl.setPreset(ThemePreset.classic);
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Wood'),
                              selected: ctrl.preset == ThemePreset.wood,
                              onSelected: (v) {
                                if (!v) return;
                                ctrl.setPreset(ThemePreset.wood);
                              },
                            ),
                            ChoiceChip(
                              label: const Text('B/W'),
                              selected: ctrl.preset == ThemePreset.blackWhite,
                              onSelected: (v) {
                                if (!v) return;
                                ctrl.setPreset(ThemePreset.blackWhite);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Theme mode'),
                          subtitle: const Text('System / Light / Dark'),
                          trailing: DropdownButton<ThemeMode>(
                            value: ctrl.mode,
                            onChanged: (m) {
                              if (m == null) return;
                              ctrl.setMode(m);
                            },
                            items: const [
                              DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                              DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                              DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Text('Audio', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),

                Card(
                  elevation: 0,
                  color: cs.surface,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Music'),
                          subtitle: const Text('Background music'),
                          value: _musicEnabled,
                          onChanged: _setMusicEnabled,
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Music volume'),
                          subtitle: Text('${(_musicVolume * 100).round()}%'),
                        ),
                        Slider(
                          value: _musicVolume,
                          min: 0,
                          max: 1,
                          onChanged: _musicEnabled ? (v) => _setMusicVolume(v) : null,
                        ),

                        const Divider(height: 1),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Sound effects'),
                          subtitle: const Text('Taps, moves, Plan B, win'),
                          value: _sfxEnabled,
                          onChanged: _setSfxEnabled,
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('SFX volume'),
                          subtitle: Text('${(_sfxVolume * 100).round()}%'),
                          trailing: IconButton(
                            tooltip: 'Test',
                            icon: const Icon(Icons.volume_up),
                            onPressed: _sfxEnabled ? () => PlanBSounds.instance.debugTestTap() : null,
                          ),
                        ),
                        Slider(
                          value: _sfxVolume,
                          min: 0,
                          max: 1,
                          onChanged: _sfxEnabled ? (v) => _setSfxVolume(v) : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}