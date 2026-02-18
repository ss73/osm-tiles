#!/usr/bin/env python3
"""Dev server that serves local PMTiles files or proxies from upstream.

By default, serves local tiles from data/planet-latest.pmtiles if present.
Use --proxy to force proxying from build.protomaps.com instead.

Supports a special /tiles/latest.pmtiles path that resolves to either the
local file or the most recent upstream daily build (depending on mode).

Includes a disk-based cache for proxied tile responses that persists across
server restarts.
"""

import argparse
import http.server
import urllib.request
import ssl
import os
import json
import hashlib
from datetime import date, timedelta

ssl_ctx = ssl.create_default_context()
ssl_ctx.check_hostname = False
ssl_ctx.verify_mode = ssl.CERT_NONE

PMTILES_UPSTREAM = "https://build.protomaps.com"
UA = "Mozilla/5.0 (pmtiles-proxy)"
BASE_DIR = os.path.dirname(__file__) or "."
DATA_DIR = os.path.join(BASE_DIR, "data")
CACHE_DIR = os.path.join(BASE_DIR, ".cache")
LOCAL_TILE = os.path.join(DATA_DIR, "planet-latest.pmtiles")

# Runtime config — set in main()
_config = {"proxy": False}

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


class CORSHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=BASE_DIR, **kwargs)

    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Range")
        self.send_header("Access-Control-Expose-Headers", "Content-Length, Content-Range, Accept-Ranges")
        super().end_headers()

    def handle_one_request(self):
        try:
            super().handle_one_request()
        except (BrokenPipeError, ConnectionResetError):
            pass

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        if self.path.startswith("/tiles/"):
            filename = self.path[len("/tiles/"):]
            if _config["proxy"]:
                self._proxy(filename)
            else:
                self._serve_local(filename)
        else:
            super().do_GET()

    def _serve_local(self, filename):
        """Serve a PMTiles file from the local data directory with Range support."""
        if filename == "latest.pmtiles":
            filepath = LOCAL_TILE
        else:
            filepath = os.path.join(DATA_DIR, filename)

        # Resolve symlinks for existence check
        try:
            real_path = os.path.realpath(filepath)
        except OSError:
            real_path = filepath

        if not os.path.isfile(real_path):
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Not found")
            return

        file_size = os.path.getsize(real_path)
        range_header = self.headers.get("Range")

        if range_header:
            # Parse Range: bytes=START-END
            try:
                range_spec = range_header.replace("bytes=", "")
                parts = range_spec.split("-")
                start = int(parts[0]) if parts[0] else 0
                end = int(parts[1]) if parts[1] else file_size - 1
                end = min(end, file_size - 1)
                length = end - start + 1
            except (ValueError, IndexError):
                self.send_response(416)
                self.send_header("Content-Range", f"bytes */{file_size}")
                self.end_headers()
                return

            with open(real_path, "rb") as f:
                f.seek(start)
                body = f.read(length)

            self.send_response(206)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Length", str(length))
            self.send_header("Content-Range", f"bytes {start}-{end}/{file_size}")
            self.send_header("Accept-Ranges", "bytes")
            self.end_headers()
            try:
                self.wfile.write(body)
            except (BrokenPipeError, ConnectionResetError):
                pass
        else:
            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Length", str(file_size))
            self.send_header("Accept-Ranges", "bytes")
            self.end_headers()
            try:
                with open(real_path, "rb") as f:
                    while chunk := f.read(65536):
                        self.wfile.write(chunk)
            except (BrokenPipeError, ConnectionResetError):
                pass

    def _proxy(self, filename):
        """Proxy a tile request to the upstream Protomaps build server."""
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
            try:
                self.wfile.write(body)
            except (BrokenPipeError, ConnectionResetError):
                pass
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
        except (BrokenPipeError, ConnectionResetError):
            pass


parser = argparse.ArgumentParser(description="Protomaps dev server")
parser.add_argument("-p", "--port", type=int, default=8080, help="port (default: 8080)")
parser.add_argument("--proxy", action="store_true", help="proxy tiles from upstream instead of serving local files")
args = parser.parse_args()

_config["proxy"] = args.proxy

has_local = os.path.isfile(LOCAL_TILE) or os.path.islink(LOCAL_TILE)
if args.proxy:
    mode = "proxy"
elif has_local:
    real = os.path.realpath(LOCAL_TILE)
    mode = f"local ({os.path.basename(real)})"
else:
    _config["proxy"] = True
    mode = "proxy (no local tile found)"

print(f"Serving protomaps/ on http://localhost:{args.port}")
print(f"Tile mode: {mode}")
if _config["proxy"]:
    print(f"Proxying /tiles/* → {PMTILES_UPSTREAM}")
    print(f"Disk cache: {CACHE_DIR}")
else:
    print(f"Serving /tiles/* from {DATA_DIR}")
http.server.HTTPServer(("", args.port), CORSHandler).serve_forever()
