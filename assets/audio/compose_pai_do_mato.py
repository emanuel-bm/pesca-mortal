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
    duration = 1.15 if palm else 1.05
    t = np.arange(round(RATE * duration)) / RATE
    water = noise(len(t), 170, 4400)
    body = noise(len(t), 40, 480)
    air = noise(len(t), 1400, 9500)
    if palm:
        # V3: bright skin crack with metallic upper resonance and diffuse reverb.
        envelope = sum(np.exp(-np.maximum(t-delay, 0)/.016) * (t >= delay) for delay in [0, .004, .011])
        signal = .82 * air * envelope + .32 * body * np.exp(-t/.12)
        signal += .36 * np.sin(2*np.pi*68*t) * np.exp(-t/.15)
        signal += .24 * np.sin(2*np.pi*220*t) * np.exp(-t/.08)
        signal += .24 * np.sin(2*np.pi*2800*t) * np.exp(-t/.045)
        signal += .16 * np.sin(2*np.pi*4300*t) * np.exp(-t/.032)
        signal += .04 * water * np.exp(-t/.20)
        dry = signal.copy()
        # Many irregular reflections soften into a decaying tail, avoiding a single echo.
        for delay in [.031, .047, .071, .097, .131, .173, .223, .281, .347, .421, .503, .593, .691, .797]:
            shift = round(delay * RATE)
            signal[shift:] += dry[:-shift] * (.21 * np.exp(-delay/.34))
    else:
        rise = 1 - np.exp(-t/.008)
        signal = rise * (.4*body*np.exp(-t/.11) + .28*water*np.exp(-t/.24))
        signal += .12*air*(1-np.exp(-t/.025))*np.exp(-t/.20)
        for _ in range(34):
            start = RNG.uniform(.08, .85)
            age = np.maximum(t-start, 0)
            signal += .045*np.sin(2*np.pi*RNG.uniform(420, 2200)*age)*np.exp(-age/.018)*(t>=start)*(1-start)
    save("pai_hand_slap_v3.wav" if palm else "pai_log_splash_v1.wav", signal, .90 if palm else .82)

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

def death():
    # Same breathy O formants as the arrival roar, falling into a final exhale.
    rng = np.random.default_rng(4102027)
    t = np.arange(round(RATE * 3.2)) / RATE
    pitch = np.interp(t, [0, .25, 1.4, 2.5, 3.2], [118, 132, 78, 42, 34])
    pitch += 3 * np.sin(2*np.pi*4.7*t) * np.exp(-t/2)
    phase = 2*np.pi*np.cumsum(pitch)/RATE
    voiced = .25*np.sin(phase) + .11*np.sin(phase/2)
    for harmonic in range(1, 40):
        freq = harmonic*pitch
        weight = .4*np.exp(-((freq-430)/145)**2) + .34*np.exp(-((freq-800)/200)**2) + .07*np.exp(-((freq-2450)/450)**2)
        voiced += np.sin(harmonic*phase) * weight / harmonic**.6
    breath = base_noise(rng, len(t), 180, 4200)
    envelope = np.clip(t/.06, 0, 1) * np.clip((3.2-t)/1.4, 0, 1)
    voiced *= (.72 + .22*np.sin(phase/3)) * np.exp(-t/.95)
    signal = np.tanh((voiced + .10*breath*(1-np.exp(-t/.7))*np.exp(-t/1.3))*1.6)*envelope
    dry = signal.copy()
    for delay, gain in [(.067, .10), (.131, .06), (.24, .04)]:
        shift = round(delay*RATE)
        signal[shift:] += dry[:-shift]*gain
    save("pai_death_v1.wav", signal, .78)

def log_break():
    rng = np.random.default_rng(4102028)
    t = np.arange(round(RATE * .85)) / RATE
    cracks = base_noise(rng, len(t), 700, 8500)
    body = base_noise(rng, len(t), 65, 900)
    signal = .35*body*np.exp(-t/.075)
    for delay, gain in [(0, 1), (.028, .6), (.071, .4), (.13, .25)]:
        age = np.maximum(t-delay, 0)
        signal += gain*cracks*np.exp(-age/.012)*(t >= delay)
        signal += .17*gain*np.sin(2*np.pi*155*age)*np.exp(-age/.06)*(t >= delay)
    signal += .08*cracks*np.exp(-t/.19)
    save("pai_log_break_v1.wav", signal, .72)

if __name__ == "__main__":
    throw()
    impact()
    impact(True)
    roar()
    death()
    log_break()
