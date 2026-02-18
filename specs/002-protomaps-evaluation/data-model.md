# Data Model: Protomaps Evaluation

**Feature Branch**: `002-protomaps-evaluation`
**Date**: 2026-02-18

## Overview

This feature has no persistent data storage or application state. All entities are static assets consumed at runtime by the browser.

## Entities

### PMTiles Source

A remote single-file tile archive accessed via HTTP range requests.

- **URL**: Remote HTTPS URL pointing to a `.pmtiles` file
- **Schema**: Protomaps Basemap Layers v4 (Tilezen-derived)
- **Format**: MVT (Mapbox Vector Tiles) packed in PMTiles v3
- **Zoom range**: 0–15
- **Attribution**: OpenStreetMap contributors + Protomaps

**Layers in the Tilezen schema**:

| Layer | Description | Key Properties |
|-------|-------------|----------------|
| boundaries | Administrative borders | `kind`, `kind_detail`, `min_zoom` |
| buildings | Structures | `kind`, `height`, `min_zoom` |
| earth | Land masses | `kind`, `min_zoom` |
| landcover | Terrain classification | `kind` (forest, farmland, glacier, etc.) |
| landuse | Zoned areas | `kind` (park, hospital, industrial, etc.) |
| places | Named locations | `kind`, `name`, `population`, `kind_tile_rank` |
| pois | Points of interest | `kind`, `name`, `min_zoom` |
| roads | Transportation | `kind`, `kind_detail`, `ref`, `shield_text` |
| transit | Passenger transport | `kind`, `name` |
| water | Water bodies | `kind` (ocean, lake, river, etc.) |

### Style Configuration

A MapLibre Style Spec v8 object generated at runtime by the `@protomaps/basemaps` library.

- **Source name**: Arbitrary string linking layers to the PMTiles source (e.g., `"protomaps"`)
- **Flavor**: One of `light`, `dark`, `white`, `black`, `grayscale`
- **Language**: BCP 47 language tag for label text (default: `"en"`)
- **Glyphs**: Remote PBF font files
- **Sprites**: Remote sprite sheets (per-flavor, 1x and 2x)

### Demo Page

A standalone HTML file with no server-side dependencies.

- **Inputs**: PMTiles URL, style flavor, MapLibre GL JS version
- **Outputs**: Interactive vector map with style switching and feature inspection
- **State**: Map center, zoom, pitch, bearing, active style (all transient, in-memory)
