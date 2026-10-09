"""V5 piercing: overlapping cuts spaced 140 ms apart; preserve earlier versions."""
from pathlib import Path
import wave
import numpy as np

ROOT = Path(__file__).parent
RATE = 44100


def read(name):
    with wave.open(str(ROOT / f'card_{name}.wav'), 'rb') as source:
        assert source.getframerate() == RATE and source.getnchannels() == 1
        return np.frombuffer(source.readframes(source.getnframes()), dtype='<i2').astype(float) / 32767


def fit(signal, seconds):
    count = round(RATE * seconds)
    result = np.interp(np.linspace(0, len(signal) - 1, count), np.arange(len(signal)), signal)
    fade = round(RATE * .008)
    result[:fade] *= np.linspace(0, 1, fade)
    result[-fade:] *= np.linspace(1, 0, fade)
    return result


def save(name, signal):
    assert len(signal) == RATE and np.isfinite(signal).all()
    signal *= .8 / max(np.max(np.abs(signal)), 1e-9)
    with wave.open(str(ROOT / f'card_{name}_v5.wav'), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes((signal * 32767).astype('<i2').tobytes())
    print(f'{name} V5: 1.00s')


# Closely spaced attacks with overlapping bodies and tails: one rolling burst.
cut = fit(read('perfurante'), .72)
burst = np.zeros(RATE)
for seconds, gain in [(0, 1.0), (.14, .95), (.28, .9)]:
    start = round(seconds * RATE)
    burst[start:start + len(cut)] += gain * cut
save('perfurante', burst)
