#!/usr/bin/env python3
"""Dev server that serves local files and proxies PMTiles requests with CORS.

Supports a special /tiles/latest.pmtiles path that auto-resolves to the most
recent daily build on build.protomaps.com (tries today, then up to 7 days back).

Includes a disk-based cache for proxied tile responses that persists across
server restarts.
"""

import http.server
import urllib.request
import ssl
import sys
import os
import json
import hashlib
from datetime import date, timedelta

ssl_ctx = ssl.create_default_context()
ssl_ctx.check_hostname = False
ssl_ctx.verify_mode = ssl.CERT_NONE

PMTILES_UPSTREAM = "https://build.protomaps.com"
UA = "Mozilla/5.0 (pmtiles-proxy)"
CACHE_DIR = os.path.join(os.path.dirname(__file__) or ".", ".cache")

# Cache the resolved latest build date to avoid repeated HEAD requests
_latest_cache = {"date": None, "checked": None}


def _cache_path(filename, range_header):
    """Return a unique file path for this (filename, range) pair."""
    key = f"{filename}|{range_header or 'full'}"
    h = hashlib.sha256(key.encode()).hexdigest()[:16]
    subdir = os.path.join(CACHE_DIR, filename.replace(".pmtiles", ""))
    return os.path.join(subdir, h)


def cache_get(filename, range_header):
    path = _cache_path(filename, range_header)
    meta_path = path + ".meta"
    data_path = path + ".data"
    if os.path.exists(meta_path) and os.path.exists(data_path):
        with open(meta_path) as f:
            meta = json.load(f)
        with open(data_path, "rb") as f:
            body = f.read()
        return meta["status"], meta["headers"], body
    return None


def cache_put(filename, range_header, status, headers, body):
    path = _cache_path(filename, range_header)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path + ".data", "wb") as f:
        f.write(body)
    with open(path + ".meta", "w") as f:
        json.dump({"status": status, "headers": headers}, f)


def resolve_latest():
    """Find the most recent daily build by trying today, then up to 7 days back."""
    today = date.today()
    if _latest_cache["checked"] == today and _latest_cache["date"]:
        return _latest_cache["date"]
    for days_ago in range(8):
        d = today - timedelta(days=days_ago)
        filename = d.strftime("%Y%m%d") + ".pmtiles"
        url = f"{PMTILES_UPSTREAM}/{filename}"
        req = urllib.request.Request(url, method="HEAD")
        req.add_header("User-Agent", UA)
        try:
            resp = urllib.request.urlopen(req, context=ssl_ctx)
            if resp.status == 200:
                _latest_cache["date"] = filename
                _latest_cache["checked"] = today
                print(f"Resolved latest build: {filename}")
                return filename
        except urllib.error.HTTPError:
            continue
    return None


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
        if filename == "latest.pmtiles":
            filename = resolve_latest()
            if not filename:
                self.send_response(502)
                self.end_headers()
                self.wfile.write(b"Could not resolve latest build")
                return

        range_header = self.headers.get("Range")

        cached = cache_get(filename, range_header)
        if cached:
            status, headers, body = cached
            self.send_response(status)
            for k, v in headers.items():
                self.send_header(k, v)
            self.end_headers()
            self.wfile.write(body)
            return

        url = f"{PMTILES_UPSTREAM}/{filename}"
        req = urllib.request.Request(url)
        req.add_header("User-Agent", UA)
        if range_header:
            req.add_header("Range", range_header)
        try:
            resp = urllib.request.urlopen(req, context=ssl_ctx)
            status = resp.status
            headers = {}
            for key in ("Content-Type", "Content-Length", "Content-Range", "Accept-Ranges", "ETag"):
                val = resp.headers.get(key)
                if val:
                    headers[key] = val
            body = resp.read()
            cache_put(filename, range_header, status, headers, body)
            self.send_response(status)
            for k, v in headers.items():
                self.send_header(k, v)
            self.end_headers()
            self.wfile.write(body)
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            self.end_headers()


port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
print(f"Serving protomaps/ on http://localhost:{port}")
print(f"Proxying /tiles/* → {PMTILES_UPSTREAM}")
print(f"Use /tiles/latest.pmtiles for auto-resolved daily build")
print(f"Disk cache: {CACHE_DIR}")
http.server.HTTPServer(("", port), CORSProxyHandler).serve_forever()
