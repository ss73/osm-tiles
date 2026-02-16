# API Endpoints: Self-Hosted Vector Tile Server

**Date**: 2026-02-16
**Feature**: 001-vector-tile-server

## Overview

All endpoints are served by Martin from a single origin. No custom
API code — these are Martin's built-in endpoints configured via CLI
flags and file layout.

## Tile Endpoints

### GET `/{tileset_name}/{z}/{x}/{y}`

Serves a single vector tile.

- **Response**: MVT/PBF binary (`application/x-protobuf`)
- **Parameters**:
  - `tileset_name`: MBTiles source name (derived from filename)
  - `z`: Zoom level (0–14)
  - `x`: Tile column
  - `y`: Tile row
- **Success**: 200 with tile data
- **Empty tile**: 204 No Content (outside coverage or no data)
- **Invalid coordinates**: 404

### GET `/{tileset_name}`

Returns TileJSON metadata for the tileset.

- **Response**: JSON (`application/json`)
- **Content**: Layer names, zoom range, bounds, tile URL template,
  attribution

## Style Endpoints

### GET `/catalog`

Returns a list of all available sources, styles, fonts, and sprites.

- **Response**: JSON catalog of available resources

### GET `/style/{style_name}`

Returns a MapLibre Style Spec JSON document.

- **Response**: JSON (`application/json`)
- **Content**: Complete style with `sources`, `layers`, `glyphs`,
  and `sprite` URLs pointing to this server

## Font Endpoints

### GET `/font/{fontstack}/{range}`

Returns PBF-encoded glyph ranges for text rendering.

- **Response**: PBF binary (`application/x-protobuf`)
- **Parameters**:
  - `fontstack`: Font name (e.g., `Noto Sans Regular`)
  - `range`: Glyph range (e.g., `0-255`)
- **Generated on-the-fly** from TTF/OTF files in the fonts directory

## Sprite Endpoints

### GET `/sprite/{sprite_name}.json`

Returns sprite index JSON (1x).

### GET `/sprite/{sprite_name}.png`

Returns sprite sheet image (1x).

### GET `/sprite/{sprite_name}@2x.json`

Returns sprite index JSON (2x/retina).

### GET `/sprite/{sprite_name}@2x.png`

Returns sprite sheet image (2x/retina).

- **Generated on-the-fly** from SVG files in the sprites directory

## Health / Diagnostics

### GET `/health`

Martin health check endpoint.

- **Response**: 200 OK when the server is running

## Notes

- All endpoints support CORS headers (Martin default)
- No authentication — tiles are publicly accessible
- HTTPS termination handled by reverse proxy (out of scope)
- Martin auto-discovers MBTiles files, fonts, sprites, and styles
  based on CLI flags pointing to directories
