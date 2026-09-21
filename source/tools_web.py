"""Polish the Godot web export; no third-party Python packages required."""
from pathlib import Path
import gzip

root = Path(__file__).parent / 'web-site' / 'dist'
page = root / 'index.html'
html = page.read_text(encoding='utf-8')
html = html.replace('<html lang="en">', '<html lang="ru">')
html = html.replace('<script src="index.js"></script>', '''<script>
// Keep the engine below the host's per-file limit and reduce mobile downloads.
const originalFetch = window.fetch.bind(window);
window.fetch = async function(input, options) {
  const url = typeof input === 'string' ? input : input.url;
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
<meta name="apple-mobile-web-app-title" content="Сад света">
<meta name="description" content="Сад света: дорожки света и цветочное три в ряд. Два режима, 500 бесплатных уровней, звуки природы.">
<style>body {background:#0e211d} #status {background:#0e211d}
#status-progress {accent-color:#e6ca8e}</style>
</head>''')
page.write_text(html, encoding='utf-8')
wasm = root / 'index.wasm'
(root / 'index.wasm.gz').write_bytes(gzip.compress(wasm.read_bytes(), mtime=0))
wasm.unlink()
worker = root / 'index.service.worker.js'
worker_text = worker.read_text(encoding='utf-8').replace('"index.wasm"', '"index.wasm.gz"')
# Activate a completed update even if another game tab remains open. Saved
# progress lives in IndexedDB, separately from this disposable asset cache.
worker_text = worker_text.replace('cache.addAll(CACHED_FILES)))',
                                  'cache.addAll(CACHED_FILES)).then(() => self.skipWaiting()))')
worker.write_text(worker_text, encoding='utf-8')
print('Web export ready:', root)
