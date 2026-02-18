#!/usr/bin/env bash
set -euo pipefail

# Download Protomaps daily planet build (PMTiles), full or regional extract
#
# Usage: ./protomaps/download-planet.sh [REGION] [OUTPUT_DIR]
#
# Arguments:
#   REGION      Country/region name or "planet" (default: planet)
#   OUTPUT_DIR  Where to save the file (default: protomaps/data)
#
# Downloads are resumable — if interrupted, re-run the same command
# and it picks up where it left off. The script resolves the latest
# available daily build (tries today, then up to 7 days back).
#
# For regional extracts, the pmtiles CLI is auto-downloaded if not
# found on $PATH. It extracts tiles by bounding box from the remote
# planet file using HTTP range requests — no full download needed.
#
# Examples:
#   ./protomaps/download-planet.sh                  # Full planet (~120 GB)
#   ./protomaps/download-planet.sh sweden           # Sweden extract (~2 GB)
#   ./protomaps/download-planet.sh europe           # Europe extract (~30 GB)
#   ./protomaps/download-planet.sh planet /mnt/tiles

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REGION="${1:-planet}"
OUTPUT_DIR="${2:-$SCRIPT_DIR/data}"
UPSTREAM="https://build.protomaps.com"
BIN_DIR="$SCRIPT_DIR/.bin"

# Bounding boxes: min_lon,min_lat,max_lon,max_lat
bbox_for() {
  case "$1" in
    sweden)      echo "10.5,55.2,24.2,69.1" ;;
    norway)      echo "4.0,57.8,31.5,71.3" ;;
    denmark)     echo "7.7,54.4,15.7,58.0" ;;
    finland)     echo "19.0,59.5,31.6,70.1" ;;
    iceland)     echo "-25.0,63.0,-13.0,67.0" ;;
    nordics)     echo "4.0,54.4,31.6,71.3" ;;
    germany)     echo "5.9,47.2,15.1,55.1" ;;
    france)      echo "-5.2,41.3,9.6,51.1" ;;
    spain)       echo "-9.4,35.9,4.4,43.8" ;;
    italy)       echo "6.6,36.6,18.5,47.1" ;;
    uk)          echo "-8.2,49.9,1.8,60.9" ;;
    netherlands) echo "3.3,50.7,7.3,53.6" ;;
    poland)      echo "14.1,49.0,24.2,55.0" ;;
    europe)      echo "-11.0,34.0,40.0,72.0" ;;
    usa)         echo "-125.0,24.5,-66.9,49.4" ;;
    japan)       echo "122.9,24.0,153.9,45.6" ;;
    australia)   echo "112.0,-44.0,154.0,-10.0" ;;
    *)           return 1 ;;
  esac
}

mkdir -p "$OUTPUT_DIR"

# --- Resolve latest build ---
echo "Resolving latest Protomaps daily build..."
LATEST=""
for DAYS_AGO in $(seq 0 7); do
  DATE=$(date -v-${DAYS_AGO}d +%Y%m%d 2>/dev/null || date -d "-${DAYS_AGO} days" +%Y%m%d)
  FILENAME="${DATE}.pmtiles"
  URL="${UPSTREAM}/${FILENAME}"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --head "$URL")
  if [ "$HTTP_CODE" = "200" ]; then
    LATEST="$FILENAME"
    echo "Found latest build: $FILENAME"
    break
  fi
done

if [ -z "$LATEST" ]; then
  echo "Error: Could not find any daily build in the last 7 days" >&2
  exit 1
fi

SOURCE_URL="${UPSTREAM}/${LATEST}"
DATE_STAMP="${LATEST%.pmtiles}"

