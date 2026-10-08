"""Create a separate upload archive; GitHub Pages stays free of ads and SDK."""
from pathlib import Path
import json
import shutil
import zipfile

root = Path(__file__).parent
source = root / 'web-site/dist'
target = root / 'artifacts/yandex-build'
target.mkdir(parents=True, exist_ok=True)
# Only necessary runtime files; never copy credentials, saves or test SDK mocks.
names = ['index.html', 'index.js', 'index.pck', 'index.wasm.gz', 'index.png',
         'index.icon.png', 'index.audio.worklet.js', 'index.audio.position.worklet.js']
for name in names:
    if (source / name).exists():
        shutil.copy2(source / name, target / name)
shutil.copy2(root / 'platform/yandex_bridge.js', target / 'yandex_bridge.js')
html = (target / 'index.html').read_text(encoding='utf-8')
html = html.replace('<script src="index.js"></script>',
                    '<script src="yandex_bridge.js"></script><script src="index.js"></script>')
html = html.replace('"serviceWorker":"index.service.worker.js"', '"serviceWorker":""')
html = html.replace('<link rel="manifest" href="index.manifest.json">', '')
html = html.replace('Два режима и 500 бесплатных уровней.', 'Два режима, 2000 уровней и восстановление сада.')
(target / 'index.html').write_text(html, encoding='utf-8')
archive = root / 'artifacts/jacks-garden-yandex.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as package:
    for name in names + ['yandex_bridge.js']:
        if (target / name).exists():
            package.write(target / name, name)
print(f'Yandex upload archive: {archive} ({archive.stat().st_size:,} bytes)')
