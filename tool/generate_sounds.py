"""Sonneries de Bois & Vis : des gouttes d'eau (« bloup ») et un petit carillon.

- bois_doux : ~2 s, pour le mode « Doux ».
- bois_fort : ~8 s, le même motif répété et plus fort, pour le mode « Fort ».

Android lit les .wav de res/raw, iOS les .aiff du dossier Runner.

Lancer : python3 tool/generate_sounds.py (Python seul, sans dépendance).
"""
import aifc
import array
import math
import os
import wave

RATE = 44100
_ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
OUT = os.path.join(_ROOT, 'android', 'app', 'src', 'main', 'res', 'raw')
IOS_OUT = os.path.join(_ROOT, 'ios', 'Runner')


def silence(seconds):
    return [0.0] * int(RATE * seconds)


def mix(track, sound, at):
    start = int(RATE * at)
    if len(track) < start + len(sound):
        track.extend([0.0] * (start + len(sound) - len(track)))
    for i, v in enumerate(sound):
        track[start + i] += v


def drop(low=380, high=1300, length=0.14, volume=0.8):
    """« Bloup » : une note qui monte très vite et s'éteint."""
    n = int(RATE * length)
    out, phase = [], 0.0
    for i in range(n):
        t = i / n
        freq = low + (high - low) * (1 - (1 - t) ** 3)
        phase += 2 * math.pi * freq / RATE
        env = math.sin(math.pi * min(t * 6, 1) / 2) * math.exp(-5 * t)
        out.append(volume * env * math.sin(phase))
    return out


def bell(freq, length=0.9, volume=0.5):
    """Note de carillon (marimba) avec deux harmoniques."""
    n = int(RATE * length)
    out = []
    for i in range(n):
        t = i / RATE
        attack = min(t / 0.005, 1)
        v = (math.sin(2 * math.pi * freq * t) * math.exp(-4 * t)
             + 0.35 * math.sin(2 * math.pi * freq * 2.76 * t) * math.exp(-9 * t)
             + 0.15 * math.sin(2 * math.pi * freq * 5.4 * t) * math.exp(-14 * t))
        out.append(volume * attack * v)
    return out


C6, E6, G6, C7 = 1046.5, 1318.5, 1568.0, 2093.0


def motif(track, at, volume=1.0):
    # Trois gouttes qui tombent dans le verre…
    mix(track, drop(360, 1100, volume=0.7 * volume), at)
    mix(track, drop(420, 1300, volume=0.7 * volume), at + 0.17)
    mix(track, drop(500, 1550, volume=0.8 * volume), at + 0.34)
    # … puis le carillon joyeux : do-mi-sol-do.
    for k, note in enumerate([C6, E6, G6, C7]):
        mix(track, bell(note, volume=0.45 * volume), at + 0.6 + k * 0.13)


def save(name, track):
    peak = max(abs(v) for v in track) or 1
    gain = 0.9 / peak
    fade = int(RATE * 0.05)
    samples = array.array('h')
    for i, v in enumerate(track):
        if i > len(track) - fade:
            v *= (len(track) - i) / fade
        samples.append(int(max(-1, min(1, v * gain)) * 32767))
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, f'{name}.wav'), 'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(samples.tobytes())
    # AIFF : même son, en gros-boutiste.
    samples.byteswap()
    with aifc.open(os.path.join(IOS_OUT, f'{name}.aiff'), 'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(samples.tobytes())


if __name__ == '__main__':
    doux = silence(0.05)
    motif(doux, 0.05)
    save('bois_doux', doux + silence(0.2))

    fort = silence(0.05)
    for r in range(4):
        motif(fort, 0.05 + r * 1.9, volume=1.0 if r % 2 == 0 else 0.85)
    save('bois_fort', fort + silence(0.2))
    print('ok')
