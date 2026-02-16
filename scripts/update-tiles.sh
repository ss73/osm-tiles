#!/usr/bin/env bash
set -euo pipefail

# Update OSM tiles by downloading a fresh extract and regenerating
#
# Usage: ./scripts/update-tiles.sh [--area AREA]
#
# This script:
#   1. Generates new tiles to a temporary file
#   2. Swaps the new file into place
#   3. Restarts the Martin container
#   4. Verifies the server is healthy
#   5. Cleans up the old file
#
# If generation fails, existing tiles are left untouched.

AREA="${1:-sweden}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_DIR/data"
CURRENT="$DATA_DIR/sweden.mbtiles"
NEW="$DATA_DIR/sweden-new.mbtiles"
OLD="$DATA_DIR/sweden-old.mbtiles"

echo "=== OSM Tile Update ==="
echo "Area: $AREA"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Step 1: Generate new tiles
echo ""
echo "Step 1: Generating new tiles..."
docker run --rm \
  -e JAVA_TOOL_OPTIONS="-Xmx2g" \
  -v "$DATA_DIR":/data \
  ghcr.io/onthegomap/planetiler:latest \
  --download --area="$AREA" \
  --output="/data/sweden-new.mbtiles"

if [ ! -f "$NEW" ]; then
  echo "ERROR: Tile generation failed — new file not found"
  exit 1
fi

echo "New tiles generated: $(ls -lh "$NEW" | awk '{print $5}')"

# Step 2: Swap files
echo ""
echo "Step 2: Swapping tileset..."
if [ -f "$CURRENT" ]; then
  mv "$CURRENT" "$OLD"
fi
mv "$NEW" "$CURRENT"
echo "Swap complete"

# Step 3: Restart Martin
echo ""
echo "Step 3: Restarting Martin..."
cd "$PROJECT_DIR"
docker compose restart martin

# Step 4: Verify health
echo ""
echo "Step 4: Verifying server health..."
sleep 3
HEALTH_STATUS=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/health || echo "000")

if [ "$HEALTH_STATUS" = "200" ]; then
  echo "Server healthy (HTTP $HEALTH_STATUS)"
else
  echo "WARNING: Health check returned HTTP $HEALTH_STATUS"
  echo "The server may need more time to start. Check: curl http://localhost:3000/health"
fi

# Step 5: Clean up
if [ -f "$OLD" ]; then
  echo ""
  echo "Step 5: Cleaning up old tileset..."
  rm "$OLD"
  echo "Old tileset removed"
fi

echo ""
echo "=== Update complete ==="
