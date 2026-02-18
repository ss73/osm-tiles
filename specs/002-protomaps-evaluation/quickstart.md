# Quickstart: Protomaps Evaluation

**Feature Branch**: `002-protomaps-evaluation`

## Prerequisites

- A modern web browser (Chrome, Firefox, Safari, Edge)
- Python 3 (for the included dev server with CORS proxy)

No Docker, no tile server, no tile generation required.

## Run the Demo

1. Start the dev server from the protomaps directory:

   ```bash
   python3 protomaps/serve.py
   ```

   This serves local files and proxies `/tiles/*` requests to `build.protomaps.com`
   with CORS headers added.

2. Open the demo in your browser:

   ```
   http://localhost:8080/examples/maplibre-demo.html
   ```

3. The map loads tiles via the CORS proxy. No Martin container needed.

### Why a proxy?

`build.protomaps.com` does **not** set CORS headers, so browsers block direct
range-request fetches. The dev server (`serve.py`) proxies tile requests and adds
the required `Access-Control-Allow-Origin` header. It also sets a browser-like
User-Agent, since the upstream server rejects Python's default UA with HTTP 403.

In production, you would self-host the PMTiles file on CORS-enabled storage
(Cloudflare R2, S3, Nginx, etc.) and point the demo directly at it — no proxy
needed.

## What to Evaluate

- **Visual quality**: Compare layer rendering (roads, buildings, labels, land cover) with the existing Martin-served demo at `examples/maplibre-demo.html`
- **Style variety**: Use the style switcher to cycle through light, dark, white, black, and grayscale themes
- **Performance**: Note initial load time and tile loading speed when panning/zooming
- **Feature inspection**: Click any map feature to inspect its layer and properties (note the Tilezen schema differences from OpenMapTiles)
- **Serverless model**: Observe that no tile server process is running — tiles are fetched via range requests

## Key Differences from Current Setup

| Aspect | Current (Martin) | Protomaps (PMTiles) |
|--------|------------------|---------------------|
| Tile server | Martin container required | None — client-side range requests |
| Tile schema | OpenMapTiles | Tilezen-derived (Protomaps v4) |
| Tile source | Local MBTiles file | Remote PMTiles URL |
| Styles | Static JSON (osm-liberty, positron, etc.) | Generated at runtime by basemaps JS |
| Fonts/sprites | Self-hosted via Martin | Protomaps GitHub Pages CDN |
| Setup effort | Docker + tile generation | Open HTML file |

## Troubleshooting

- **Blank map / CORS errors**: Make sure you're using `serve.py`, not a plain `python3 -m http.server`. The proxy adds required CORS headers for upstream tile requests.
- **HTTP 403 from proxy**: The upstream (`build.protomaps.com`) blocks non-browser User-Agents. The proxy sets one automatically — if you write your own, include a `User-Agent` header.
- **Expired tile URL**: Daily builds are retained for ~1 week. If the URL in the demo 404s, update the date in `PMTILES_URL` to a recent date (check [maps.protomaps.com/builds](https://maps.protomaps.com/builds/)).
- **Missing labels**: Ensure the glyphs URL is reachable (`protomaps.github.io`).
- **Slow loading**: The first load fetches the PMTiles header (~16 KB) and then individual tiles. Subsequent views are faster due to browser caching.
