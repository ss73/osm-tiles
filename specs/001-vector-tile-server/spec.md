# Feature Specification: Self-Hosted Vector Tile Server

**Feature Branch**: `001-vector-tile-server`
**Created**: 2026-02-16
**Status**: Draft
**Input**: User description: "Set up a self-hosted vector tile server using open-source tools to serve OSM vector tiles with custom styles, compatible with MapLibre GL JS and Leaflet"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Serve Vector Tiles (Priority: P1)

As a developer, I want to serve OpenStreetMap vector tiles from my own
infrastructure so that my web applications can display interactive maps
without depending on a Mapbox subscription.

**Why this priority**: This is the core value proposition. Without tile
serving, nothing else works. A working tile endpoint is the minimum
viable product.

**Independent Test**: Can be verified by requesting a tile URL in a
browser and receiving valid vector tile data, then loading the tile
endpoint in a basic map viewer that renders the tiles visually.

**Acceptance Scenarios**:

1. **Given** the tile server is running with OSM data loaded, **When** a
   client requests a vector tile at a valid z/x/y coordinate, **Then**
   the server returns a valid vector tile with appropriate content type
   and the response completes within 1 second.
2. **Given** the tile server is running, **When** a client requests a
   tile at an invalid coordinate or outside the coverage area, **Then**
   the server returns an appropriate empty response (not an error).
3. **Given** the tile server is running, **When** a client requests the
   TileJSON metadata endpoint, **Then** the server returns valid
   metadata describing available tile layers, zoom levels, and bounds.

---

### User Story 2 - Custom Map Styling (Priority: P2)

As a developer, I want to apply and modify custom visual styles to my
maps — including colors, fonts, label placement, and layer visibility —
so that the maps match my application's brand and design requirements.

**Why this priority**: Style freedom is a primary motivation for
self-hosting. Without it, the project offers little advantage over
free-tier hosted alternatives.

**Independent Test**: Can be verified by loading two different style
files against the same tile data and confirming visually distinct map
appearances (e.g., a light theme vs. a dark theme).

**Acceptance Scenarios**:

1. **Given** the tile server is serving tiles and a style file is
   available, **When** a map client loads the style, **Then** the map
   renders with the colors, fonts, and layer visibility defined in
   that style.
2. **Given** a style file exists, **When** the operator modifies a
   color value and reloads the map, **Then** the change is visible
   without reprocessing tile data.
3. **Given** the server hosts multiple style variants, **When** a
   client requests a specific style by name, **Then** the correct
   style JSON is returned along with references to the appropriate
   font glyphs and sprite sheets.

---

### User Story 3 - MapLibre GL JS Integration (Priority: P3)

As a developer migrating from Mapbox, I want to use MapLibre GL JS
with this tile server so that I can replace my Mapbox dependency with
minimal code changes in my existing applications.

**Why this priority**: MapLibre GL JS is the primary client target.
Proving a smooth migration path validates the entire project for its
intended use case.

**Independent Test**: Can be verified by taking a working Mapbox GL JS
application, swapping the library to MapLibre GL JS, pointing it at
the self-hosted tile server, and confirming the map renders correctly
with interactive features (zoom, pan, popups).

**Acceptance Scenarios**:

1. **Given** a web page using MapLibre GL JS, **When** the map is
   configured to use the self-hosted tile and style endpoints, **Then**
   the map renders correctly with all expected layers visible.
2. **Given** a MapLibre GL JS map connected to the tile server, **When**
   the user zooms and pans, **Then** new tiles load smoothly with no
   visual artifacts or broken layers.
3. **Given** a MapLibre GL JS map, **When** the user clicks on a map
   feature (road, building, POI), **Then** the feature's attribute
   data is available for display in a popup or sidebar.

---

### User Story 4 - Leaflet Integration (Priority: P4)

As a developer with existing Leaflet-based applications, I want to
display vector tiles from this server in Leaflet so that I can
upgrade my maps without rewriting my application.

**Why this priority**: Leaflet is the secondary client target. It
broadens the project's usefulness but is not the primary migration
path.

**Independent Test**: Can be verified by creating a Leaflet map that
loads vector tiles from the server using a vector tile plugin and
confirming the map renders and supports basic interactions.

**Acceptance Scenarios**:

1. **Given** a Leaflet map using a vector tile plugin, **When** the map
   is configured to use the self-hosted tile endpoint, **Then** the
   map renders with styled vector data.
2. **Given** a Leaflet map connected to the tile server, **When** the
   user pans across the coverage area, **Then** tiles load without
   errors and the map remains responsive.

---

### User Story 5 - OSM Data Updates (Priority: P5)

As an operator, I want to update the map data periodically so that the
maps reflect recent OpenStreetMap edits and additions.

**Why this priority**: Stale data is acceptable at launch but becomes
a problem over time. This story ensures long-term viability but is not
required for initial deployment.

**Independent Test**: Can be verified by noting a recent OSM edit in
the coverage area, running the update process, and confirming the edit
appears in the served tiles.

