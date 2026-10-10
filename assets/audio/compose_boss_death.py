"""Original dying growl and heavy river plunge; no sampled recordings."""
import numpy as np
from pathlib import Path
import wave
import argparse
import shutil
import subprocess
from compose_boss_sounds import RATE, noise, save


def compose_death(ffmpeg, version='v0'):
    rng = np.random.default_rng(731961)
    t = np.arange(round(RATE * 2.2)) / RATE
    f0 = np.interp(t, [0, .12, .5, 1.1, 1.65, 2.2], [180, 240, 160, 85, 42, 30])
    f0 += 5 * np.sin(2 * np.pi * 23 * t) * np.exp(-t * 1.5)
    phase = 2 * np.pi * np.cumsum(f0) / RATE
    throat = sum(np.sin(phase * h + .22 * np.sin(t * (91 + h))) / h ** 1.2
                 for h in range(1, 15))
    rasp = noise(rng, len(t), 180, 3600, [(850, 350, 1.6)])
    breath = np.clip(t / .045, 0, 1) * np.exp(-t * 1.7)
    strain = .72 + .28 * np.sin(2 * np.pi * (14 * t - 2 * t ** 2)) ** 2
    dry = (np.tanh(throat * 1.4) * .65 + rasp * .18) * breath * strain
    water = noise(rng, len(t), 90, 4200)
    rumble = noise(rng, len(t), 30, 330)
    collapse = np.exp(-((t - .85) / .16) ** 2)
    wake = np.exp(-((t - 1.22) / .38) ** 2)
    signal = dry + rumble * (.32 * collapse + .13 * wake)
    signal += water * (.17 * collapse + .08 * wake)
    for delay, gain in [(.073, .12), (.147, .065)]:
        shift = round(delay * RATE)
        signal[shift:] += dry[:-shift] * gain
    save('minhocao_death.wav', signal, .012, .45, lowpass=4500, gain=.80)
    if version == 'v0':
        return
    # Compress time independently of pitch to preserve the original low growl.
    path = Path(__file__).with_name('minhocao_death.wav')
    with wave.open(str(path), 'rb') as audio:
        original = np.frombuffer(audio.readframes(audio.getnframes()), dtype='<i2').astype(float)
    result = subprocess.run([
        ffmpeg, '-hide_banner', '-loglevel', 'error', '-i', str(path),
        '-af', 'rubberband=tempo=2.2:pitch=1', '-f', 's16le',
        '-acodec', 'pcm_s16le', '-ar', str(RATE), '-ac', '1', 'pipe:1',
    ], check=True, capture_output=True)
    compressed = np.frombuffer(result.stdout, dtype='<i2').astype(float)
    assert len(compressed) == RATE, 'Time compression must produce exactly one second'
    compressed *= (np.max(np.abs(original)) * .5) / np.max(np.abs(compressed))
    pcm = np.rint(compressed).astype('<i2')
    with wave.open(str(path), 'wb') as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        audio.writeframes(pcm.tobytes())
    assert len(pcm) == RATE
    assert np.max(np.abs(pcm.astype(float))) <= np.max(np.abs(original)) * .5 + 1
    print('Final death sound: 1.000s, original pitch preserved, peak amplitude 50%')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    bundled = Path(__file__).resolve().parents[2] / '.tools/video-python/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe'
    parser.add_argument('--ffmpeg', default=shutil.which('ffmpeg') or str(bundled))
    parser.add_argument('--version', choices=['v0', 'v3'], default='v0')
    args = parser.parse_args()
    compose_death(args.ffmpeg, args.version)
