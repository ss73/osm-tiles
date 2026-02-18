# Research: Protomaps Evaluation

**Feature Branch**: `002-protomaps-evaluation`
**Date**: 2026-02-18

## R1: Tile Schema Compatibility

**Decision**: Protomaps tiles use the Tilezen-derived schema (v4), not OpenMapTiles. Existing styles cannot be reused.

**Rationale**: The Protomaps Planetiler profile produces tiles with fundamentally different layer names (`roads` vs `transportation`, `places` vs `place`) and property conventions (`kind`/`kind_detail` vs `class`/`subclass`). Schema remapping would be fragile and defeat the purpose of an evaluation.

**Alternatives considered**:
- Remap OpenMapTiles styles to Tilezen schema — rejected (brittle, high effort, not a fair comparison)
- Generate Protomaps-schema tiles locally with Planetiler — rejected (user specified using public tiles)

## R2: Tile Source

**Decision**: Use the publicly available Protomaps daily planet build via `pmtiles://` protocol. For demos, the Florence extract (`pmtiles.io`) is suitable as a fallback.

**Rationale**: The daily builds at `build.protomaps.com` provide full planet coverage at zoom 0–15. The `pmtiles` JS library handles range requests transparently. No need to generate or host tiles ourselves for an evaluation.

**Alternatives considered**:
- Download and self-host a PMTiles extract — possible but unnecessary for evaluation
- Generate tiles with the Protomaps Planetiler profile — rejected per user requirements (no self-generation unless advantageous)

**Note**: Protomaps warns against hotlinking daily build URLs as they may change. For a PoC this is acceptable; production use would require copying to own storage.

**CORS limitation**: `build.protomaps.com` does **not** set `Access-Control-Allow-Origin` headers, so browsers cannot fetch tiles directly from this URL. A CORS proxy or self-hosted copy is required for browser-based access.

**User-Agent blocking**: `build.protomaps.com` returns HTTP 403 for requests with Python's default `Python-urllib` User-Agent. Any proxy must set a browser-like User-Agent header.

## R3: Style Approach

**Decision**: Use the `@protomaps/basemaps` CDN bundle (v5.x) which provides 5 programmatic flavors: light, dark, white, black, grayscale.

**Rationale**: The basemaps package generates complete MapLibre style layers arrays from a single function call. This is simpler than building styles from scratch in Maputnik and guarantees compatibility with the Tilezen tile schema. Styles are generated at runtime via `basemaps.layers("source", basemaps.namedFlavor("light"))`.

**Alternatives considered**:
- Build styles from scratch in Maputnik — rejected (high effort, Protomaps layers/properties are complex)
- Export basemaps styles to static JSON and customize in Maputnik — viable future enhancement, not needed for initial evaluation

## R4: Serving Model

**Decision**: No tile server required. The `pmtiles` JS library registers a custom protocol handler with MapLibre GL JS, fetching tiles via HTTP range requests directly from the PMTiles file.

**Rationale**: This is the core architectural difference from Martin. The PMTiles JS library handles range requests transparently in the browser.

**Caveat**: In practice, the tile source must serve CORS headers (`Access-Control-Allow-Origin`). Since `build.protomaps.com` does not, a local CORS proxy (`protomaps/serve.py`) is needed for development. In production, self-hosting the PMTiles file on CORS-enabled storage (Cloudflare R2, S3, Nginx, etc.) eliminates this issue.

**Alternatives considered**:
- Use a PMTiles-aware server (e.g., go-pmtiles) — unnecessary for client-side rendering
- Proxy through Martin (which supports PMTiles) — defeats the purpose of evaluating the serverless model

## R5: CDN Dependencies

**Decision**: Use unpkg CDN for all JS libraries (no build tooling).

| Library | Version | CDN URL |
|---------|---------|---------|
| MapLibre GL JS | 5.x | `unpkg.com/maplibre-gl@5/dist/maplibre-gl.js` |
| pmtiles | 4.4.0 | `unpkg.com/pmtiles@4.4.0/dist/pmtiles.js` |
| @protomaps/basemaps | 5.x | `unpkg.com/@protomaps/basemaps@5/dist/basemaps.js` |

**Global variables**: `maplibregl`, `pmtiles`, `basemaps`

## R6: Sprite and Font Assets

**Decision**: Use Protomaps-hosted assets from GitHub Pages (basemaps-assets repo).

- **Glyphs**: `https://protomaps.github.io/basemaps-assets/fonts/{fontstack}/{range}.pbf`
- **Sprites**: `https://protomaps.github.io/basemaps-assets/sprites/v4/<flavor>`

**Rationale**: Self-hosting these assets is unnecessary for an evaluation. The GitHub Pages URLs are stable and public.

## R7: Directory Separation

**Decision**: All Protomaps assets go under `protomaps/` at the project root, mirroring the existing top-level structure but fully isolated.

```
protomaps/
├── examples/
│   └── maplibre-demo.html    # Standalone PoC demo
└── README.md                 # Protomaps-specific documentation
```

**Rationale**: User explicitly requested separation from existing Martin/Planetiler assets. A top-level `protomaps/` directory is clean, discoverable, and can be deleted without affecting anything else.