**Acceptance Scenarios**:

1. **Given** the tile server is running with an initial data load,
   **When** the operator runs the documented update process, **Then**
   new OSM data is incorporated and served without extended downtime
   (less than 10 minutes of unavailability).
2. **Given** the update process is running, **When** it encounters a
   data download failure, **Then** the existing tiles remain available
   and the operator is notified of the failure.

---

### Edge Cases

- What happens when a client requests tiles outside the geographic
  coverage area? The server MUST return empty tiles, not errors.
- What happens when the OSM data extract is corrupted or incomplete?
  The system MUST retain the previous working dataset and report the
  error.
- What happens when multiple clients request the same tile
  simultaneously? The server MUST handle concurrent requests without
  serving corrupt or partial data.
- What happens when the server runs out of disk space during a data
  update? The update MUST fail gracefully and the existing tiles MUST
  remain available.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST serve vector tiles over HTTP(S) using the
  standard z/x/y URL pattern.
- **FR-002**: System MUST provide a TileJSON metadata endpoint
  describing available layers, zoom range, and geographic bounds.
- **FR-003**: System MUST serve map style files that reference
  self-hosted tile endpoints, font glyphs, and sprite sheets.
- **FR-004**: System MUST host font glyph ranges (PBF format) for
  all fonts referenced in style files.
- **FR-005**: System MUST host sprite sheets (PNG + JSON) for all
  icons referenced in style files.
- **FR-006**: System MUST serve tiles containing standard OSM map
  layers (roads, buildings, water, land use, points of interest,
  labels).
- **FR-007**: System MUST support zoom levels 0 through 14 at minimum.
- **FR-008**: Style files MUST be modifiable without regenerating or
  reprocessing tile data.
- **FR-009**: System MUST provide a documented, repeatable process for
  loading initial OSM data.
- **FR-010**: System MUST provide a documented process for updating OSM
  data by downloading a fresh extract and regenerating tiles. The update
  process SHOULD be designed so that incremental diff-based updates can
  be added later without rearchitecting.
- **FR-011**: System MUST work with MapLibre GL JS as the primary map
  client library.
- **FR-012**: System MUST work with Leaflet (via a vector tile plugin)
  as a secondary map client library.
- **FR-013**: System MUST include at least one complete, usable map
  style as a starting point for customization.
- **FR-014**: System MUST be deployable on a single machine using
  container orchestration.
- **FR-015**: The geographic coverage area MUST be configurable by
  choosing an appropriate OSM data extract at setup time. The initial
  target is a single country (e.g., Sweden). The system MUST support
  scaling to larger regions by substituting a different extract.

### Key Entities

- **Tile**: A single vector tile identified by zoom level (z), column
  (x), and row (y). Contains geometry and attributes for map features
  within that geographic cell.
- **Tileset**: A complete collection of tiles covering a geographic
  area across a range of zoom levels. Stored as a single package file.
- **Style**: A JSON document defining how tile data is visually
  rendered — colors, line widths, label rules, layer ordering, and
  references to fonts and sprites.
- **Font Glyphs**: Pre-rendered text glyph ranges in PBF format used
  for map label rendering on the client side.
- **Sprite Sheet**: A PNG image containing map icons bundled with a
  JSON index describing icon positions and dimensions.
- **OSM Data Extract**: A regional or global subset of OpenStreetMap
  data used as input for tile generation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A map loads and displays all expected layers (roads,
  water, buildings, labels) within 3 seconds on a standard broadband
  connection.
- **SC-002**: Tile requests at zoom levels 0–14 return valid data
  with no more than 0.1% error rate under normal load.
- **SC-003**: An existing Mapbox GL JS application can be migrated
  to the self-hosted server by changing only the library import and
  endpoint URL — no map logic changes required.
- **SC-004**: A style change (e.g., modifying a road color) is
  visible in the browser within 60 seconds of editing the style file
  and refreshing.
- **SC-005**: The initial data load and tile generation process
  completes successfully and is fully documented with exact commands
  for the chosen coverage area.
- **SC-006**: The data update process completes without requiring
  operator intervention beyond starting it.


## Clarifications

### Session 2026-02-16

- Q: Data update strategy — full re-download, incremental diffs, or both? → A: Full re-download initially, designed for future incremental support.
- Q: Expected concurrent users? → A: Low (1–10), personal/small team use. No caching layer needed.

### Assumptions

- Target usage is 1–10 concurrent map viewers (personal or small team).
  No caching layer or CDN is required for this scale.
- The operator has a Linux server (or VM) with at least 4 CPU cores,
  8 GB RAM, and sufficient disk space for the chosen coverage area.
- The server has a stable internet connection for downloading OSM data
  extracts.
- No authentication is required for tile serving — tiles are publicly
  accessible. (Access restriction can be handled by a reverse proxy if
  needed, but is out of scope for this feature.)
- HTTPS termination is handled externally (e.g., by a reverse proxy or
  load balancer), not by the tile server itself.
- The operator is comfortable with basic command-line and container
  operations.
