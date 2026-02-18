#!/usr/bin/env python3
"""Dev server that serves local files and proxies PMTiles requests with CORS."""

import http.server
import urllib.request
import ssl
import sys
import os

ssl_ctx = ssl.create_default_context()
ssl_ctx.check_hostname = False
ssl_ctx.verify_mode = ssl.CERT_NONE

PMTILES_UPSTREAM = "https://build.protomaps.com"

class CORSProxyHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=os.path.dirname(__file__) or ".", **kwargs)

    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Range")
        self.send_header("Access-Control-Expose-Headers", "Content-Length, Content-Range, Accept-Ranges")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        if self.path.startswith("/tiles/"):
            self._proxy(self.path[len("/tiles/"):])
        else:
            super().do_GET()

    def _proxy(self, filename):
        url = f"{PMTILES_UPSTREAM}/{filename}"
        req = urllib.request.Request(url)
        req.add_header("User-Agent", "Mozilla/5.0 (pmtiles-proxy)")
        range_header = self.headers.get("Range")
        if range_header:
            req.add_header("Range", range_header)
        try:
            resp = urllib.request.urlopen(req, context=ssl_ctx)
            self.send_response(resp.status)
            for key in ("Content-Type", "Content-Length", "Content-Range", "Accept-Ranges", "ETag"):
                val = resp.headers.get(key)
                if val:
                    self.send_header(key, val)
            self.end_headers()
            while chunk := resp.read(65536):
                self.wfile.write(chunk)
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            self.end_headers()

port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
print(f"Serving protomaps/ on http://localhost:{port}")
print(f"Proxying /tiles/* → {PMTILES_UPSTREAM}")
http.server.HTTPServer(("", port), CORSProxyHandler).serve_forever()
