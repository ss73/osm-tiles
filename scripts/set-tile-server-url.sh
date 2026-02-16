#!/usr/bin/env bash
set -euo pipefail

# Rewrite tile server URLs in all style JSON files
#
# Usage: ./scripts/set-tile-server-url.sh <NEW_URL>
#
# Example:
#   ./scripts/set-tile-server-url.sh https://tiles.example.com
#   ./scripts/set-tile-server-url.sh http://localhost:3000

if [ $# -eq 0 ]; then
  echo "Usage: $0 <NEW_URL>"
  echo "Example: $0 https://tiles.example.com"
  exit 1
fi

NEW_URL="${1%/}"  # strip trailing slash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STYLES_DIR="$(dirname "$SCRIPT_DIR")/styles"

echo "Rewriting tile server URL to: $NEW_URL"

for style in "$STYLES_DIR"/*.json; do
  if [ -f "$style" ]; then
    # Replace any http://localhost:3000 or https://*.* base URLs in
    # glyphs, sprite, tiles, and url fields
    sed -i.bak -E \
      "s|https?://[^/\"]+(/font/)|${NEW_URL}\1|g;
       s|https?://[^/\"]+(/sprite/)|${NEW_URL}\1|g;
       s|https?://[^/\"]+(/style/)|${NEW_URL}\1|g;
       s|https?://[^/\"]+(/sweden)|${NEW_URL}\1|g" \
      "$style"
    rm -f "${style}.bak"
    echo "  Updated: $(basename "$style")"
  fi
done

echo "Done. Verify with: jq '.glyphs, .sprite, .sources' styles/*.json"
