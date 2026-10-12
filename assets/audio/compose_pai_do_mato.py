"""Original deterministic Pai do Mato effects: no external samples or recordings."""
import numpy as np
from compose_boss_sounds import RATE, noise as base_noise, save as base_save
RNG = np.random.default_rng(4102026)

def noise(count, low, high):
    return base_noise(RNG, count, low, high)

def save(name, signal, gain=.8):
    base_save(name, signal, attack=.006, release=.04, lowpass=10000, gain=gain/.89)

def throw():
    t = np.arange(round(RATE * .325)) / RATE
    envelope = np.sin(np.pi * t / .325) ** 1.4
    air = noise(len(t), 180, 6400)
    body = noise(len(t), 55, 430)
    signal = envelope * (.23 * air + .18 * body)
    signal += .10 * np.sin(2*np.pi*(85*t + 95*t*t)) * envelope
    save("pai_log_throw_v1.wav", signal, .72)

def impact(palm=False):
    duration = .58 if palm else 1.05
    t = np.arange(round(RATE * duration)) / RATE
    water = noise(len(t), 170, 4400)
    body = noise(len(t), 40, 480)
    air = noise(len(t), 1400, 9500)
    if palm:
        # V2: a sharper skin crack, chesty sub impact and brighter palm resonance.
        envelope = sum(np.exp(-np.maximum(t-delay, 0)/.016) * (t >= delay) for delay in [0, .004, .011])
        signal = .58 * air * envelope + .52 * body * np.exp(-t/.12)
        signal += .36 * np.sin(2*np.pi*68*t) * np.exp(-t/.15)
        signal += .24 * np.sin(2*np.pi*220*t) * np.exp(-t/.08)
        signal += .10 * np.sin(2*np.pi*1800*t) * np.exp(-t/.025)
        signal += .04 * water * np.exp(-t/.20)
    else:
        rise = 1 - np.exp(-t/.008)
        signal = rise * (.4*body*np.exp(-t/.11) + .28*water*np.exp(-t/.24))
        signal += .12*air*(1-np.exp(-t/.025))*np.exp(-t/.20)
        for _ in range(34):
            start = RNG.uniform(.08, .85)
            age = np.maximum(t-start, 0)
            signal += .045*np.sin(2*np.pi*RNG.uniform(420, 2200)*age)*np.exp(-age/.018)*(t>=start)*(1-start)
    save("pai_hand_slap_v2.wav" if palm else "pai_log_splash_v1.wav", signal, .90 if palm else .82)

def roar():
    t = np.arange(round(RATE * 2.4)) / RATE
    # An aged, breathy O vowel: deep fundamental, rising strain, rough subharmonic.
    pitch = 88 + 38*np.sin(np.pi*np.minimum(t/1.8, 1)) + 3*np.sin(2*np.pi*5.3*t)
    pitch += np.interp(t, np.linspace(0, 2.4, 330), RNG.normal(0, 1.7, 330))
    phase = 2*np.pi*np.cumsum(pitch)/RATE
    voiced = np.zeros_like(t)
    for harmonic in range(1, 40):
        freq = harmonic*pitch
        weight = .4*np.exp(-((freq-430)/145)**2) + .34*np.exp(-((freq-800)/200)**2) + .07*np.exp(-((freq-2450)/450)**2)
        voiced += np.sin(harmonic*phase) * weight / harmonic**.6
    voiced += .25*np.sin(phase) + .11*np.sin(phase/2)
    breath = noise(len(t), 300, 4800)
    roughness = (.70 + .22*np.sin(phase/3) + .08*np.sin(2*np.pi*33*t))
    envelope = np.clip(t/.16, 0, 1) * np.clip((2.4-t)/.6, 0, 1)
    signal = (voiced*roughness + .035*breath) * envelope
    signal = np.tanh(signal*1.6)
    for delay, gain in [(.067, .10), (.131, .06)]:
        shift = round(delay*RATE)
        signal[shift:] += signal[:-shift].copy()*gain
    save("pai_roar_v1.wav", signal, .78)

if __name__ == "__main__":
    throw()
    impact()
    impact(True)
    roar()
