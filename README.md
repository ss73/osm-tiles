# osm-tiles

Self-hosted vector tile server replacing Mapbox. Serves OpenStreetMap
vector tiles with custom styles, compatible with MapLibre GL JS and
Leaflet.

## Stack

- **Tile generation**: [Planetiler](https://github.com/onthegomap/planetiler) — OSM PBF to MBTiles
- **Tile server**: [Martin](https://github.com/maplibre/martin) — serves tiles, styles, fonts, sprites
- **Styles**: OSM Liberty, Positron, Dark Matter, Blue Dark
- **Fonts**: Noto Sans, Roboto (served by Martin)
- **Sprites**: Maki icons (served by Martin)

## Prerequisites

- Docker (or Podman)
- 4 GB free RAM (8 GB recommended for planet-scale generation)
- 10 GB free disk space

## Quickstart

```bash
# 1. Clone the repository
git clone https://github.com/ss73/osm-tiles.git
cd osm-tiles

# 2. Generate tiles (Sweden by default, ~30 min)
#    Requires Docker running — downloads OSM data and produces MBTiles
./scripts/generate-tiles.sh

# 3. Start the tile server
docker compose up -d

# 4. Verify the server is running
curl http://localhost:3000/health
```

Open `examples/maplibre-demo.html` in a browser. The demos connect
to the tile server at `http://localhost:3000`.

## Tile Generation

```bash
# Generate tiles for any Geofabrik region
./scripts/generate-tiles.sh sweden
./scripts/generate-tiles.sh norway
./scripts/generate-tiles.sh europe

# Planet-scale (uses disk-backed storage on machines with <= 16 GB RAM)
./scripts/generate-tiles.sh planet
```

Memory is auto-scaled based on area size. Downloads are resumable — if
interrupted, re-run the same command and it picks up where it left off.

## Demo Pages

### MapLibre GL JS (`examples/maplibre-demo.html`)

Full-featured demo with:

- **Style switcher** — OSM Liberty, Positron, Dark Matter, Blue Dark
- **Layer toggles** — labels, land borders, sea borders
- **3D view** — pitch/bearing controls with 2D/3D presets
- **Overlays**:
  - **Road density heatmap** — transportation layer visualized as a cold-warm heatmap, visible from z4
  - **Public transport** — bus stops, subway, train, tram, and ferry icons from POI data (z12+), with name labels at z14+
  - **Restaurants & cafes** — clustered GeoJSON overlay with ~680 Stockholm POIs. Clusters merge/expand based on zoom level, click a cluster to zoom in
- **Feature inspector** — click any feature to see its properties

### Leaflet (`examples/leaflet-demo.html`)

Lightweight demo using Leaflet with a MapLibre GL layer underneath.
Includes label and border toggles.

## Project Structure

```
docker-compose.yml          # Martin tile server
styles/                     # MapLibre Style Spec JSON files
  osm-liberty.json          # OSM Liberty (default)
  positron.json             # Light/minimal style
  dark-matter.json          # Dark style
  blue-dark.json            # Blue dark style
fonts/                      # TTF fonts (Noto Sans, Roboto)
sprites/osm-liberty/        # SVG icons for sprite generation
scripts/
  generate-tiles.sh         # Generate MBTiles from OSM extract
  update-tiles.sh           # Re-download and swap tiles
  set-tile-server-url.sh    # Rewrite URLs for production
examples/
  maplibre-demo.html        # MapLibre GL JS demo
  leaflet-demo.html         # Leaflet demo
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

## Production Deployment

Rewrite tile server URLs in all style files:

```bash
./scripts/set-tile-server-url.sh https://tiles.example.com
```

Then copy the project to your server and run `docker compose up -d`.
The only files needed are `docker-compose.yml`, `styles/`, `fonts/`,
`sprites/`, and `data/` (the generated MBTiles).

## Documentation

Detailed specs and design decisions are in
[specs/001-vector-tile-server/](specs/001-vector-tile-server/).
