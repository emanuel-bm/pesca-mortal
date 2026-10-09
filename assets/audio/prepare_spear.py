"""Reproduz o recorte do swosh-01.flac do pacote CC0 de qubodup.

Requer numpy e soundfile; arquivo fonte em .tools/swoshes/swosh-01.flac.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / '.tools/audio-python'))
import numpy as np
import soundfile as sf

audio, rate = sf.read(ROOT / '.tools/swoshes/swosh-01.flac')
if audio.ndim > 1:
    audio = audio.mean(axis=1)
active = np.flatnonzero(np.abs(audio) > np.max(np.abs(audio)) * 0.025)
start = max(0, int(active[0]) - int(rate * 0.008))
end = min(len(audio), int(active[-1]) + int(rate * 0.015))
audio = audio[start:end]
audio = audio / np.max(np.abs(audio)) * 0.85
fade = min(int(rate * 0.008), len(audio) // 2)
audio[:fade] *= np.linspace(0, 1, fade)
audio[-fade:] *= np.linspace(1, 0, fade)
sf.write(ROOT / 'assets/audio/spear_swish.wav', audio, rate, subtype='PCM_16')
print(f'Spear swish: {len(audio) / rate:.3f}s, {rate} Hz, mono PCM16')
