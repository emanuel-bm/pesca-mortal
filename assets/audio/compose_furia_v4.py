"""One-second Fury: original rumble blended with the magnet's rising charge.
Only writes card_furia_v4.wav; earlier recordings remain available.
"""
from pathlib import Path
import wave
import numpy as np

ROOT = Path(__file__).parent
RATE = 44100


def read(name):
    with wave.open(str(ROOT / name), 'rb') as source:
        assert source.getframerate() == RATE and source.getnchannels() == 1
        return np.frombuffer(source.readframes(source.getnframes()), dtype='<i2').astype(float) / 32767


def rms(signal):
    return np.sqrt(np.mean(signal ** 2))


fury = read('card_furia_v3.wav')
# Extract the charging layer before the original magnet's metallic latch.
charge = read('card_ima.wav')[:round(.92 * RATE)]
charge = np.interp(np.linspace(0, len(charge) - 1, RATE), np.arange(len(charge)), charge)
t = np.arange(RATE) / RATE
charge *= (.15 + .85 * t ** .7) * np.clip((1 - t) / .09, 0, 1)
charge *= rms(fury) / max(rms(charge), 1e-9)
signal = .55 * fury + .45 * charge
fade = round(.012 * RATE)
signal[:fade] *= np.linspace(0, 1, fade)
signal[-fade:] *= np.linspace(1, 0, fade)
signal *= .8 / max(np.max(np.abs(signal)), 1e-9)
assert len(signal) == RATE and np.isfinite(signal).all()
assert rms(signal[round(.55 * RATE):round(.85 * RATE)]) > 2 * rms(signal[:round(.2 * RATE)])
with wave.open(str(ROOT / 'card_furia_v4.wav'), 'wb') as output:
    output.setnchannels(1)
    output.setsampwidth(2)
    output.setframerate(RATE)
    output.writeframes((signal * 32767).astype('<i2').tobytes())
print('Furia V4: 1.00s, growing charge with the original rumble.')
