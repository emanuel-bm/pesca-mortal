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


def save(name, signal, attack, release, lowpass=None):
    t = np.arange(len(signal)) / RATE
    duration = len(signal) / RATE
    signal = signal - np.mean(signal)
    signal = np.tanh(signal * 1.2)
    if lowpass is not None:
        frequencies = np.fft.rfftfreq(len(signal), 1 / RATE)
        rolloff = 1 / np.sqrt(1 + (frequencies / lowpass) ** 8)
        signal = np.fft.irfft(np.fft.rfft(signal) * rolloff, len(signal))
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
    # Kaiju-like cry: a torn metallic howl, with a less piercing upper register.
    # This is an original sound; no film recording or sampled roar is used.
    drift = np.interp(t, np.linspace(0, 2, 125), rng.uniform(-14, 14, 125))
    f0 = np.interp(t, [0, .06, .26, .80, 1.30, 1.65, 2],
                   [160, 340, 460, 390, 310, 185, 100])
    f0 += drift + 8 * np.sin(2 * np.pi * 27 * t) + 4 * np.sin(2 * np.pi * 43 * t)
    f0 *= .80  # Lower the previous cry by about four semitones, keeping its shape.
    phase = 2 * np.pi * np.cumsum(f0) / RATE
    throat = np.zeros(len(t))
    for harmonic in range(1, 20):
        # Bright mouth resonances and detuning give the cry size and roughness.
        f = f0 * harmonic
        vowel = .35 + 2.4 * np.exp(-((f - (950 - 140 * t)) / 420) ** 2)
        vowel += 1.6 * np.exp(-((f - (2050 - 280 * t)) / 650) ** 2)
        jitter = .40 * np.sin(2 * np.pi * (17 + harmonic * .47) * t)
        voice = np.sin(phase * harmonic + jitter)
        voice += .28 * np.sin(phase * harmonic * 1.017 - jitter)
        throat += voice * vowel / harmonic ** 1.10
    throat += .20 * np.sin(phase / 2)
    throat = np.tanh(throat * 1.3)
    # Inharmonic friction evokes a giant strained/bowed vocal cord.
    metal = sum(np.sin(phase * ratio + .8 * np.sin(phase / 7)) * gain
                for ratio, gain in [(1.49, .20), (2.07, .12), (2.83, .06)])
    rasp = noise(rng, len(t), 280, 4800, [(1400, 600, 2)])
    rasp *= .25 + .75 * np.sin(phase / 2) ** 2
    pulse = .74 + .17 * np.sin(2 * np.pi * 31 * t) + .09 * np.sin(2 * np.pi * 47 * t)
    body = (throat * .70 + metal + rasp * .24) * pulse
    contour = (1 - np.exp(-t * 45)) * np.exp(-t * .36)
    contour *= 1 + .30 * np.exp(-((t - .48) / .32) ** 2)
    contour += .12 * np.exp(-((t - 1.35) / .20) ** 2)
    dry = body * contour
    signal = dry.copy()
    for delay, gain in [(.047, .16), (.094, .09), (.151, .045)]:
        shift = round(delay * RATE)
        signal[shift:] += dry[:-shift] * gain
    save('minhocao_roar.wav', signal, .008, .30, lowpass=3800)


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
