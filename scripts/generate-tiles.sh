#!/usr/bin/env bash
set -euo pipefail

# Generate vector tiles from an OSM extract using Planetiler
#
# Usage: ./scripts/generate-tiles.sh [AREA] [OUTPUT_FILE] [MEMORY]
#
# Arguments:
#   AREA        Geofabrik area name or "planet" (default: sweden)
#   OUTPUT_FILE Output filename (default: AREA.mbtiles)
#   MEMORY      Java heap size (default: auto-scaled by area)
#
# Downloads are resumable — if interrupted, re-run the same command
# and it picks up where it left off. For planet builds on machines
# with <=16 GB RAM, disk-backed storage is used automatically.
#
# Examples:
#   ./scripts/generate-tiles.sh                          # Sweden, 2g RAM
#   ./scripts/generate-tiles.sh norway                   # Norway, 2g RAM
#   ./scripts/generate-tiles.sh planet                   # Planet, 8g RAM (disk-backed)
#   ./scripts/generate-tiles.sh planet world.mbtiles 48g # Planet, 48g RAM (in-memory)

AREA="${1:-sweden}"
OUTPUT_FILE="${2:-$AREA.mbtiles}"

# Auto-scale memory based on area size
if [ -z "${3:-}" ]; then
  case "$AREA" in
    planet)               MEMORY="8g" ;;
    europe|north-america) MEMORY="8g" ;;
    *)                    MEMORY="2g" ;;
  esac
else
  MEMORY="$3"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_DIR/data"
SOURCES_DIR="$DATA_DIR/sources"

mkdir -p "$DATA_DIR" "$SOURCES_DIR"

# Resolve download URL and local filename for the OSM extract
case "$AREA" in
  planet)
    PBF_URL="https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf"
    PBF_FILE="planet.osm.pbf"
    ;;
  *)
    PBF_URL="https://download.geofabrik.de/${AREA}-latest.osm.pbf"
    PBF_FILE="${AREA}.osm.pbf"
    ;;
esac

# Download with resume support (curl -C - retries from where it left off)
# If the file already exists and matches the remote size, skip the download.
echo "Downloading $AREA extract..."
echo "URL:    $PBF_URL"
echo "File:   $SOURCES_DIR/$PBF_FILE"
echo ""

REMOTE_SIZE=$(curl -sLI "$PBF_URL" | grep -i content-length | tail -1 | tr -dc '0-9')
LOCAL_SIZE=0
if [ -f "$SOURCES_DIR/$PBF_FILE" ]; then
  LOCAL_SIZE=$(stat -f%z "$SOURCES_DIR/$PBF_FILE" 2>/dev/null || stat -c%s "$SOURCES_DIR/$PBF_FILE" 2>/dev/null || echo 0)
fi

if [ "$LOCAL_SIZE" -gt 0 ] && [ "$LOCAL_SIZE" -ge "$REMOTE_SIZE" ]; then
  echo "Already downloaded ($(ls -lh "$SOURCES_DIR/$PBF_FILE" | awk '{print $5}'))"
else
  curl -L -C - --retry 5 --retry-delay 10 -o "$SOURCES_DIR/$PBF_FILE" "$PBF_URL"
  echo ""
  echo "Download complete: $(ls -lh "$SOURCES_DIR/$PBF_FILE" | awk '{print $5}')"
fi
echo ""

# For planet/continent builds with <=16g heap, use disk-backed sort
# to avoid OOM. Above 16g we can keep everything in memory.
EXTRA_ARGS=()
MEMORY_NUM="${MEMORY%g}"
if [[ "$AREA" == "planet" || "$AREA" == "europe" || "$AREA" == "north-america" ]] && [ "$MEMORY_NUM" -le 16 ]; then
  EXTRA_ARGS+=(
    --nodemap-type=sortexternally
    --storage=mmap
    --building-merge-z13=false
  )
  MODE="disk-backed"
else
  MODE="in-memory"
fi

echo "Area:   $AREA"
echo "Output: $DATA_DIR/$OUTPUT_FILE"
echo "Memory: $MEMORY ($MODE)"
echo ""

docker run --rm \
  -e JAVA_TOOL_OPTIONS="-Xmx${MEMORY}" \
  -v "$DATA_DIR":/data \
  ghcr.io/onthegomap/planetiler:latest \
  --osm-path="/data/sources/$PBF_FILE" \
  --download --force \
  --output="/data/$OUTPUT_FILE" \
  ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}

echo ""
echo "Tile generation complete: $DATA_DIR/$OUTPUT_FILE"
ls -lh "$DATA_DIR/$OUTPUT_FILE"
