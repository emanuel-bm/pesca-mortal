"""Preview V1: fast movement through water with a heavy bow wave and wake.
Only writes minhocao_dash_v1.wav; the current game sound stays intact.
"""
import numpy as np
from compose_boss_sounds import RATE, noise, save


def compose_dash():
    rng = np.random.default_rng(940418)
    t = np.arange(round(RATE * .8)) / RATE
    count = len(t)
    mass = noise(rng, count, 35, 580, [(155, 100, 1.3)])
    water = noise(rng, count, 170, 3200, [(760, 450, .8)])
    foam = noise(rng, count, 1200, 6800)
    thrust = np.exp(-((t - .105) / .065) ** 2)
    passage = np.exp(-((t - .245) / .14) ** 2)
    wake = np.exp(-((t - .44) / .18) ** 2)
    texture = np.interp(t, np.linspace(0, .8, 105), rng.uniform(.35, 1, 105))
    signal = mass * (.37 * thrust + .19 * passage + .06 * wake)
    signal += water * texture * (.30 * passage + .16 * wake)
    signal += foam * texture * (.065 * passage + .055 * wake)
    # Water repeatedly breaks along the creature, rather than one airy whoosh.
    for start, width, gain in [(.06, .018, .13), (.16, .03, .16),
                               (.29, .035, .13), (.41, .045, .09), (.53, .055, .05)]:
        signal += water * gain * np.exp(-((t - start) / width) ** 2)
    # Brief wet resonances in the receding wake.
    for _ in range(32):
        start = rng.uniform(.18, .68)
        age = np.maximum(t - start, 0)
        envelope = (t >= start) * (1 - np.exp(-age / .001)) * np.exp(-age / rng.uniform(.007, .019))
        frequency = rng.uniform(550, 2100)
        bubble = np.sin(2 * np.pi * frequency * (age + .0015 * (1 - np.exp(-age / .006))))
        signal += bubble * envelope * rng.uniform(.014, .04) * (1 - start / .8)
    save('minhocao_dash_v1.wav', signal, .006, .18, lowpass=6500, gain=.8)


if __name__ == '__main__':
    compose_dash()
