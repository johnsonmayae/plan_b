// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';
import '../audio/planb_sounds.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  double _musicVolume = 0.35;
  double _sfxVolume = 0.85;
  ThemePreset _preset = ThemePreset.classic;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();

    final s = PlanBSounds.instance;
    _musicEnabled = s.musicEnabled.value;
    _sfxEnabled = s.sfxEnabled.value;
    _musicVolume = s.musicVolume.value;
    _sfxVolume = s.sfxVolume.value;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe to read inherited widgets here.
    final ctrl = ThemeControllerScope.of(context);
    _preset = ctrl.preset;
    _themeMode = ctrl.mode;
  }

  Future<void> _applySound() async {
    final s = PlanBSounds.instance;
    await s.setMusicEnabled(_musicEnabled);
    await s.setSfxEnabled(_sfxEnabled);
    await s.setMusicVolume(_musicVolume);
    await s.setSfxVolume(_sfxVolume);
  }

  void _applyTheme(ThemePreset preset) {
    final ctrl = ThemeControllerScope.of(context);
    ctrl.setPreset(preset);
  }

  void _applyThemeMode(ThemeMode mode) {
    final ctrl = ThemeControllerScope.of(context);
    ctrl.setMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Appearance', style: text.titleMedium),
          const SizedBox(height: 8),

          // Light/Dark Mode toggle
          ListTile(
            title: const Text('Theme Mode'),
            subtitle: Text(_themeModeLabel(_themeMode)),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode, size: 16),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto, size: 16),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode, size: 16),
                ),
              ],
              selected: {_themeMode},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                setState(() => _themeMode = newSelection.first);
                _applyThemeMode(newSelection.first);
              },
            ),
          ),

          const Divider(height: 24),

          Text('Color Theme', style: text.titleMedium),
          const SizedBox(height: 8),

          RadioListTile<ThemePreset>(
            value: ThemePreset.classic,
            groupValue: _preset,
            title: const Text('Classic'),
            subtitle: const Text('Blue & Orange'),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _preset = v);
              _applyTheme(v);
            },
          ),
          RadioListTile<ThemePreset>(
            value: ThemePreset.wood,
            groupValue: _preset,
            title: const Text('Wood'),
            subtitle: const Text('Warm tones'),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _preset = v);
              _applyTheme(v);
            },
          ),
          RadioListTile<ThemePreset>(
            value: ThemePreset.blackWhite,
            groupValue: _preset,
            title: const Text('Black & White'),
            subtitle: const Text('Monochrome'),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _preset = v);
              _applyTheme(v);
            },
          ),

          const Divider(height: 32),

          Text('Sound', style: text.titleMedium),
          const SizedBox(height: 8),

          SwitchListTile(
            title: const Text('Music'),
            value: _musicEnabled,
            onChanged: (value) async {
              setState(() => _musicEnabled = value);
              await PlanBSounds.instance.setMusicEnabled(value);
            },
          ),
          Slider(
            value: _musicVolume,
            onChanged: (v) => setState(() => _musicVolume = v),
            onChangeEnd: (v) async {
              await PlanBSounds.instance.setMusicVolume(v);
            },
          ),

          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text('Sound effects'),
            value: _sfxEnabled,
            onChanged: (value) async {
              setState(() => _sfxEnabled = value);
              await PlanBSounds.instance.setSfxEnabled(value);
              // feedback
              if (value) PlanBSounds.instance.tap();
            },
          ),
          Slider(
            value: _sfxVolume,
            onChanged: (v) => setState(() => _sfxVolume = v),
            onChangeEnd: (v) async {
              await PlanBSounds.instance.setSfxVolume(v);
              PlanBSounds.instance.tap();
            },
          ),

          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              await _applySound();
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}