# --- Planet: direct download with resume ---
if [ "$REGION" = "planet" ]; then
  OUTPUT_FILE="${OUTPUT_DIR}/${LATEST}"
  SYMLINK="${OUTPUT_DIR}/planet-latest.pmtiles"

  REMOTE_SIZE=$(curl -sI "$SOURCE_URL" | grep -i content-length | tail -1 | tr -d '[:space:]' | cut -d: -f2)
  if [ -n "$REMOTE_SIZE" ]; then
    SIZE_GB=$(echo "scale=1; $REMOTE_SIZE / 1073741824" | bc)
    echo "Remote file size: ${SIZE_GB} GB"
  fi

  if [ -f "$OUTPUT_FILE" ]; then
    LOCAL_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE")
    LOCAL_GB=$(echo "scale=1; $LOCAL_SIZE / 1073741824" | bc)
    echo "Resuming download from ${LOCAL_GB} GB..."
  else
    echo "Starting fresh download to $OUTPUT_FILE"
  fi

  curl -C - -L -o "$OUTPUT_FILE" \
    --progress-bar \
    --retry 5 \
    --retry-delay 10 \
    "$SOURCE_URL"

  echo ""
  echo "Download complete: $OUTPUT_FILE"

  # Clean up older planet files
  for OLD in "$OUTPUT_DIR"/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9].pmtiles; do
    [ -f "$OLD" ] && [ "$OLD" != "$OUTPUT_FILE" ] && echo "Removing old build: $OLD" && rm "$OLD"
  done

  ln -sf "$LATEST" "$SYMLINK"
  echo "Symlink updated: $SYMLINK -> $LATEST"
  exit 0
fi

# --- Region: extract via pmtiles CLI ---
BBOX=$(bbox_for "$REGION") || {
  echo "Error: Unknown region '$REGION'" >&2
  echo "Available regions: planet sweden norway denmark finland iceland nordics germany france spain italy uk netherlands poland europe usa japan australia" >&2
  exit 1
}

# Ensure pmtiles CLI is available
PMTILES_BIN=""
if command -v pmtiles &>/dev/null; then
  PMTILES_BIN="pmtiles"
elif [ -x "$BIN_DIR/pmtiles" ]; then
  PMTILES_BIN="$BIN_DIR/pmtiles"
else
  echo "pmtiles CLI not found — downloading..."
  mkdir -p "$BIN_DIR"

  ARCH=$(uname -m)
  OS=$(uname -s)
  case "$OS" in
    Darwin) OS_NAME="Darwin" ;;
    Linux)  OS_NAME="Linux" ;;
    *)      echo "Error: Unsupported OS: $OS" >&2; exit 1 ;;
  esac
  case "$ARCH" in
    arm64|aarch64) ARCH_NAME="arm64" ;;
    x86_64)        ARCH_NAME="x86_64" ;;
    *)             echo "Error: Unsupported architecture: $ARCH" >&2; exit 1 ;;
  esac

  VERSION=$(curl -sL "https://api.github.com/repos/protomaps/go-pmtiles/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
  ZIP_NAME="go-pmtiles-${VERSION#v}_${OS_NAME}_${ARCH_NAME}.zip"
  ZIP_URL="https://github.com/protomaps/go-pmtiles/releases/download/${VERSION}/${ZIP_NAME}"

  echo "Downloading $ZIP_URL"
  curl -sL -o "$BIN_DIR/$ZIP_NAME" "$ZIP_URL"
  unzip -qo "$BIN_DIR/$ZIP_NAME" -d "$BIN_DIR"
  rm "$BIN_DIR/$ZIP_NAME"
  chmod +x "$BIN_DIR/pmtiles"
  PMTILES_BIN="$BIN_DIR/pmtiles"
  echo "Installed pmtiles CLI to $PMTILES_BIN"
fi

OUTPUT_FILE="${OUTPUT_DIR}/${REGION}.pmtiles"
SYMLINK="${OUTPUT_DIR}/planet-latest.pmtiles"

echo "Extracting $REGION (bbox: $BBOX) from $LATEST..."
"$PMTILES_BIN" extract "$SOURCE_URL" "$OUTPUT_FILE" --bbox="$BBOX"

echo ""
echo "Extract complete: $OUTPUT_FILE"

# Clean up older extracts for this region
# (pmtiles extract overwrites in place, but clean any date-stamped variants)
for OLD in "$OUTPUT_DIR"/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9].pmtiles; do
  [ -f "$OLD" ] && echo "Removing old planet build: $OLD" && rm "$OLD"
done

ln -sf "${REGION}.pmtiles" "$SYMLINK"
echo "Symlink updated: $SYMLINK -> ${REGION}.pmtiles"

FINAL_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE")
FINAL_MB=$(echo "scale=1; $FINAL_SIZE / 1048576" | bc)
echo "Final size: ${FINAL_MB} MB"
