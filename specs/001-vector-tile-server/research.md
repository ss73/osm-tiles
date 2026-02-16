# Research: Self-Hosted Vector Tile Server

**Date**: 2026-02-16
**Feature**: 001-vector-tile-server

## Decision 1: Tile Generation Tool

**Decision**: Planetiler

**Rationale**: Fastest option by a wide margin. A Sweden extract (~753 MB
PBF) generates in minutes. Single Docker command or JAR invocation —
no database, no multi-container orchestration. Native MBTiles and PMTiles
output. Built-in OpenMapTiles schema profile ensures immediate
compatibility with MapLibre styles.

**Alternatives considered**:

| Tool | Verdict | Trade-off |
|------|---------|-----------|
| tilemaker | Viable runner-up | 2-4x slower, higher RAM, OpenMapTiles schema is "best-effort" not exact |
| OpenMapTiles pipeline | Too complex | Requires PostgreSQL + Docker Compose with 5+ containers. Overkill for static tile generation. Only choose if incremental diff updates are required |

**Key details**:
- Docker image: `ghcr.io/onthegomap/planetiler:latest`
- v0.10.0 (Feb 2026), 1,944 GitHub stars, Apache-2.0
- RAM for Sweden: ~1-2 GB
- Output format selected by filename extension (`--output=file.pmtiles`)
- `--download --area=sweden` auto-fetches Geofabrik extract

## Decision 2: Tile Server

**Decision**: Martin

**Rationale**: Single Rust binary serves all four resource types MapLibre
GL JS requires — tiles, style JSON, font glyphs (generated on-the-fly
from TTF/OTF), and sprite sheets (generated on-the-fly from SVGs).
Docker image is ~12 MB. Near-zero configuration: a single CLI command
serves everything. Part of the official MapLibre organization.

**Alternatives considered**:

| Tool | Verdict | Trade-off |
|------|---------|-----------|
| tileserver-gl | Strong runner-up | Best built-in preview UI, but heavier (Node.js), more complex config, larger Docker image, slower under load |
| TileServer PHP | Eliminated | Archived July 2025. Cannot serve styles, fonts, or sprites |
| Static nginx/Caddy + PMTiles | Eliminated | Cannot serve MBTiles, requires pre-generating all fonts and sprites externally |

**Key details**:
- Docker image: `ghcr.io/maplibre/martin`
- v1.3.1 (Feb 2026), 3,400 GitHub stars, Apache-2.0
- CLI: `martin tiles.mbtiles --font ./fonts --sprite ./sprites`
- Supports MBTiles, PMTiles, and PostGIS sources
- Dynamic font PBF generation from OTF/TTF files
- Dynamic sprite sheet generation from SVG directories

## Decision 3: Base Map Style

**Decision**: OSM Liberty (primary), with Positron and Dark Matter as
light/dark variants.

**Rationale**: OSM Liberty is the best general-purpose OpenMapTiles style
— good visual quality, Maki POI icons, Roboto/Noto fonts, actively
maintained by the Maputnik community. Positron and Dark Matter provide
clean light/dark alternatives for data visualization. All three are
BSD/CC-BY licensed and fully self-hostable.

**Alternatives considered**:

| Style | Verdict | Trade-off |
|-------|---------|-----------|
| OSM Bright | Viable | Canonical OpenMapTiles style but less polished visually |
| Protomaps basemaps | Incompatible | Uses own tile schema, not OpenMapTiles. Beautiful 5-theme system but requires different tiles |

**Key details**:
- OSM Liberty: BSD-3 + CC-BY 4.0, github.com/maputnik/osm-liberty
- Positron: BSD-3 + CC-BY 4.0, github.com/openmaptiles/positron-gl-style
- Dark Matter: BSD-3 + CC0, github.com/openmaptiles/dark-matter-gl-style

## Decision 4: Fonts

**Decision**: Noto Sans (Regular + Bold), served dynamically by Martin
from TTF files. No pre-generation needed.

**Rationale**: Martin generates PBF glyph ranges on-the-fly from
TTF/OTF files, eliminating the font build pipeline. Noto Sans is the
de facto standard for OSM map styles with wide script coverage (Latin,
Cyrillic, Greek).

**Alternatives considered**:

| Approach | Verdict | Trade-off |
|----------|---------|-----------|
| Pre-built openmaptiles/fonts package | Viable fallback | Static PBF files, no build needed, but no dynamic generation and font stack fallback requires composite files |
| build_pbf_glyphs (Rust) | Not needed | Good tool if pre-generation is required, but Martin eliminates the need |

## Decision 5: Sprites

**Decision**: Use SVG icons from OSM Liberty's Maki icon set, served
dynamically by Martin from an SVG directory.

**Rationale**: Martin generates sprite sheets (PNG + JSON at 1x and 2x)
on-the-fly from SVG directories. This eliminates the sprite build
pipeline and makes adding/removing icons a simple file operation.

**Alternatives considered**:

| Approach | Verdict | Trade-off |
|----------|---------|-----------|
| spreet (Rust CLI) | Viable fallback | Excellent tool for static sprite generation if dynamic serving is not available |
| spritezero (Node.js) | Not needed | Original Mapbox tool, heavier dependency chain |

## Decision 6: Leaflet Vector Tile Plugin

**Decision**: maplibre-gl-leaflet

**Rationale**: The only Leaflet plugin that supports MapLibre Style Spec
JSON. Embeds a MapLibre GL JS renderer inside a Leaflet map, enabling
full style reuse across both client targets. v0.1.3 (Aug 2025), actively
maintained under the MapLibre organization.

**Alternatives considered**:

| Plugin | Verdict | Trade-off |
|--------|---------|-----------|
| protomaps-leaflet | Eliminated | Does not support MapLibre Style Spec JSON (removed in v2.0) |
| Leaflet.VectorGrid | Eliminated | Last npm release 8 years ago. No MapLibre style support. Designed for overlay layers, not basemaps |

## Decision 7: Tile Storage Format

**Decision**: MBTiles for initial deployment, with PMTiles as a future
option.

**Rationale**: MBTiles (SQLite) is the most widely supported format
across the toolchain. Both Planetiler and Martin support it natively.
PMTiles is a good future option for cloud/CDN hosting but adds no
benefit for a single-server deployment. Planetiler can generate either
format by changing the output filename extension.
