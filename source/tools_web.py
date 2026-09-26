"""Polish the Godot web export; no third-party Python packages required."""
from pathlib import Path
import gzip
import hashlib
import json

root = Path(__file__).parent / 'web-site' / 'dist'
page = root / 'index.html'
pack_version = hashlib.sha256((root/'index.pck').read_bytes()).hexdigest()[:12]
html = page.read_text(encoding='utf-8')
html = html.replace('<html lang="en">', '<html lang="ru">')
html = html.replace('<title>Сад света</title>', '<title>Сад Джека</title>')
html = html.replace('<div id="status">', '<div id="status" aria-label="Загрузка игры Сад Джека">')
html = html.replace('<progress id="status-progress"></progress>', '<progress id="status-progress" aria-label="Загрузка игры"></progress><div id="status-caption">Сад расцветает…</div>')
html = html.replace('<script src="index.js"></script>', '''<script>
// Keep the engine below the host's per-file limit and reduce mobile downloads.
const originalFetch = window.fetch.bind(window);
window.fetch = async function(input, options) {
  const url = typeof input === 'string' ? input : input.url;
  if (url && new URL(url, location.href).pathname.endsWith('/index.pck')) {
    return originalFetch(new URL('index.pck?v=PACK_VERSION', location.href), options);
  }
  if (url && new URL(url, location.href).pathname.endsWith('/index.wasm')) {
    if (!('DecompressionStream' in window)) {
      throw new Error('Обновите Safari / iOS для запуска игры (iOS 16.4 или новее).');
    }
    const response = await originalFetch(new URL('index.wasm.gz', location.href), options);
    if (!response.ok) throw new Error('Не удалось загрузить игру. Проверьте интернет и обновите страницу.');
    return new Response(response.body.pipeThrough(new DecompressionStream('gzip')), {
      headers: {'Content-Type': 'application/wasm'}
    });
  }
  return originalFetch(input, options);
};
</script><script src="index.js"></script>''')
html = html.replace('</head>', '''<meta name="theme-color" content="#0e211d">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-title" content="Сад Джека">
<meta name="description" content="Сад Джека: уютный сад, дорожки света и цветочное три в ряд. Два режима и 500 бесплатных уровней.">
<style>
body, #status {background:#0c3028}
#status {visibility:visible}
#status-splash.fullsize--true {object-fit:contain}
@media (max-aspect-ratio:3/4) {#status-splash.fullsize--true {object-fit:cover}}
#status-progress {z-index:2;bottom:6%;width:min(68%,320px);height:11px;border:2px solid #e8ce86;border-radius:20px;overflow:hidden;accent-color:#f2d879;background:#164b3b;box-shadow:0 3px 14px #092b27}
#status-progress::-webkit-progress-bar {background:#164b3b}
#status-progress::-webkit-progress-value {background:linear-gradient(90deg,#dcae58,#ffe6a0)}
#status-caption {position:absolute;z-index:2;bottom:2%;left:0;right:0;text-align:center;font:600 16px Georgia,serif;letter-spacing:.04em;color:#fff1ce;text-shadow:0 2px 5px #123629}
</style>
</head>''')
page.write_text(html.replace('PACK_VERSION',pack_version), encoding='utf-8')
manifest = root / 'index.manifest.json'
manifest_data = json.loads(manifest.read_text(encoding='utf-8'))
manifest_data.update({'name':'Сад Джека','short_name':'Сад Джека','orientation':'portrait','background_color':'#0c3028','theme_color':'#0c3028'})
manifest.write_text(json.dumps(manifest_data,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
wasm = root / 'index.wasm'
(root / 'index.wasm.gz').write_bytes(gzip.compress(wasm.read_bytes(), mtime=0))
wasm.unlink()
worker = root / 'index.service.worker.js'
worker_text = worker.read_text(encoding='utf-8').replace('"index.wasm"', '"index.wasm.gz"')
worker_text = worker_text.replace('"index.pck"', '"index.pck?v='+pack_version+'"')
worker_text = worker_text.replace('"index.html","index.js"', '"index.html","index.png","index.manifest.json","index.js"')
# Activate a completed update even if another game tab remains open. Saved
# progress lives in IndexedDB, separately from this disposable asset cache.
worker_text = worker_text.replace('cache.addAll(CACHED_FILES)))',
                                  'cache.addAll(CACHED_FILES)).then(() => self.skipWaiting()))')
worker.write_text(worker_text, encoding='utf-8')
print('Web export ready:', root)
