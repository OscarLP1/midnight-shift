"""Original nonverbal creature vocalizations: breath, formants, sobs and echoes."""
from pathlib import Path
import wave
import numpy as np

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "assets/audio"

def render(name, duration, pitch, formants, mode, seed):
    rng = np.random.default_rng(seed)
    t = np.arange(int(duration * RATE)) / RATE
    if mode == "sob":
        pulse = np.maximum(0, np.sin(2 * np.pi * t * 1.35)) ** 1.8
        pitch_curve = pitch + 35 * np.sin(t * 3) + 12 * np.sin(t * 36)
        envelope = pulse * np.sin(np.pi * t / duration) ** 0.6
    elif mode == "scream":
        pitch_curve = pitch + 95 * np.sin(np.pi * t / duration) + 18 * np.sin(t * 39)
        envelope = np.sin(np.pi * t / duration) ** 0.7 * (0.8 + 0.2 * np.sin(t * 49))
    else:
        pitch_curve = pitch + 7 * np.sin(t * 4) + 4 * np.sin(t * 28)
        envelope = np.sin(np.pi * t / duration) ** 1.4
    phase = 2 * np.pi * np.cumsum(pitch_curve) / RATE
    voice = np.zeros_like(t)
    for harmonic in range(1, 38):
        freq = pitch_curve * harmonic
        weight = sum(np.exp(-0.5 * ((freq - center) / width) ** 2) * gain
                     for center, width, gain in formants)
        voice += np.sin(phase * harmonic) * weight / harmonic ** 0.55
    breath = rng.normal(0, 1, len(t))
    breath = np.convolve(breath, np.ones(7) / 7, "same")
    voice = (voice + breath * (0.16 if mode == "scream" else 0.3)) * envelope
    voice = np.tanh(voice * 0.9)
    left, right = voice.copy(), voice.copy()
    for delay, gain in [(0.083, .18), (.173, .13), (.291, .09), (.43, .05)]:
        samples = int(delay * RATE)
        left[samples:] += voice[:-samples] * gain
        samples += 197
        right[samples:] += voice[:-samples] * gain
    stereo = np.column_stack((left, right))
    stereo *= 0.65 / max(0.001, np.abs(stereo).max())
    with wave.open(str(OUT / (name + ".wav")), "wb") as file:
        file.setnchannels(2)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes((stereo * 32767).astype("<i2").tobytes())

render("stalker-growl", 3.2, 74, [(350, 120, 1), (850, 170, .6)], "growl", 1)
render("stalker-scream", 2.6, 285, [(740, 200, 1), (1350, 260, .8), (2700, 350, .3)], "scream", 2)
render("antler-scream", 3.6, 180, [(550, 180, 1), (1900, 280, .7), (3100, 300, .4)], "scream", 3)
render("drowned-sobs", 4.4, 195, [(430, 130, 1), (1150, 200, .8), (2300, 280, .2)], "sob", 4)
print("Rendered four original breath/formant creature vocalizations.")
