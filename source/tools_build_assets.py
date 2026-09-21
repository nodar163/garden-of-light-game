"""Rebuild original audio and ten authored boards; Python standard library only.
Not used by the game at runtime. Run from the project directory.
"""
import json
import math
import struct
import wave
from pathlib import Path

# Each sequence is a hand-authored continuous route from source to flower.
ROUTES = [
    [3, 4, 5],
    [6, 3, 4, 5],
    [0, 1, 4, 7, 8],
    [6, 3, 0, 1, 2, 5, 8],
    [0, 3, 6, 7, 4, 5, 8],
    [2, 1, 0, 3, 4, 7, 8],
    [8, 5, 2, 1, 4, 3, 6],
    [4, 1, 0, 3, 6, 7, 8, 5, 2],
    [0, 1, 2, 5, 4, 3, 6, 7, 8],
    [6, 7, 8, 5, 2, 1, 0, 3, 4],
]

def mask(base, turns):
    for _ in range(turns):
        base = ((base << 1) & 15) | (base >> 3)
    return base

def direction(a, b):
    return { -3: 0, 1: 1, 3: 2, -1: 3 }[b-a]

for number, route in enumerate(ROUTES, 1):
    cells, solution = ['empty']*9, [0]*9
    for position, index in enumerate(route):
        neighbors = route[max(0, position-1):position] + route[position+1:position+2]
        ports = sum(1 << direction(index, other) for other in neighbors)
        kind = 'source' if position == 0 else 'plant' if position == len(route)-1 else 'straight' if ports in [5,10] else 'corner'
        base = {'source':1,'plant':1,'straight':5,'corner':3}[kind]
        cells[index] = kind
        solution[index] = next(r for r in range(4) if mask(base,r) == ports)
    start = solution.copy()
    for step, index in enumerate(route[1:-1]):
        start[index] = (start[index] + (1 if number == 1 else 1 + (step+number)%3)) % 4
    data = dict(id=number, size=3, cells=cells, start=start, solution=solution)
    Path(f'levels/{number:02}.json').write_text(json.dumps(data, indent=2)+'\n', encoding='utf-8')

def audio(path, seconds, notes, chime=False):
    rate = 22050
    samples = bytearray()
    for i in range(int(seconds*rate)):
        t = i/rate
        if chime:
            envelope = min(t*40, 1) * math.exp(-3*t)
        else:
            envelope = math.sin(math.pi*t/seconds)**2
        value = sum(math.sin(2*math.pi*f*t) / len(notes) for f in notes)
        value += 0.12*math.sin(2*math.pi*notes[0]*2*t)
        samples.extend(struct.pack('<h', int(12000*value*envelope)))
    with wave.open(str(path),'wb') as f:
        f.setparams((1,2,rate,0,'NONE','not compressed'))
        f.writeframes(samples)

audio('assets/ambience.wav', 12, [130.8128,196,261.6256,329.6276])
audio('assets/chime.wav', 1.4, [523.251,659.255,783.991], True)
print('10 authored boards and 2 original synthesized audio files rebuilt.')
