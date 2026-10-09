"""Rearrange complete original recordings; keep V1 and V2 for comparison."""
from pathlib import Path
import wave
import numpy as np

ROOT = Path(__file__).parent
RATE = 44100


def read(name):
    with wave.open(str(ROOT / f'card_{name}.wav'), 'rb') as source:
        assert source.getframerate() == RATE and source.getnchannels() == 1
        return np.frombuffer(source.readframes(source.getnframes()), dtype='<i2').astype(float) / 32767


def accelerate(signal, count):
    # Resample the entire recording: no truncation of the crescendo or its ending.
    return np.interp(np.linspace(0, len(signal) - 1, count), np.arange(len(signal)), signal)


def edges(signal, seconds=.008):
    signal = signal.copy()
    count = int(RATE * seconds)
    signal[:count] *= np.linspace(0, 1, count)
    signal[-count:] *= np.linspace(1, 0, count)
    return signal


def save(name, signal):
    assert len(signal) == RATE and np.isfinite(signal).all()
    signal = edges(signal)
    signal *= .8 / max(np.max(np.abs(signal)), 1e-9)
    with wave.open(str(ROOT / f'card_{name}_v3.wav'), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes((signal * 32767).astype('<i2').tobytes())
    print(f'{name} V3: 1.00s')


# Move the original metallic latch to the beginning, followed by the charging pull.
original = read('ima')
split = int(.92 * RATE)
metal = edges(original[split:])
charge = edges(original[:split])
save('ima', accelerate(np.concatenate([metal, charge]), RATE))

# Three distinct complete spear cuts, with a short gap between each one.
cut = edges(accelerate(read('perfurante'), int(.29 * RATE)))
triple = np.zeros(RATE)
for start in [0, int(.34 * RATE), int(.68 * RATE)]:
    triple[start:start + len(cut)] += cut
save('perfurante', triple)

# Play the full 1.8-second original faster, including the complete release.
save('furia', accelerate(read('furia'), RATE))
