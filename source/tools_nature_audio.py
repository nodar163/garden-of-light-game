"""Original synthesized nature ambience and soft match-3 sounds; no external samples."""
import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).parent/'assets'
RATE = 22050

def write(name, samples, channels=1):
    with wave.open(str(ROOT/name), 'wb') as f:
        f.setparams((channels,2,RATE,0,'NONE','not compressed'))
        f.writeframes(b''.join(struct.pack('<h',max(-32767,min(32767,int(s*26000)))) for s in samples))

def nature():
    rng = random.Random(817)
    seconds = 24
    # Smooth water/leaf noise with stereo space. Edges crossfade to silence.
    left = right = 0.0
    birds = [(1.5,2200),(4.2,2850),(8.4,2450),(13.1,3100),(17.0,2300),(20.4,2700)]
    samples=[]
    for i in range(RATE*seconds):
        t=i/RATE
        left=left*.92+rng.uniform(-1,1)*.08
        right=right*.94+rng.uniform(-1,1)*.06
        fade=min(1,t/1.0,(seconds-t)/1.0)
        wind=.13+.025*math.sin(t*.47)
        bird=0.0
        for onset,pitch in birds:
            u=t-onset
            if 0 <= u < 1.2:
                pulse=(u%0.29)/0.29
                envelope=math.sin(math.pi*pulse)**3*math.sin(math.pi*u/1.2)**2
                phase=2*math.pi*(pitch*u+150*math.sin(u*13))
                bird+=.025*envelope*math.sin(phase)
        water=.007*math.sin(2*math.pi*710*t+3*math.sin(t*9))
        samples.extend([(left*wind+bird+water)*fade,(right*wind+bird*.6-water)*fade])
    write('nature.wav',samples,2)

def pluck(name, notes, seconds, stagger=.04, volume=.19):
    data=[]
    for i in range(int(RATE*seconds)):
        t=i/RATE
        value=0.0
        for j,hz in enumerate(notes):
            u=t-j*stagger
            if u >= 0:
                envelope=min(1,u*150)*math.exp(-u*7)*(min(1,(seconds-t)*30))
                value+=envelope*(math.sin(math.tau*hz*u)+.19*math.sin(math.tau*hz*2*u))
        data.append(value*volume/len(notes))
    write(name,data)

nature()
pluck('swap.wav',[740,880],.18,.035,.10)
pluck('bloom.wav',[659.25,830.61,987.77],.55,.045,.25)
pluck('power.wav',[392,523.25,659.25,783.99,1046.5],.8,.06,.3)
pluck('win.wav',[523.25,659.25,783.99,1046.5,1318.5],1.5,.14,.28)
print('Nature ambience and 4 original match sounds created.')
