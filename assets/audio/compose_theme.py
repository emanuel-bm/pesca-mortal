"""Compose 'Correnteza sombria': original 30-second, sample-exact loop.

Requires numpy. Run this file to regenerate the stereo PCM16 WAV.
All instruments are synthesized here; no recordings or soundfonts are used.
"""
from pathlib import Path
import wave

import numpy as np

RATE = 44100
BPM = 128
BEAT = 60 / BPM
SECONDS = 30
COUNT = RATE * SECONDS
RNG = np.random.default_rng(417)
mix = np.zeros((COUNT, 2), dtype=np.float64)


def hz(midi):
    return 440 * 2 ** ((midi - 69) / 12)


def add(signal, beat, gain, pan=0):
    """Wrap note tails across the loop instead of cutting them off."""
    start = round(beat * BEAT * RATE)
    indices = (start + np.arange(len(signal))) % COUNT
    mix[indices, 0] += signal * gain * np.sqrt((1 - pan) / 2)
    mix[indices, 1] += signal * gain * np.sqrt((1 + pan) / 2)


def noise(n, low, high):
    spectrum = np.fft.rfft(RNG.normal(size=n))
    frequencies = np.fft.rfftfreq(n, 1 / RATE)
    spectrum *= np.exp(-(frequencies / high) ** 4)
    spectrum *= 1 - np.exp(-(frequencies / low) ** 4)
    signal = np.fft.irfft(spectrum, n)
    return signal / max(np.std(signal), 1e-6)


def pluck(note, duration=1.15, bass=False):
    t = np.arange(round(duration * RATE)) / RATE
    frequency = hz(note)
    signal = np.zeros(len(t))
    # Slightly detuned pairs suggest the double courses of a viola.
    for harmonic in range(1, 9):
        amplitude = 0.68 / harmonic ** 1.55
        decay = (3.0 if bass else 4.2) + harmonic * 0.8
        for detune in (0.9986, 1.0014):
            signal += amplitude * np.sin(2 * np.pi * frequency * harmonic * detune * t) * np.exp(-t * decay)
    signal += noise(len(t), 800, 3800) * np.exp(-t * 120) * 0.035
    signal *= np.minimum(t / 0.003, 1) * np.minimum((duration - t) / 0.04, 1)
    return signal


def flute(note, beats):
    duration = beats * BEAT
    t = np.arange(round((duration + 0.16) * RATE)) / RATE
    phase = 2 * np.pi * hz(note) * t + 0.025 * np.sin(2 * np.pi * 4.6 * t)
    signal = np.sin(phase) + 0.16 * np.sin(phase * 2) + 0.045 * np.sin(phase * 3)
    envelope = (1 - np.exp(-t * 35)) * np.exp(-t * 0.45)
    envelope *= np.minimum(np.maximum((duration + 0.16 - t) / 0.20, 0), 1)
    signal += noise(len(t), 1100, 4500) * 0.025
    return signal * envelope


def drum(accent=False):
    t = np.arange(round(0.32 * RATE)) / RATE
    phase = 2 * np.pi * (63 * t + 30 * 0.025 * (1 - np.exp(-t / 0.025)))
    signal = np.sin(phase) * np.exp(-t * 18)
    signal += noise(len(t), 130, 1000) * np.exp(-t * 55) * (0.18 if accent else 0.08)
    return signal * np.minimum(t / 0.002, 1) * np.minimum((0.32 - t) / 0.025, 1)


def wood(note):
    t = np.arange(round(0.12 * RATE)) / RATE
    signal = np.sin(2 * np.pi * note * t) + 0.45 * np.sin(2 * np.pi * note * 1.47 * t)
    return signal * np.exp(-t * 65) * np.minimum(t / 0.001, 1) * np.minimum((0.12 - t) / 0.02, 1)


def shaker():
    t = np.arange(round(0.10 * RATE)) / RATE
    return noise(len(t), 4500, 9500) * np.minimum(t / 0.012, 1) * np.exp(-t * 55) * np.minimum((0.10 - t) / 0.02, 1)


def pad(notes):
    duration = 4 * BEAT + 0.55
    t = np.arange(round(duration * RATE)) / RATE
    signal = np.zeros(len(t))
    for note in notes:
        phase = 2 * np.pi * hz(note) * t
        signal += np.sin(phase + 0.08 * np.sin(2 * np.pi * 0.7 * t)) + 0.12 * np.sin(2 * phase)
    envelope = np.minimum(t / 0.4, 1) * np.minimum((duration - t) / 0.65, 1)
    return signal * envelope / len(notes)


