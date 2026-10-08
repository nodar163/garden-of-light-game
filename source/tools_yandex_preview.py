"""Local integration test with a fake SDK. No real advertisements or payouts."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

root = Path(__file__).parent
class Preview(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(root/'artifacts/yandex-build'), **kwargs)
    def do_GET(self):
        if self.path.split('?')[0] == '/sdk.js':
            data=(root/'tests/yandex_mock.js').read_bytes()
            self.send_response(200); self.send_header('Content-Type','application/javascript')
            self.send_header('Content-Length',str(len(data))); self.end_headers(); self.wfile.write(data)
        else:
            super().do_GET()
if __name__ == '__main__':
    ThreadingHTTPServer(('127.0.0.1',8778),Preview).serve_forever()
