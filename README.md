# osm-tiles

Self-hosted vector tile server replacing Mapbox. Serves OpenStreetMap
vector tiles with custom styles, compatible with MapLibre GL JS and
Leaflet.

## Stack

- **Tile generation**: [Planetiler](https://github.com/onthegomap/planetiler) — OSM PBF → MBTiles
- **Tile server**: [Martin](https://github.com/maplibre/martin) — serves tiles, styles, fonts, sprites
- **Styles**: [OSM Liberty](https://github.com/maputnik/osm-liberty), [Positron](https://github.com/openmaptiles/positron-gl-style), [Dark Matter](https://github.com/openmaptiles/dark-matter-gl-style)
- **Fonts**: Noto Sans (served dynamically by Martin)
- **Sprites**: Maki icons (served dynamically by Martin)

## Prerequisites

- Docker (or Podman)
- 4 GB free RAM
- 10 GB free disk space

## Quickstart

```bash
# 1. Generate tiles (Sweden, ~2-10 min)
./scripts/generate-tiles.sh

# 2. Start the tile server
docker compose up -d

# 3. Verify
curl http://localhost:3000/health
```

Open `examples/maplibre-demo.html` in a browser to see the map.

See [specs/001-vector-tile-server/quickstart.md](specs/001-vector-tile-server/quickstart.md)
for the full walkthrough.

## Project Structure

```
docker-compose.yml          # Martin tile server
styles/                     # MapLibre Style Spec JSON files
fonts/                      # TTF fonts (Noto Sans)
sprites/osm-liberty/        # SVG icons for dynamic sprite generation
scripts/
├── generate-tiles.sh       # Generate MBTiles from OSM extract
├── update-tiles.sh         # Re-download and swap tiles
└── set-tile-server-url.sh  # Rewrite URLs for production
examples/
├── maplibre-demo.html      # MapLibre GL JS demo with style switcher
└── leaflet-demo.html       # Leaflet + maplibre-gl-leaflet demo
data/                       # Generated tiles (gitignored)
```

## Customizing Styles

Edit any JSON file in `styles/` and refresh the browser. Changes are
visible immediately — no tile regeneration needed.

## Updating Map Data

```bash
./scripts/update-tiles.sh
```

Downloads a fresh OSM extract, regenerates tiles, swaps the file, and
restarts Martin.

## Changing Coverage Area

```bash
./scripts/generate-tiles.sh norway
```

Use any [Geofabrik region name](https://download.geofabrik.de/).

## Production Deployment

Rewrite tile server URLs in all style files:

```bash
./scripts/set-tile-server-url.sh https://tiles.example.com
```

## Documentation

Detailed specs and design decisions are in
[specs/001-vector-tile-server/](specs/001-vector-tile-server/).
