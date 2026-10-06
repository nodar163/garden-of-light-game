"""Append fixed levels; the released first 250 levels are never rewritten."""
import json
from pathlib import Path
from tools_expansion import candidate

ROOT = Path(__file__).parent

def main():
    levels = []
    for offset in range(750):
        level = candidate(810000 + offset, 7, 49, 7, 12)
        levels.append(level)
    levels.sort(key=lambda x: x['design']['difficulty_score'])
    for number, level in enumerate(levels, 251):
        level['id'] = number
        (ROOT / 'levels' / f'{number:02}.json').write_text(json.dumps(level, ensure_ascii=False) + '\n', encoding='utf-8')
    print('Added 750 unique authored light boards; first 250 preserved.')

if __name__ == '__main__':
    main()
