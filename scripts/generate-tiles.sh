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
# For planet builds on machines with <=16 GB RAM, the script
# automatically uses disk-backed storage (nodemap-type=sortexternally,
# storage=mmap) so it fits in ~8g heap. This trades speed for lower
# memory — expect ~4 hours on an 8-core machine.
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

mkdir -p "$DATA_DIR"

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
  --download --area="$AREA" \
  --output="/data/$OUTPUT_FILE" \
  "${EXTRA_ARGS[@]}"

echo ""
echo "Tile generation complete: $DATA_DIR/$OUTPUT_FILE"
ls -lh "$DATA_DIR/$OUTPUT_FILE"
