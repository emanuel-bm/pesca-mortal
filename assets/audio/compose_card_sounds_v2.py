"""V2: one-second card activation sounds; original WAVs remain untouched. No samples; deterministic NumPy synthesis."""
from pathlib import Path
import wave
import numpy as np

RATE = 44100
ROOT = Path(__file__).parent
rng = np.random.default_rng(20261009)


def air(t, low, high):
    frequencies = np.fft.rfftfreq(len(t), 1 / RATE)
    shape = (1 - np.exp(-(frequencies / low) ** 4)) * np.exp(-(frequencies / high) ** 4)
    signal = np.fft.irfft(np.fft.rfft(rng.normal(size=len(t))) * shape, len(t))
    return signal / max(np.std(signal), 1e-9)


def tone(t, frequency):
    return np.sin(2 * np.pi * np.cumsum(np.broadcast_to(frequency, t.shape)) / (RATE * TIME_SCALE))


def save(name, signal):
    # Smooth edges and leave headroom for simultaneous game sounds.
    fade = min(int(RATE * .025), len(signal) // 2)
    signal[:fade] *= np.linspace(0, 1, fade)
    signal[-fade:] *= np.linspace(1, 0, fade)
    signal *= .8 / max(np.max(np.abs(signal)), 1e-9)
    assert np.isfinite(signal).all()
    pcm = (signal * 32767).astype('<i2')
    with wave.open(str(ROOT / f'card_{name}_v2.wav'), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm.tobytes())
    print(f'{name}: {len(signal)/RATE:.2f}s, peak {np.max(np.abs(signal)):.2f}')
    return signal


# Magnetic pull: rising metallic vibration, then a small resonant latch.
TIME_SCALE = 1.3
t = np.arange(RATE) / RATE * TIME_SCALE
pull = np.sin(np.pi * np.clip(t / 1.0, 0, 1)) ** 1.2
signal = pull * (.2 * air(t, 400, 2400) + .45 * tone(t, 240 + 650 * t))
for frequency, gain in [(760, .6), (1210, .3), (1930, .16)]:
    elapsed = np.maximum(t - .92, 0)
    signal += (t >= .92) * gain * np.exp(-elapsed * 12) * tone(t, frequency)
save('ima', signal)

# Fury: restrained beginning, accelerating rumble and breath over 1.8 seconds.
TIME_SCALE = 1.8
t = np.arange(RATE) / RATE * TIME_SCALE
growth = (.025 + (t / 1.8) ** 1.7) * np.clip((1.8 - t) / .22, 0, 1)
pulse = .7 + .3 * tone(t, 4 + 5 * t)
signal = growth * pulse * (.45 * air(t, 90, 1700) + .35 * tone(t, 85 + 75 * t) + .12 * tone(t, 170 + 150 * t))
signal = save('furia', signal)
assert np.sqrt(np.mean(signal[int(RATE*.56):int(RATE*.83)] ** 2)) > 3 * np.sqrt(np.mean(signal[:int(RATE*.22)] ** 2)), 'Fury must grow gradually'

# Scale shield: hollow crystalline resonance, gently spreading harmonics.
TIME_SCALE = 1.6
t = np.arange(RATE) / RATE * TIME_SCALE
signal = np.zeros_like(t)
for frequency, gain, delay in [(420, .5, 0), (630, .32, .07), (1010, .2, .13), (1510, .1, .2)]:
    elapsed = np.maximum(t - delay, 0)
    envelope = (t >= delay) * (1 - np.exp(-elapsed * 70)) * np.exp(-elapsed * 3.5)
    signal += gain * envelope * tone(t, frequency + 3 * np.sin(t * 14))
signal += .06 * air(t, 500, 3500) * np.sin(np.pi * t / 1.6) ** 2
save('intangivel', signal)

# Piercing spear: sharp air cut, followed by a metallic shaft resonance.
TIME_SCALE = 1.1
t = np.arange(RATE) / RATE * TIME_SCALE
signal = .55 * air(t, 700, 6500) * np.exp(-((t - .18) / .1) ** 2)
elapsed = np.maximum(t - .25, 0)
for frequency, gain in [(310, .3), (930, .12), (1720, .06)]:
    signal += (t >= .25) * gain * (1 - np.exp(-elapsed * 100)) * np.exp(-elapsed * 6) * tone(t, frequency)
signal += .06 * air(t, 300, 2200) * np.sin(np.pi * t / 1.1) ** 2
save('perfurante', signal)
