# Feature Specification: Protomaps Evaluation

**Feature Branch**: `002-protomaps-evaluation`
**Created**: 2026-02-18
**Status**: Draft
**Input**: User description: "Test Protomaps as an alternative tile serving approach. Use publicly available world tiles if self-generating offers no real advantage. Separate all new assets from existing Martin/Planetiler setup. Frontend PoC equivalent to the existing MapLibre GL demo. Use Maputnik or Protomaps-native styles."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View a Protomaps-powered map (Priority: P1)

A developer opens a standalone HTML demo page and sees a fully rendered vector map powered by Protomaps PMTiles, with pan, zoom, and styled layers (land, water, roads, buildings, labels). The experience should be visually comparable to the existing MapLibre demo using Martin-served tiles.

**Why this priority**: This is the core proof of concept — if the map doesn't render correctly with Protomaps tiles, nothing else matters.

**Independent Test**: Can be fully tested by opening the HTML file in a browser and verifying that the map renders with all expected layers visible and interactive.

**Acceptance Scenarios**:

1. **Given** the Protomaps demo HTML file is opened in a browser, **When** the page loads, **Then** a vector map renders showing land, water, roads, buildings, and labels at the default view.
2. **Given** the map is rendered, **When** the user pans and zooms, **Then** new tiles load and display without errors across zoom levels 0–15.
3. **Given** the map is rendered, **When** the user clicks a map feature, **Then** a popup displays the feature's layer and properties (feature inspector).

---

### User Story 2 - Switch between map styles (Priority: P2)

A developer can switch between multiple visual styles (e.g., light, dark, and a data-visualization theme) using a style switcher, similar to the existing demo's four-style switcher.

**Why this priority**: Style variety demonstrates that the Protomaps tile schema supports the same range of visual presentations as the current OpenMapTiles setup.

**Independent Test**: Can be tested by clicking each style option and verifying the map re-renders with the correct color scheme and layer visibility.

**Acceptance Scenarios**:

1. **Given** the demo is loaded with the default style, **When** the user selects a different style from the switcher, **Then** the map re-renders with the new style's colors and symbology.
2. **Given** multiple styles are available, **When** the user cycles through all styles, **Then** each style renders correctly with appropriate labels, roads, and land cover.

---

### User Story 3 - Serve tiles without a dedicated tile server (Priority: P3)

A developer serves the Protomaps demo from a simple static file server (or directly from a cloud storage URL) without running Martin or any other tile server process. Tiles are fetched via HTTP range requests directly from a PMTiles file.

**Why this priority**: The serverless serving model is a key differentiator of PMTiles over the current Martin-based approach and is central to evaluating operational simplicity.

**Independent Test**: Can be tested by serving the demo from a basic HTTP server (e.g., `python -m http.server`) with a local PMTiles file and verifying tiles load without any tile server container.

**Acceptance Scenarios**:

1. **Given** a PMTiles file is available on a static HTTP server with range request support, **When** the demo page loads, **Then** tiles are fetched directly from the PMTiles file without a tile server process.
2. **Given** tiles are served via range requests, **When** the user pans across the map, **Then** tiles load with acceptable latency (visually comparable to the Martin-served demo).

---

### Edge Cases

- What happens when the PMTiles file is unreachable or the URL is wrong? The map should display a clear error state rather than a blank canvas.
- What happens at zoom levels beyond the tile data's maxzoom? The map should overzoom gracefully without visual artifacts.
- What happens on a slow or metered connection with the large planet PMTiles file? Initial load should still be usable since only the header and visible tiles are fetched.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: All Protomaps-related files (scripts, demos, styles, configuration) MUST reside in directories separate from the existing Martin/Planetiler assets.
- **FR-002**: The existing Martin/Planetiler/OpenMapTiles functionality MUST remain unchanged and fully operational.
- **FR-003**: The demo MUST use MapLibre GL JS as the map rendering library, consistent with the existing demo.
- **FR-004**: The demo MUST support loading tiles from a publicly available PMTiles source (e.g., a Protomaps daily build) as the default, removing the need to generate tiles locally.
- **FR-005**: The demo MUST include at least three visually distinct map styles with a UI control to switch between them.
- **FR-006**: The demo MUST include a feature inspector (click-to-inspect) equivalent to the existing demo.
- **FR-007**: The demo MUST work when served from a simple static HTTP server without requiring a running tile server container.
- **FR-008**: The demo MUST include navigation controls (zoom, pan, rotation) equivalent to the existing demo.

### Key Entities

- **PMTiles file**: A single-file tile archive accessed via HTTP range requests. Contains vector tiles in the Protomaps/Tilezen schema. Can be a remote URL (publicly hosted) or a local file.
- **Style configuration**: MapLibre Style Spec JSON defining layer rendering rules. Must target the Protomaps/Tilezen schema (different layer names and properties from OpenMapTiles).
- **Demo page**: A standalone HTML file with embedded or referenced JavaScript that wires together the PMTiles source, style, and MapLibre GL JS.

## Scope & Constraints

### In Scope

- Standalone HTML demo with MapLibre GL JS and Protomaps tiles
- Multiple map styles compatible with the Protomaps/Tilezen tile schema
- Style switcher, feature inspector, and navigation controls
- Documentation of the Protomaps approach and how it compares to the current setup

### Out of Scope

- Replacing or modifying the existing Martin/Planetiler infrastructure
- Generating custom Protomaps-schema tiles with Planetiler (using public tiles instead)
- Overlays (heatmap, clustering, transit) — these are enhancements beyond the core evaluation
- Production deployment configuration for PMTiles hosting
- 3D building extrusion and pitch/bearing controls (nice-to-have, not required for evaluation)

## Assumptions

- A publicly available Protomaps planet PMTiles build provides sufficient coverage and zoom levels for evaluation purposes, eliminating the need to generate tiles locally.
- The Protomaps `@protomaps/basemaps` package (or its CDN build) provides ready-to-use styles for the Tilezen schema, removing the need to build styles from scratch in Maputnik.
- HTTP range requests work reliably from the Protomaps CDN or a mirrored PMTiles file for interactive map use.
- The Protomaps/Tilezen tile schema is sufficiently different from OpenMapTiles that existing styles (osm-liberty, positron, etc.) cannot be reused — new styles specific to the Tilezen schema are required.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The Protomaps demo renders a complete vector basemap (land, water, roads, buildings, labels) at zoom levels 0–15 without visual gaps or missing layers.
- **SC-002**: The demo loads and displays the initial map view within 5 seconds on a standard broadband connection, despite using remote PMTiles.
- **SC-003**: At least 3 distinct styles are available and switchable without page reload.
- **SC-004**: The demo functions correctly when served from a static file server with no tile server process running.
- **SC-005**: All Protomaps assets are fully isolated — removing the Protomaps directories has zero impact on the existing Martin/Planetiler demo.
