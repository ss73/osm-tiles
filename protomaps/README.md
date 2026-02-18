# Protomaps Evaluation

Proof-of-concept evaluating [Protomaps](https://protomaps.com) as an alternative
to the current Martin + Planetiler tile serving stack.

## Key Differences from Current Setup

| Aspect | Current (Martin) | Protomaps (PMTiles) |
|--------|------------------|---------------------|
| Tile server | Martin container required | None — client-side range requests |
| Tile schema | OpenMapTiles | Tilezen-derived (Protomaps v4) |
| Tile source | Local MBTiles file | Remote PMTiles URL |
| Styles | Static JSON (osm-liberty, positron, etc.) | Generated at runtime by `@protomaps/basemaps` |
| Fonts/sprites | Self-hosted via Martin | Protomaps GitHub Pages CDN |
| Setup effort | Docker + tile generation | Open HTML file |

## How to Run

No Docker, no tile server, no tile generation required.

1. Start the dev server (includes CORS proxy for upstream tiles):

   ```bash
   python3 protomaps/serve.py
   ```

2. Open the demo:

   ```
   http://localhost:8080/examples/maplibre-demo.html
   ```

### Why a proxy instead of a plain HTTP server?

`build.protomaps.com` does **not** set CORS headers, so browsers block direct
tile fetches. The dev server proxies `/tiles/*` requests to the upstream and adds
the required `Access-Control-Allow-Origin` header. It also sets a browser-like
User-Agent, since the upstream returns HTTP 403 for Python's default UA.

In production, you'd self-host the PMTiles file on CORS-enabled storage
(Cloudflare R2, S3, Nginx, etc.) and point the demo directly at it.

## What's Here

```
protomaps/
├── examples/
│   └── maplibre-demo.html    # MapLibre GL JS demo with PMTiles
├── serve.py                  # Dev server with CORS proxy
└── README.md                 # This file
```

## Tile Schema Note

Protomaps uses the **Tilezen** tile schema, which is fundamentally different from
the **OpenMapTiles** schema used by the current Martin/Planetiler setup:

- Layer names differ: `roads` vs `transportation`, `places` vs `place`
- Property names differ: `kind`/`kind_detail` vs `class`/`subclass`
- Existing styles (osm-liberty, positron, dark-matter, blue-dark) are **not compatible**

The demo uses `@protomaps/basemaps` which provides styles purpose-built for the
Tilezen schema: light, dark, white, black, and grayscale.

## Tile Source

The demo uses a publicly available Protomaps daily planet build. These are
published at [maps.protomaps.com/builds](https://maps.protomaps.com/builds/)
and provide world coverage at zoom levels 0–15 (~120 GB).

For production use, Protomaps recommends copying the PMTiles file to your own
storage rather than hotlinking their build server.
