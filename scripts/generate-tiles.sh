#!/usr/bin/env bash
set -euo pipefail

# Generate vector tiles from an OSM extract using Planetiler
#
# Usage: ./scripts/generate-tiles.sh [--area AREA] [--output FILE]
#
# Defaults to Sweden extract if no area specified.

AREA="${1:-sweden}"
OUTPUT_FILE="${2:-sweden.mbtiles}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_DIR/data"

mkdir -p "$DATA_DIR"

echo "Generating tiles for area: $AREA"
echo "Output: $DATA_DIR/$OUTPUT_FILE"

docker run --rm \
  -e JAVA_TOOL_OPTIONS="-Xmx2g" \
  -v "$DATA_DIR":/data \
  ghcr.io/onthegomap/planetiler:latest \
  --download --area="$AREA" \
  --output="/data/$OUTPUT_FILE"

echo "Tile generation complete: $DATA_DIR/$OUTPUT_FILE"
ls -lh "$DATA_DIR/$OUTPUT_FILE"
