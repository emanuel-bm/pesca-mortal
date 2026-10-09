"""Create V0 (previous brighter roar), V1 (exact copy), V2 (one-second sustain).
Preserves minhocao_roar.wav and the game's selection. Requires NumPy.
"""
from pathlib import Path
import hashlib
import inspect
import shutil
import sys
import wave
import numpy as np
from compose_boss_sounds import RATE, noise, save, compose_roar

DIRECTORY = Path(__file__).parent


def replace_exact(source, before, after):
    if source.count(before) != 1:
        raise RuntimeError('Baseline composer changed; review the variant before regenerating.')
    return source.replace(before, after)


def create_variant(version):
    # Transform only our trusted local synthesis source, not any reference audio.
    source = inspect.getsource(compose_roar)
    if version in (0, 3, 4, 5):
        # Reverse the precise changes from the preceding pitch/brightness edit.
        changes = [
            ('    f0 *= .80  # Lower the previous cry by about four semitones, keeping its shape.\n', ''),
            ('950 - 140 * t', '1100 - 160 * t'),
            ('1.6 * np.exp(-((f - (2050 - 280 * t)) / 650)', '1.9 * np.exp(-((f - (2450 - 330 * t)) / 650)'),
            ('throat += .20 * np.sin(phase / 2)', 'throat += .12 * np.sin(phase / 2)'),
            ('[(1.49, .20), (2.07, .12), (2.83, .06)]', '[(1.49, .22), (2.07, .14), (2.83, .08)]'),
            ('noise(rng, len(t), 280, 4800, [(1400, 600, 2)])', 'noise(rng, len(t), 350, 6500, [(1700, 600, 2)])'),
            (', lowpass=3800)', ')'),
        ]
    else:
        changes = []
    if version in (2, 3, 4, 5):
        attack_seconds = {2: '.15', 3: '.04', 4: '.20', 5: '.40'}[version]
        release_seconds = '.85' if version == 2 else '.50'
        hold_end = '1.15' if version == 2 else '1.50'
        changes += [(
            '    contour = (1 - np.exp(-t * 45)) * np.exp(-t * .36)\n'
            '    contour *= 1 + .30 * np.exp(-((t - .48) / .32) ** 2)\n'
            '    contour += .12 * np.exp(-((t - 1.35) / .20) ** 2)',
            '    window = round(RATE * .04)\n'
            '    power = np.convolve(body ** 2, np.ones(window) / window, mode="same")\n'
            f'    reference = np.sqrt(np.mean(body[int(.15 * RATE):int({hold_end} * RATE)] ** 2))\n'
            '    body *= np.clip(reference / np.sqrt(np.maximum(power, 1e-8)), .75, 1.35)\n'
            f'    attack = np.clip(t / {attack_seconds}, 0, 1)\n'
            '    attack = attack * attack * (3 - 2 * attack)\n'
            f'    release = np.clip((2 - t) / {release_seconds}, 0, 1)\n'
            '    release = release * release * (3 - 2 * release)\n'
            '    contour = attack * release'
        )]
    for before, after in changes:
        source = replace_exact(source, before, after)
    source = replace_exact(source, "'minhocao_roar.wav'", f"'minhocao_roar_v{version}.wav'")
    namespace = {'np': np, 'RATE': RATE, 'noise': noise, 'save': save}
    exec(compile(source, f'<original-roar-variant-{version}>', 'exec'), namespace)
    namespace['compose_roar']()
    if version == 5:
        # Attenuate after normalization so the WAV itself is 30% quieter.
        path = DIRECTORY / 'minhocao_roar_v5.wav'
        with wave.open(str(path), 'rb') as audio:
            parameters = audio.getparams()
            original_pcm = np.frombuffer(audio.readframes(audio.getnframes()), dtype='<i2')
        quieter_pcm = np.rint(original_pcm.astype(float) * .70).astype('<i2')
        assert np.max(np.abs(quieter_pcm.astype(float) - original_pcm.astype(float) * .70)) <= .5
        with wave.open(str(path), 'wb') as audio:
            audio.setparams(parameters)
            audio.writeframes(quieter_pcm.tobytes())
        print('V5 gain: 70% of unattenuated amplitude (-3.10 dB), no renormalization.')


