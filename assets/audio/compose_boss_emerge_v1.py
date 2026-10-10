"""Official V1: a large creature breaching water, followed by falling spray.
Generates the approved V1 asset while preserving the previous emergence WAV.
"""
import numpy as np
from compose_boss_sounds import RATE, noise, save


def compose_emergence():
    rng = np.random.default_rng(310418)
    t = np.arange(round(RATE * 1.15)) / RATE
    count = len(t)
    # Broad, irregular water masses; no roar, rubble or explosive crack.
    body = noise(rng, count, 45, 650, [(190, 130, 1.1)])
    water = noise(rng, count, 230, 3400, [(900, 700, .6)])
    spray = noise(rng, count, 1600, 7800)
    swell = np.exp(-((t - .11) / .085) ** 2)
    opening = np.exp(-((t - .23) / .13) ** 2)
    falling = np.exp(-((t - .46) / .24) ** 2)
    texture = np.interp(t, np.linspace(0, 1.15, 95), rng.uniform(.45, 1, 95))
    signal = body * (.30 * swell + .19 * opening)
    signal += water * texture * (.29 * opening + .12 * falling)
    signal += spray * texture * (.055 * opening + .07 * falling)
    # Short damped bubble resonances and scattered droplets in the wake.
    for _ in range(42):
        start = rng.uniform(.20, .94)
        age = t - start
        active = np.maximum(age, 0)
        frequency = rng.uniform(480, 2350)
        decay = rng.uniform(.008, .026)
        envelope = (age >= 0) * (1 - np.exp(-active / .0015)) * np.exp(-active / decay)
        bubble = np.sin(2 * np.pi * frequency * (active + .002 * (1 - np.exp(-active / .008))))
        signal += bubble * envelope * rng.uniform(.012, .04) * (1 - start / 1.15)
    # Quiet wash recedes smoothly after the breach.
    signal += water * .025 * np.clip((t - .32) / .08, 0, 1) * np.exp(-np.maximum(t - .32, 0) * 5)
    save('minhocao_emerge_v1.wav', signal, .012, .28, lowpass=7200, gain=.8)


if __name__ == '__main__':
    compose_emergence()
