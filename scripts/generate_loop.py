#!/usr/bin/env python3
import wave
import struct
import math
import os

SR = 44100
DURATION = 8.0
FREQS = [220.0, 440.0, 660.0]
AMPLITUDE = 0.6
OUT_PATH = 'assets/audio/music'
OUT_FILE = os.path.join(OUT_PATH, 'background.wav')

os.makedirs(OUT_PATH, exist_ok=True)

num_samples = int(SR * DURATION)
fade_len = int(SR * 0.01)  # 10ms fade to avoid clicks

with wave.open(OUT_FILE, 'w') as wf:
    wf.setnchannels(1)
    wf.setsampwidth(2)  # 16-bit
    wf.setframerate(SR)

    for i in range(num_samples):
        t = i / SR
        sample = 0.0
        for k, f in enumerate(FREQS):
            # decreasing amplitude for higher harmonics
            sample += math.sin(2 * math.pi * f * t) * (0.5 / (k + 1))

        # short fade-in/out to avoid clicks
        if i < fade_len:
            env = i / float(fade_len)
        elif i > num_samples - fade_len:
            env = (num_samples - i) / float(fade_len)
        else:
            env = 1.0

        sample *= env * AMPLITUDE
        # clamp
        val = int(max(-32767, min(32767, int(sample * 32767))))
        wf.writeframes(struct.pack('<h', val))

print(f'Generated {OUT_FILE} ({DURATION}s, {SR}Hz)')
