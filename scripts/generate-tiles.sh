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
# Examples:
#   ./scripts/generate-tiles.sh                          # Sweden, 2g RAM
#   ./scripts/generate-tiles.sh norway                   # Norway, 2g RAM
#   ./scripts/generate-tiles.sh planet                   # Planet, 32g RAM
#   ./scripts/generate-tiles.sh planet world.mbtiles 48g # Planet, custom

AREA="${1:-sweden}"
OUTPUT_FILE="${2:-$AREA.mbtiles}"

# Auto-scale memory based on area size
if [ -z "${3:-}" ]; then
  case "$AREA" in
    planet)               MEMORY="32g" ;;
    europe|north-america) MEMORY="16g" ;;
    *)                    MEMORY="2g"  ;;
  esac
else
  MEMORY="$3"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_DIR/data"

mkdir -p "$DATA_DIR"

echo "Area:   $AREA"
echo "Output: $DATA_DIR/$OUTPUT_FILE"
echo "Memory: $MEMORY"
echo ""

docker run --rm \
  -e JAVA_TOOL_OPTIONS="-Xmx${MEMORY}" \
  -v "$DATA_DIR":/data \
  ghcr.io/onthegomap/planetiler:latest \
  --download --area="$AREA" \
  --output="/data/$OUTPUT_FILE"

echo ""
echo "Tile generation complete: $DATA_DIR/$OUTPUT_FILE"
ls -lh "$DATA_DIR/$OUTPUT_FILE"
