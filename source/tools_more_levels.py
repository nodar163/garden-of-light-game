"""Deterministic build-time authoring of 40 fixed, solvable branching gardens."""
import json, random
from pathlib import Path

def rotate(mask, r):
    for _ in range(r): mask = ((mask << 1) & 15) | (mask >> 3)
    return mask

def make(number):
    rng = random.Random(70800 + number)
    n = 4 if number <= 25 else 5
    progress = (number - 11) / 39
    count = min(n*n, 10 + (number-11)*15//39)
    plant_target = 2 + (number-11)*3//39
    for attempt in range(100000):
        edges = {rng.randrange(n*n): []}
        while len(edges) < count:
            options = []
            for a in edges:
                if len(edges[a]) >= 3: continue
                for dx,dy in [(0,-1),(1,0),(0,1),(-1,0)]:
                    x,y = a%n+dx,a//n+dy
                    b=y*n+x
                    if 0<=x<n and 0<=y<n and b not in edges: options.append((a,b))
            if not options: break
            a,b=rng.choice(options); edges[a].append(b); edges[b]=[a]
        leaves=[a for a in edges if len(edges[a])==1]
        if len(edges)==count and len(leaves)==plant_target+1: break
    else: raise RuntimeError(number)
    source=rng.choice(leaves)
    cells=['empty']*(n*n); solution=[0]*(n*n)
    for a,neighbors in edges.items():
        mask=0
        for b in neighbors:
            direction = 0 if b==a-n else 2 if b==a+n else 1 if b==a+1 else 3
            mask |= 1<<direction
        kind='source' if a==source else 'plant' if len(neighbors)==1 else 'tee' if len(neighbors)==3 else 'straight' if mask in (5,10) else 'corner'
        cells[a]=kind
        solution[a]=next(r for r in range(4) if rotate({'source':1,'plant':1,'tee':11,'straight':5,'corner':3}[kind],r)==mask)
    start=solution.copy()
    movable=[i for i,k in enumerate(cells) if k in ('straight','corner','tee')]
    rng.shuffle(movable)
    scramble=max(3,round(len(movable)*(.55+.45*progress)))
    for i in movable[:scramble]:
        start[i]=(start[i]+rng.choice([1,3] if cells[i]=='straight' else [1,2,3]))%4
    return dict(id=number,size=n,cells=cells,start=start,solution=solution,
                design=dict(plants=plant_target,network_cells=count,scrambled=scramble))

for number in range(11,51):
    Path(f'levels/{number:02}.json').write_text(json.dumps(make(number),indent=2)+'\n',encoding='utf-8')
print('40 fixed levels written; original 10 preserved.')
