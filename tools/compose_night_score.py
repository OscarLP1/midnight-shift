"""Original ambient score. Deterministic stereo PCM, seamless 32 s loops.
No external samples. Slow bowed harmonics, filtered air and restrained pulses.
"""
from pathlib import Path
import wave
import numpy as np

SR = 22050
N = SR * 32
t = np.arange(N) / SR
rng = np.random.default_rng(819)
out = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
out.mkdir(exist_ok=True)

def save(name, audio):
    audio = np.tanh(audio * 0.8)
    with wave.open(str(out / (name + '.wav')), 'wb') as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes((np.clip(audio, -0.92, 0.92) * 32767).astype('<i2').tobytes())

def pad(freq, offset=0):
    # Quantized oscillators and modulation guarantee periodic loop boundaries.
    freq = round(freq * 32) / 32
    result = np.zeros(N)
    for k in range(1, 7):
        result += np.sin(2*np.pi*freq*k*t + 0.20*np.sin(2*np.pi*t/16+offset)) / k**2.3
    return result * (0.68 + 0.25*np.cos(2*np.pi*t/32+offset))

def stereo(notes):
    a = sum(pad(f,i*1.3) * amp for i,(f,amp) in enumerate(notes))
    b = sum(pad(f,i*1.3+0.28) * amp for i,(f,amp) in enumerate(notes))
    return np.column_stack((a,b))

save('after-hours',stereo([(55,.30),(82.4069,.16),(130.8128,.10),(164.8138,.06)]))
unease = stereo([(55,.25),(58.2705,.07),(110,.14),(155.5635,.09),(207.6523,.04)])
pulse = (0.5+0.5*np.cos(2*np.pi*t/4))**10
unease += (0.07*np.sin(2*np.pi*41.25*t)*pulse)[:,None]
save('unease',unease)
save('presence',stereo([(36.71875,.25),(73.4375,.17),(77.78125,.08),(146.84375,.07)]))

# A low wooden resonance with soft air; no scream or abrupt volume spike.
u = np.arange(SR*5)/SR
env = np.sin(np.pi*np.minimum(u/5,1))**2*np.exp(-u*.38)
air = rng.normal(0,1,len(u))
air = np.convolve(air,np.ones(90)/90,mode='same')
creak = sum(np.sin(2*np.pi*(f*u+2*np.sin(u*.7)))/a for f,a in [(96,3),(151,6),(213,10)])
cue = (creak*.28+air*.5)*env
save('threshold',np.column_stack((cue,np.roll(cue,270))))
print('Composed 3 ambient layers and one restrained apparition cue.')
