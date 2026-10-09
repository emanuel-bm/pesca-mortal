"""Original one-second giant-serpent roar, synthesized without external samples.
Run with Python + NumPy to regenerate minhocao_roar.wav.
"""
from pathlib import Path
import wave
import numpy as np

RATE = 44100
RNG = np.random.default_rng(731417)
t = np.arange(RATE) / RATE


def textured_noise(low, high, resonances=()):
    f = np.fft.rfftfreq(RATE, 1 / RATE)
    shape = (1 - np.exp(-(f / low) ** 4)) * np.exp(-(f / high) ** 4)
    for center, width, strength in resonances:
        shape *= 1 + strength * np.exp(-((f - center) / width) ** 2)
    signal = np.fft.irfft(np.fft.rfft(RNG.normal(size=RATE)) * shape, RATE)
    return signal / np.std(signal)


def compose():
    # A large, uneven throat: low fundamental, subharmonics and vocal resonances.
    drift = np.interp(t, np.linspace(0, 1, 36), RNG.uniform(-3, 3, 36))
    f0 = 48 + 17 * np.exp(-((t - .16) / .19) ** 2) + drift
    f0 += 2.0 * np.sin(2 * np.pi * 19 * t) + 1.3 * np.sin(2 * np.pi * 31 * t)
    phase = 2 * np.pi * np.cumsum(f0) / RATE
    throat = np.zeros(RATE)
    for h in range(1, 27):
        f = h * 55
        resonance = .35 + 1.8 * np.exp(-((f - 260) / 110) ** 2)
        resonance += 1.5 * np.exp(-((f - 680) / 210) ** 2)
        throat += np.sin(phase * h + .16 * np.sin(2 * np.pi * (11 + h) * t)) * resonance / h
    throat += .55 * np.sin(phase / 2)
    throat = np.tanh(throat * 1.7)
    rasp = textured_noise(110, 2100, [(320, 130, 2), (850, 250, 1.5)])
    rasp *= .45 + .55 * np.sin(phase / 2) ** 2
    flutter = .78 + .15 * np.sin(2 * np.pi * 17 * t) + .07 * np.sin(2 * np.pi * 29 * t)
    body = (throat * .65 + rasp * .23) * flutter
    body *= np.exp(-t * 1.6) * (1 + .35 * np.exp(-((t - .22) / .17) ** 2))
    # Breath and disturbed water make it a river creature rather than a synth hit.
    hiss = textured_noise(1800, 8500) * .085 * np.exp(-((t - .40) / .28) ** 2)
    water = textured_noise(100, 2500) * .19 * np.exp(-((t - .07) / .065) ** 2)
    sub = np.sin(2 * np.pi * 39 * t) * .30 * np.exp(-t * 8)
    dry = body + hiss + water + sub
    # Short chamber reflections remain inside the one-second asset.
    signal = dry.copy()
    for delay, gain in [(.037, .13), (.073, .08)]:
        shift = round(delay * RATE)
        signal[shift:] += dry[:-shift] * gain
    signal -= signal.mean()
    signal = np.tanh(signal * 1.2)
    signal *= np.minimum(t / .012, 1) * np.clip((1 - t) / .18, 0, 1) ** 1.5
    signal *= .89 / np.max(np.abs(signal))
    pcm = np.rint(signal * 32767).astype('<i2')
    assert len(pcm) == RATE and abs(int(pcm[0])) <= 1 and abs(int(pcm[-1])) <= 1
    output = Path(__file__).with_name('minhocao_roar.wav')
    with wave.open(str(output), 'wb') as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        audio.writeframes(pcm.tobytes())
    print(f'{output.name}: 1.000s, mono PCM16/{RATE}Hz, peak {20*np.log10(.89):.2f} dBFS')


if __name__ == '__main__':
    compose()
