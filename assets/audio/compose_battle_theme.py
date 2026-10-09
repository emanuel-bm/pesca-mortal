"""Original electronic battle loop: 160 BPM, 20 bars, exactly 30 seconds.
Requires NumPy. All instruments synthesized here, without external samples.
"""
from pathlib import Path
import wave
import numpy as np

RATE, BPM, BARS = 44100, 160, 20
BEAT = 60 / BPM
COUNT = RATE * 30
RNG = np.random.default_rng(960417)
buses = {name: np.zeros((COUNT, 2)) for name in ('drums', 'bass', 'synth', 'lead')}


def hz(note):
    return 440 * 2 ** ((note - 69) / 12)


def add(bus, signal, beat, gain, pan=0):
    # Note tails wrap into the start rather than getting truncated.
    indices = (round(beat * BEAT * RATE) + np.arange(len(signal))) % COUNT
    buses[bus][indices, 0] += signal * gain * np.sqrt((1 - pan) / 2)
    buses[bus][indices, 1] += signal * gain * np.sqrt((1 + pan) / 2)


def noise(n, low, high):
    spectrum = np.fft.rfft(RNG.normal(size=n))
    f = np.fft.rfftfreq(n, 1 / RATE)
    spectrum *= np.exp(-(f / high) ** 4) * (1 - np.exp(-(f / low) ** 4))
    signal = np.fft.irfft(spectrum, n)
    return signal / max(np.std(signal), 1e-6)


def envelope(t, duration, attack=.003, release=.025):
    return np.minimum(t / attack, 1) * np.clip((duration - t) / release, 0, 1)


def saw(t, f, harmonics=16):
    # Finite harmonic series prevents raw sawtooth aliasing.
    signal = np.zeros(len(t))
    for h in range(1, min(harmonics, int(9000 / f)) + 1):
        signal += np.sin(2 * np.pi * f * h * t) / h
    return signal * .6


def bass(note):
    duration = .40 * BEAT
    t = np.arange(round(duration * RATE)) / RATE
    f = hz(note)
    grit = np.tanh((saw(t, f, 12) + saw(t, f * 1.004, 8)) * 1.8) * .55
    sub = np.sin(2 * np.pi * f * t) * .65
    return (grit + sub) * envelope(t, duration, release=.02) * np.exp(-t * 1.8)


def lead(note, beats, bright=False):
    duration = beats * BEAT + .035
    t = np.arange(round(duration * RATE)) / RATE
    f = hz(note)
    signal = sum(saw(t, f * detune, 12) for detune in (.996, 1, 1.004)) / 3
    signal += .22 * np.sin(2 * np.pi * f * t + 1.1 * np.sin(2 * np.pi * f * 2 * t) * np.exp(-t * 12))
    if bright:
        signal += .15 * saw(t, f * 2, 6)
    return np.tanh(signal * 1.4) * envelope(t, duration, release=.045)


def arp(note):
    duration = BEAT * .23
    t = np.arange(round(duration * RATE)) / RATE
    f = hz(note)
    signal = np.sin(2 * np.pi * f * t + 2.5 * np.sin(2 * np.pi * f * 2 * t) * np.exp(-t * 28))
    return signal * np.exp(-t * 13) * envelope(t, duration, release=.015)


def chord(notes):
    duration = BEAT * .40
    t = np.arange(round(duration * RATE)) / RATE
    signal = sum(saw(t, hz(note), 8) for note in notes) / len(notes)
    return signal * np.exp(-t * 6) * envelope(t, duration)


def kick():
    duration = .28
    t = np.arange(round(duration * RATE)) / RATE
    phase = 2 * np.pi * (49 * t + 135 * .022 * (1 - np.exp(-t / .022)))
    signal = np.tanh(np.sin(phase) * 1.9) * np.exp(-t * 13)
    signal += noise(len(t), 1600, 6500) * np.exp(-t * 180) * .13
    return signal * envelope(t, duration, attack=.0008)


def snare():
    duration = .21
    t = np.arange(round(duration * RATE)) / RATE
    body = np.sin(2 * np.pi * 185 * t) * np.exp(-t * 30) * .40
    snap = noise(len(t), 900, 7800) * np.exp(-t * 23) * .40
    clap = noise(len(t), 1500, 6200) * sum(np.exp(-((t - p) / .004) ** 2) for p in (.012, .023, .036)) * .14
    return (body + snap + clap) * envelope(t, duration, attack=.001)


def hat(opened=False):
    duration = .15 if opened else .045
    t = np.arange(round(duration * RATE)) / RATE
    return noise(len(t), 6500, 12500) * np.exp(-t * (23 if opened else 80)) * envelope(t, duration, attack=.001, release=.01)


