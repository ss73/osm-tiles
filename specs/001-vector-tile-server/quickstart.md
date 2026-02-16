# Quickstart: Self-Hosted Vector Tile Server

**Date**: 2026-02-16
**Feature**: 001-vector-tile-server

## Prerequisites

- Docker (or Podman) installed
- At least 4 GB free RAM
- At least 10 GB free disk space
- Internet connection (for downloading OSM data)

## Step 1: Generate Tiles

Download the Sweden OSM extract and generate vector tiles using
Planetiler:

```bash
mkdir -p data

docker run -e JAVA_TOOL_OPTIONS="-Xmx2g" \
  -v "$(pwd)/data":/data \
  ghcr.io/onthegomap/planetiler:latest \
  --download --area=sweden \
  --output=/data/sweden.mbtiles
```

This downloads ~753 MB of OSM data and produces an MBTiles file.
Takes approximately 2-10 minutes depending on hardware.

## Step 2: Start the Tile Server

Run Martin with the generated tiles, styles, fonts, and sprites:

```bash
docker run -d --name martin \
  -p 3000:3000 \
  -v "$(pwd)/data":/data \
  -v "$(pwd)/styles":/styles \
  -v "$(pwd)/fonts":/fonts \
  -v "$(pwd)/sprites":/sprites \
  ghcr.io/maplibre/martin \
  /data/sweden.mbtiles \
  --font /fonts \
  --sprite /sprites \
  --style /styles
```

## Step 3: Verify

Check that the server is running:

```bash
curl http://localhost:3000/health
```

View the tile catalog:

```bash
curl http://localhost:3000/catalog
```

Request a sample tile (zoom 10, central Sweden):

```bash
curl -o test.pbf http://localhost:3000/sweden/10/546/280
```

## Step 4: View in Browser

Open `examples/maplibre-demo.html` in a browser. The map should
display Sweden with the OSM Liberty style, supporting zoom, pan,
and feature interaction.

## Step 5: Customize Styles

Edit any style JSON file in `styles/` (e.g., change a road color).
Refresh the browser — the change is visible immediately. No tile
regeneration needed.

## Updating Map Data

To update to a newer OSM extract:

```bash
# 1. Generate new tiles (existing server keeps running)
docker run -e JAVA_TOOL_OPTIONS="-Xmx2g" \
  -v "$(pwd)/data":/data \
  ghcr.io/onthegomap/planetiler:latest \
  --download --area=sweden \
  --output=/data/sweden-new.mbtiles

# 2. Swap the tileset
mv data/sweden.mbtiles data/sweden-old.mbtiles
mv data/sweden-new.mbtiles data/sweden.mbtiles

# 3. Restart Martin to pick up the new file
docker restart martin

# 4. Verify, then clean up
curl http://localhost:3000/health
rm data/sweden-old.mbtiles
```

## Changing Coverage Area

To serve a different country or region, change the `--area` flag
in Step 1 to any Geofabrik region name (e.g., `--area=norway`,
`--area=germany`, `--area=europe`). Larger areas require more RAM
and disk space — see data-model.md for estimates.