def compose():
    # Dm(add9), C(add9), G6, Dm: minor tonic with a Dorian lift.
    chords = [(38, [62, 65, 69, 76]), (36, [60, 64, 67, 74]),
              (43, [59, 62, 67, 76]), (38, [62, 65, 69, 74])]
    # A restrained eight-bar melody; rests leave room for combat effects.
    melody = [
        [(0, 74, 0.75), (1.5, 77, 0.5), (2.5, 76, 0.75)],
        [(0.5, 74, 1.0), (2.5, 69, 0.75)],
        [(0, 72, 0.75), (1.5, 76, 0.5), (2.5, 74, 0.75)],
        [(0.5, 72, 1.0), (2.5, 67, 0.75)],
        [(0, 71, 0.75), (1.5, 74, 0.5), (2.5, 76, 0.75)],
        [(0.5, 74, 1.0), (2.5, 71, 0.75)],
        [(0, 69, 0.75), (1.5, 72, 0.5), (2.5, 74, 0.75)],
        [(0, 77, 0.75), (1.5, 76, 0.5), (2.5, 69, 0.75)],
    ]
    for bar in range(16):
        root, notes = chords[(bar // 2) % 4]
        base = bar * 4
        add(pad(notes[:3]), base, 0.065, -0.15)
        for offset, note in [(0, root), (1.75, root + 12), (2.5, root + 7)]:
            add(pluck(note, 1.3, bass=True), base + offset, 0.20, 0)
        pattern = [(0, 0), (0.75, 2), (1.5, 1), (2, 2), (2.75, 3), (3.5, 1)]
        for offset, index in pattern:
            add(pluck(notes[index]), base + offset + 0.018, 0.095 if index != 3 else 0.075, -0.38)
        # Quiet answering plucks on the right create space without busy melody.
        for offset, index in [(1.0, 1), (3.0, 2)]:
            add(pluck(notes[index] + 12, 0.65), base + offset, 0.026, 0.45)
        for offset in (0, 2):
            add(drum(), base + offset, 0.24)
        add(drum(True), base + 3.5, 0.10)
        for offset in (0.75, 1.5, 2.75, 3.25):
            add(wood(620 if offset in (1.5, 3.25) else 470), base + offset, 0.062, 0.23)
        for step in range(8):
            add(shaker(), base + step * 0.5 + (0.025 if step % 2 else 0),
                0.013 if step % 2 else 0.008, 0.50)
        for offset, note, beats in melody[bar % 8]:
            # The second phrase changes only one note: subtle variation in a loop.
            if bar == 11 and note == 67:
                note = 69
            add(flute(note, beats), base + offset, 0.085, 0.15)

    # Circular stereo echoes retain the reverb/delay tails at the loop boundary.
    dry = mix.copy()
    for delay, gain in [(BEAT * 0.75, 0.13), (BEAT * 1.5, 0.065), (0.071, 0.045)]:
        mix[:] += np.roll(dry[:, ::-1], round(delay * RATE), axis=0) * gain
    mix[:] -= mix.mean(axis=0)
    mix[:] = np.tanh(mix * 1.15)
    mix[:] *= 0.78 / np.max(np.abs(mix))
    pcm = np.rint(mix * 32767).astype('<i2')
    output = Path(__file__).with_name('correnteza_sombria.wav')
    with wave.open(str(output), 'wb') as audio:
        audio.setnchannels(2)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        audio.writeframes(pcm.tobytes())
    seam = np.max(np.abs(mix[0] - mix[-1]))
    adjacent = np.max(np.abs(np.diff(mix, axis=0)))
    rms = np.sqrt(np.mean(mix ** 2))
    assert COUNT == 16 * 4 * BEAT * RATE
    assert seam < 0.01, f'Unexpected loop discontinuity: {seam}'
    assert np.max(np.abs(pcm.astype(np.int32))) < 32767
    print(f'{output.name}: {SECONDS}s, {BPM} BPM, stereo PCM16/{RATE}Hz')
    print(f'Peak: {20 * np.log10(0.78):.2f} dBFS; RMS: {20 * np.log10(rms):.2f} dBFS')
    print(f'Loop seam delta: {seam:.6f}; max adjacent delta: {adjacent:.6f}')


if __name__ == '__main__':
    compose()