def crash():
    duration = .75
    t = np.arange(round(duration * RATE)) / RATE
    return noise(len(t), 3200, 11000) * np.exp(-t * 6) * envelope(t, duration, release=.08)


def compose():
    # E minor, with B major introducing a tense harmonic-minor turnaround.
    progression = [(40, [64, 67, 71]), (36, [60, 64, 67]),
                   (38, [62, 66, 69]), (35, [59, 63, 66])]
    hooks = [
        [(0, 76, .5), (.75, 76, .25), (1, 79, .5), (1.75, 78, .25), (2, 76, .5), (2.75, 74, .25), (3, 71, .75)],
        [(0, 72, .5), (.75, 76, .25), (1, 79, .5), (1.75, 76, .25), (2, 74, .5), (2.75, 72, .25), (3, 71, .5), (3.75, 72, .2)],
        [(0, 74, .5), (.75, 78, .25), (1, 81, .5), (1.75, 78, .25), (2, 79, .5), (2.75, 78, .25), (3, 74, .75)],
        [(0, 75, .5), (.75, 78, .25), (1, 83, .5), (1.75, 81, .25), (2, 78, .5), (2.75, 75, .25), (3, 71, .5), (3.75, 75, .2)],
    ]
    for bar in range(BARS):
        base = bar * 4
        root, notes = progression[bar % 4]
        for beat in range(4):
            add('drums', kick(), base + beat, .83)
        for beat in (1, 3):
            add('drums', snare(), base + beat, .70)
        for step in range(16):
            add('drums', hat(step % 4 == 2), base + step / 4,
                .080 if step % 2 else .11, .23 if step % 2 else -.23)
        if bar % 4 == 0:
            add('drums', crash(), base, .14, -.15)
        if bar in (7, 15, 19):
            for offset, gain in [(3.25, .20), (3.50, .27), (3.75, .38)]:
                add('drums', snare(), base + offset, gain, .10)
        for step in range(8):
            note = root + (12 if step in (3, 7) else 0)
            add('bass', bass(note), base + step * .5, .48 if step % 2 else .36)
        for offset in (.5, 1.5, 2.5, 3.5):
            add('synth', chord(notes), base + offset, .14, -.28)
        arpeggio = [notes[0] + 12, notes[2] + 12, notes[1] + 12, notes[2] + 24]
        for step in range(16):
            add('synth', arp(arpeggio[step % 4]), base + step * .25,
                .075 if bar < 8 else .095, .42 if step % 2 else -.42)
        for offset, note, beats in hooks[bar % 4]:
            add('lead', lead(note, beats, bright=bar >= 8), base + offset, .25, .06)
            if 8 <= bar < 16 and offset in (0, 2):
                add('lead', lead(note + 12, .2), base + offset, .065, -.24)
        if bar >= 16:
            for step in range(8):
                add('synth', arp(notes[step % 3] + 24), base + step * .5 + .25, .07, .3)
    # Circular melodic echoes; dry centered drums and bass retain their punch.
    dry = buses['lead'].copy()
    for beats, gain in [(.75, .16), (1.5, .07)]:
        buses['lead'] += np.roll(dry[:, ::-1], round(beats * BEAT * RATE), axis=0) * gain
    phase = (np.arange(COUNT) / RATE) % BEAT
    # A short attack avoids a discontinuous gain jump at each kick/loop edge.
    duck = 1 - .65 * np.exp(-phase / .060) * (1 - np.exp(-phase / .0015))
    for bus in ('bass', 'synth', 'lead'):
        buses[bus] *= duck[:, None]
    mix = sum(buses.values())
    mix -= mix.mean(axis=0)
    mix = np.tanh(mix * 1.35)
    mix *= .87 / np.max(np.abs(mix))
    pcm = np.rint(mix * 32767).astype('<i2')
    seam = np.max(np.abs(mix[0] - mix[-1]))
    assert COUNT == BARS * 4 * BEAT * RATE
    assert seam < .015, f'Unexpected loop discontinuity: {seam}'
    assert np.max(np.abs(pcm.astype(np.int32))) < 32767
    output = Path(__file__).with_name('correnteza_em_furia.wav')
    with wave.open(str(output), 'wb') as audio:
        audio.setnchannels(2)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        audio.writeframes(pcm.tobytes())
    rms = np.sqrt(np.mean(mix ** 2))
    print(f'{output.name}: 30s, {BPM} BPM, {BARS} bars, stereo PCM16/{RATE}Hz')
    print(f'Peak: {20*np.log10(.87):.2f} dBFS; RMS: {20*np.log10(rms):.2f} dBFS; seam delta: {seam:.6f}')


if __name__ == '__main__':
    compose()
