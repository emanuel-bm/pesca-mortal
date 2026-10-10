"""Official V3: a fast dash followed by a distinct, cohesive water surge.
Generates the approved V3 asset; preserves all previous dash versions.
"""
import numpy as np
from compose_boss_sounds import RATE, noise, save


def compose_dash():
    rng = np.random.default_rng(940420)
    t = np.arange(round(RATE * .7)) / RATE
    count = len(t)
    rush = noise(rng, count, 350, 4800)
    mass = noise(rng, count, 45, 520, [(160, 110, .8)])
    water = noise(rng, count, 180, 2800, [(650, 380, 1.3)])
    foam = noise(rng, count, 1700, 5500)
    passage = np.exp(-((t - .10) / .055) ** 2)
    surge = np.exp(-((t - .19) / .085) ** 2)
    wake = np.exp(-((t - .32) / .115) ** 2)
    # A single quick leading gesture keeps the dash immediately readable.
    signal = rush * .25 * passage + mass * .24 * passage
    # The connected surge and receding wash make the movement sound wet.
    texture = np.interp(t, np.linspace(0, .7, 36), rng.uniform(.65, 1, 36))
    signal += water * texture * (.28 * surge + .13 * wake)
    signal += mass * .09 * surge
    signal += foam * texture * (.06 * surge + .045 * wake)
    save('minhocao_dash_v3.wav', signal, .006, .18, lowpass=5500, gain=.8)


if __name__ == '__main__':
    compose_dash()
