"""Author 200 deterministic gardens. Runtime uses only the resulting JSON files."""
import csv
import json
import random
from pathlib import Path

ROOT = Path(__file__).parent
BASE = {'source': 1, 'plant': 1, 'straight': 5, 'corner': 3, 'tee': 11}
STEPS = [(0, -1), (1, 0), (0, 1), (-1, 0)]

def rotate(mask, turns):
    for _ in range(turns):
        mask = ((mask << 1) & 15) | (mask >> 3)
    return mask

def candidate(seed, n, count, min_plants, max_plants):
    rng = random.Random(seed)
    for _ in range(20000):
        start = rng.randrange(n*n)
        edges = {start: []}
        stack = [start]
        while stack and len(edges) < count:
            a = stack[-1]
            options = [y*n+x for dx, dy in STEPS
                       for x, y in [(a % n+dx, a//n+dy)]
                       if 0 <= x < n and 0 <= y < n and y*n+x not in edges]
            if not options or len(edges[a]) == 3:
                stack.pop()
                continue
            b = rng.choice(options)
            edges[a].append(b)
            edges[b] = [a]
            stack.append(b)
        leaves = [a for a in edges if len(edges[a]) == 1]
        if len(edges) == count and min_plants <= len(leaves)-1 <= max_plants:
            break
    else:
        raise RuntimeError(f'Cannot author seed {seed}')
    source = rng.choice(leaves)
    cells = ['empty']*(n*n)
    solution = [0]*(n*n)
    for a, neighbors in edges.items():
        mask = sum(1 << STEPS.index((b % n-a % n, b//n-a//n)) for b in neighbors)
        kind = ('source' if a == source else 'plant' if len(neighbors) == 1
                else 'tee' if len(neighbors) == 3 else 'straight' if mask in (5, 10) else 'corner')
        cells[a] = kind
        solution[a] = next(r for r in range(4) if rotate(BASE[kind], r) == mask)
    initial = solution.copy()
    taps = 0
    for i, kind in enumerate(cells):
        if kind not in ('straight', 'corner', 'tee'):
            continue
        offset = rng.choice([1, 3] if kind == 'straight' else [1, 2, 3])
        initial[i] = (initial[i]+offset) % 4
        taps += 1 if kind == 'straight' else 4-offset
    # This is an authoring score, NOT a proof of minimum solution moves.
    score = count*20 + cells.count('tee')*8 + cells.count('corner')*2 + taps
    return dict(size=n, cells=cells, start=initial, solution=solution,
                design=dict(network_cells=count, plants=len(leaves)-1,
                            branches=cells.count('tee'), solution_taps=taps,
                            difficulty_score=score, seed=seed))

def main():
    authored = []
    # Increasing occupied area; long winding paths, then more branches.
    for offset in range(200):
        if offset < 30:
            n, count, lo, hi = 5, 25, 5, 6
        elif offset < 110:
            n, count, lo, hi = 6, 26+(offset-30)*10//79, 5, 8
        else:
            n, count, lo, hi = 7, 37+(offset-110)*12//89, 7, 10
        authored.append(candidate(250000+offset, n, count, lo, hi))
    authored.sort(key=lambda level: (level['size'], level['design']['difficulty_score']))
    fingerprints = set()
    for number, level in enumerate(authored, 51):
        level['id'] = number
        fingerprint = json.dumps([level['cells'], level['start']])
        assert fingerprint not in fingerprints
        fingerprints.add(fingerprint)
        (ROOT/'levels'/f'{number:02}.json').write_text(json.dumps(level, indent=2)+'\n', encoding='utf-8')
    with (ROOT/'docs'/'level-difficulty.csv').open('w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['level', 'size', 'network_cells', 'plants', 'branches', 'solution_taps', 'difficulty_score'])
        for level in authored:
            d = level['design']
            writer.writerow([level['id'], level['size']]+[d[k] for k in ['network_cells','plants','branches','solution_taps','difficulty_score']])
    print('Authored 200 unique levels, 51-250. Levels 1-50 untouched.')

if __name__ == '__main__':
    main()
