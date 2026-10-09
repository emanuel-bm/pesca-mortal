"""Original creature sounds: 2s roar, 0.7s emergence, 0.5s dash.
Python + NumPy, no samples or soundfonts. Run to regenerate all three WAVs.
"""
from pathlib import Path
import wave
import numpy as np

RATE = 44100


def noise(rng, count, low, high, resonances=()):
    frequencies = np.fft.rfftfreq(count, 1 / RATE)
    shape = (1 - np.exp(-(frequencies / low) ** 4)) * np.exp(-(frequencies / high) ** 4)
    for center, width, strength in resonances:
        shape *= 1 + strength * np.exp(-((frequencies - center) / width) ** 2)
    signal = np.fft.irfft(np.fft.rfft(rng.normal(size=count)) * shape, count)
    return signal / np.std(signal)


def save(name, signal, attack, release):
    t = np.arange(len(signal)) / RATE
    duration = len(signal) / RATE
    signal = signal - np.mean(signal)
    signal = np.tanh(signal * 1.2)
    signal *= np.minimum(t / attack, 1) * np.clip((duration - t) / release, 0, 1) ** 1.5
    signal *= .89 / np.max(np.abs(signal))
    pcm = np.rint(signal * 32767).astype('<i2')
    assert abs(int(pcm[0])) <= 1 and abs(int(pcm[-1])) <= 1
    with wave.open(str(Path(__file__).with_name(name)), 'wb') as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        audio.writeframes(pcm.tobytes())
    print(f'{name}: {duration:.3f}s, mono PCM16/{RATE}Hz, peak -1.01 dBFS')


def compose_roar():
    rng = np.random.default_rng(731960)
    t = np.arange(RATE * 2) / RATE
    # A forceful open-throat roar: rises rapidly, sustains, then breaks into growls.
    drift = np.interp(t, np.linspace(0, 2, 95), rng.uniform(-7, 7, 95))
    f0 = 74 + 31 * np.exp(-((t - .36) / .40) ** 2) - 20 * (t / 2)
    f0 += drift + 3 * np.sin(2 * np.pi * 23 * t)
    phase = 2 * np.pi * np.cumsum(f0) / RATE
    throat = np.zeros(len(t))
    for harmonic in range(1, 45):
        # Broad moving formants suggest a mouth/throat rather than a fixed synth.
        f = f0 * harmonic
        vowel = .22 + 3.2 * np.exp(-((f - (430 - 80 * t)) / 170) ** 2)
        vowel += 2.1 * np.exp(-((f - (1050 - 130 * t)) / 300) ** 2)
        jitter = .25 * np.sin(2 * np.pi * (9 + harmonic * .37) * t)
        throat += np.sin(phase * harmonic + jitter) * vowel / harmonic ** 1.15
    throat += .50 * np.sin(phase / 2) + .16 * np.sin(phase / 3)
    throat = np.tanh(throat * 1.6)
    rasp = noise(rng, len(t), 80, 2800, [(390, 180, 2), (950, 320, 1.5)])
    rasp *= .35 + .65 * np.sin(phase / 2) ** 2
    pulse = .78 + .14 * np.sin(2 * np.pi * 16 * t) + .08 * np.sin(2 * np.pi * 29 * t)
    body = (throat * .75 + rasp * .28) * pulse
    contour = (1 - np.exp(-t * 35)) * np.exp(-t * .55)
    contour *= 1 + .24 * np.exp(-((t - .55) / .4) ** 2)
    # A second guttural push before the release, with little high-frequency hiss.
    contour += .16 * np.exp(-((t - 1.35) / .23) ** 2)
    breath = noise(rng, len(t), 1700, 5200) * .025 * np.exp(-((t - .75) / .5) ** 2)
    dry = body * contour + breath
    signal = dry.copy()
    for delay, gain in [(.047, .16), (.094, .09), (.151, .045)]:
        shift = round(delay * RATE)
        signal[shift:] += dry[:-shift] * gain
    save('minhocao_roar.wav', signal, .008, .30)


def compose_emergence():
    rng = np.random.default_rng(310417)
    t = np.arange(round(RATE * .7)) / RATE
    rubble = noise(rng, len(t), 60, 1600, [(240, 160, 1.8)])
    splash = noise(rng, len(t), 350, 6500)
    impact = np.sin(2 * np.pi * (43 * t + 25 * .035 * (1 - np.exp(-t / .035))))
    cracks = np.zeros(len(t))
    for time, width, gain in [(.025, .009, .32), (.055, .012, .25), (.12, .018, .17)]:
        cracks += splash * gain * np.exp(-((t - time) / width) ** 2)
    signal = impact * .55 * np.exp(-t * 9) + rubble * .38 * np.exp(-t * 6)
    signal += splash * .16 * np.exp(-((t - .09) / .075) ** 2) + cracks
    save('minhocao_emerge.wav', signal, .003, .16)


def compose_dash():
    rng = np.random.default_rng(940417)
    t = np.arange(round(RATE * .5)) / RATE
    air = noise(rng, len(t), 140, 5000)
    weight = noise(rng, len(t), 35, 650)
    sweep = np.exp(-((t - .13) / .09) ** 2)
    wake = np.exp(-((t - .24) / .13) ** 2)
    signal = air * (.36 * sweep + .12 * wake) + weight * .42 * sweep
    signal += np.sin(2 * np.pi * 52 * t) * .22 * sweep
    save('minhocao_dash.wav', signal, .006, .12)


if __name__ == '__main__':
    compose_roar()
    compose_emergence()
    compose_dash()
