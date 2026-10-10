"""Preview V2: a clean fast dash with a restrained water wake.
Preserves both the official effect and V1.
"""
import numpy as np
from compose_boss_sounds import RATE, noise, save


def compose_dash():
    rng = np.random.default_rng(940419)
    t = np.arange(round(RATE * .6)) / RATE
    count = len(t)
    # One clear movement gesture, with weight underneath the quick passage.
    rush = noise(rng, count, 200, 4800)
    weight = noise(rng, count, 45, 480)
    water = noise(rng, count, 300, 2200, [(700, 350, .5)])
    passage = np.exp(-((t - .115) / .065) ** 2)
    wake = np.exp(-((t - .24) / .09) ** 2)
    signal = rush * .34 * passage + weight * .27 * passage
    signal += np.sin(2 * np.pi * 52 * t) * .09 * passage
    # A single soft wash trails the dash; no separate bubbles or droplet clicks.
    signal += water * (.065 * passage + .085 * wake)
    signal += rush * .025 * wake
    save('minhocao_dash_v2.wav', signal, .006, .16, lowpass=5200, gain=.8)


if __name__ == '__main__':
    compose_dash()
