"""Original quiet pentatonic garden score. No external recordings or licenses."""
import math, struct, wave
from pathlib import Path
RATE=22050
DURATION=32
data=bytearray()
chords=[(130.813,164.814,195.998),(110,130.813,164.814),
        (87.307,130.813,174.614),(97.999,146.832,195.998)]
melody=[523.251,659.255,783.991,659.255,587.330,523.251,440,523.251,
        659.255,783.991,1046.502,783.991,659.255,587.330,523.251,392]
peak=0.0
for i in range(RATE*DURATION):
    t=i/RATE
    chord=chords[int(t//8)%4]
    section=t%8
    pad=sum(math.sin(math.tau*f*t)+.12*math.sin(math.tau*f*2*t) for f in chord)/3
    pad*=.07*math.sin(math.pi*section/8)**2
    note=melody[int(t//2)%len(melody)]
    u=t%2
    pluck=(math.sin(math.tau*note*u)+.16*math.sin(math.tau*note*2*u))
    pluck*=.10*min(1,u/.018)*math.exp(-u*3.8)
    edge=min(1,t/.2,(DURATION-t)/.3)
    for pan in [.92,1.0]:
        sample=(pad+pluck*pan)*edge
        peak=max(peak,abs(sample))
        data.extend(struct.pack('<h',round(sample*32767)))
with wave.open(str(Path(__file__).parent/'assets/garden-music.wav'),'wb') as f:
    f.setparams((2,2,RATE,0,'NONE','not compressed')); f.writeframes(data)
print(f'Original 32 s stereo garden score; peak {peak:.3f}; no clipping.')
