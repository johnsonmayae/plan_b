import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../audio/planb_sounds.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _sfxVolume = 1.0;
  bool _sfxMuted = false;
  double _musicVolume = 1.0;
  bool _musicMuted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sfxVolume = prefs.getDouble('sfx_volume') ?? PlanBSounds.instance.sfxVolume.value;
      _sfxMuted = prefs.getBool('sfx_muted') ?? PlanBSounds.instance.muted.value;
      _musicVolume = prefs.getDouble('music_volume') ?? 1.0;
      _musicMuted = prefs.getBool('music_muted') ?? false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sfx_volume', _sfxVolume);
    await prefs.setBool('sfx_muted', _sfxMuted);
    await prefs.setDouble('music_volume', _musicVolume);
    await prefs.setBool('music_muted', _musicMuted);
  }

  void _applySfx() {
    PlanBSounds.instance.setSfxVolume(_sfxVolume);
    PlanBSounds.instance.setMuted(_sfxMuted);
    // Apply music settings as well
    PlanBSounds.instance.setMusicVolume(_musicVolume);
    PlanBSounds.instance.setMusicMuted(_musicMuted);
    // If music is unmuted and not playing, attempt to start background music.
    if (!_musicMuted) {
      PlanBSounds.instance.ensureMusicPlaying('audio/music/background.mp3');
    } else {
      PlanBSounds.instance.stopMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sound Effects', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Mute'),
                const SizedBox(width: 12),
                Switch(
                  value: _sfxMuted,
                  onChanged: (v) async {
                    setState(() => _sfxMuted = v);
                    _applySfx();
                    await _save();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Volume'),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _sfxVolume,
                    onChanged: (v) async {
                      setState(() => _sfxVolume = v);
                      _applySfx();
                      await _save();
                    },
                    min: 0,
                    max: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text('Music (placeholder)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Mute'),
                const SizedBox(width: 12),
                Switch(
                  value: _musicMuted,
                  onChanged: (v) async {
                    setState(() => _musicMuted = v);
                    await _save();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Volume'),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _musicVolume,
                    onChanged: (v) async {
                      setState(() => _musicVolume = v);
                      await _save();
                    },
                    min: 0,
                    max: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _applySfx();
                _save();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