def main():
    original = DIRECTORY / 'minhocao_roar.wav'
    before = hashlib.sha256(original.read_bytes()).hexdigest()
    v1 = DIRECTORY / 'minhocao_roar_v1.wav'
    if v1.exists() and v1.read_bytes() != original.read_bytes():
        raise RuntimeError('Existing V1 differs from the current sound; preserve it before regenerating.')
    if not v1.exists():
        shutil.copyfile(original, v1)
    create_variant(0)
    create_variant(2)
    assert before == hashlib.sha256(original.read_bytes()).hexdigest()
    assert original.read_bytes() == v1.read_bytes()
    for version in range(3):
        with wave.open(str(DIRECTORY / f'minhocao_roar_v{version}.wav'), 'rb') as audio:
            assert audio.getnframes() == RATE * 2 and audio.getframerate() == RATE
            assert audio.getnchannels() == 1 and audio.getsampwidth() == 2
    print('Original unchanged; V1 is a byte-for-byte copy; all variants last 2 seconds.')
    with wave.open(str(DIRECTORY / 'minhocao_roar_v2.wav'), 'rb') as audio:
        samples = np.frombuffer(audio.readframes(RATE * 2), dtype='<i2').astype(float) / 32768
    for start in [.25, .50, .75, 1.0, 1.5, 1.75]:
        segment = samples[round(start * RATE):round((start + .2) * RATE)]
        print(f'V2 RMS at {start:.2f}s: {20*np.log10(np.sqrt(np.mean(segment**2))):.2f} dBFS')


def create_sustained_variant(version):
    preserved = ['minhocao_roar.wav'] + [f'minhocao_roar_v{i}.wav' for i in range(version)]
    hashes = {name: hashlib.sha256((DIRECTORY / name).read_bytes()).hexdigest() for name in preserved}
    create_variant(version)
    for name in preserved:
        assert hashlib.sha256((DIRECTORY / name).read_bytes()).hexdigest() == hashes[name]
    with wave.open(str(DIRECTORY / f'minhocao_roar_v{version}.wav'), 'rb') as audio:
        assert audio.getnframes() == RATE * 2 and audio.getframerate() == RATE
        samples = np.frombuffer(audio.readframes(RATE * 2), dtype='<i2').astype(float) / 32768
    levels = []
    for start in [.25, .50, .75, 1.0, 1.25, 1.5, 1.75]:
        segment = samples[round(start * RATE):round((start + .2) * RATE)]
        level = 20 * np.log10(np.sqrt(np.mean(segment**2)))
        levels.append(level)
        print(f'V{version} RMS at {start:.2f}s: {level:.2f} dBFS')
    sustain_levels = levels[1:5] if version == 5 else levels[:5]
    assert max(sustain_levels) - min(sustain_levels) < 1.5, 'Sustain must remain steady until the final half-second'
    assert levels[-1] < min(levels[:5]) - 8, 'Final half-second must release clearly'
    if version in (4, 5):
        attack_levels = []
        attack_points = [0.0, .16, .32] if version == 5 else [0.0, .08, .16]
        for start in attack_points:
            segment = samples[round(start * RATE):round((start + .04) * RATE)]
            attack_levels.append(np.sqrt(np.mean(segment ** 2)))
        assert samples[0] == 0.0
        assert attack_levels[0] < attack_levels[1] < attack_levels[2], 'Attack must rise from silence'
        milliseconds = 400 if version == 5 else 200
        print(f'V{version} attack: zero start, rising intensity over {milliseconds}ms.')
    print(f'V{version} uses V0 tone; holds until 1.5s, releases to 2s. Previous files preserved.')


if __name__ == '__main__':
    if '--v5' in sys.argv:
        create_sustained_variant(5)
    elif '--v4' in sys.argv:
        create_sustained_variant(4)
    elif '--v3' in sys.argv:
        create_sustained_variant(3)
    else:
        main()
