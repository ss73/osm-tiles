# Tasks: Self-Hosted Vector Tile Server

**Input**: Design documents from `/specs/001-vector-tile-server/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: No tests explicitly requested in the specification.

**Organization**: Tasks are grouped by user story to enable independent
implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

This is an infrastructure/configuration project. No `src/` or `tests/`
directories. Paths reference config files, scripts, styles, and assets
at the repository root.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create project directory structure and base configuration

- [x] T001 Create directory structure: styles/, fonts/, sprites/osm-liberty/, scripts/, examples/, data/
- [x] T002 Create .gitignore to exclude data/ directory, *.mbtiles, *.pbf, and other generated artifacts
- [x] T003 Create docker-compose.yml with Martin service mounting data/, styles/, fonts/, sprites/ volumes using ghcr.io/maplibre/martin image on port 3000

**Checkpoint**: Directory structure and base configuration ready

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Generate tile data and acquire font/sprite assets that ALL user stories depend on

**CRITICAL**: No user story work can begin until tiles are generated and assets are in place

- [x] T004 Write scripts/generate-tiles.sh that runs Planetiler via Docker to download Sweden extract from Geofabrik and output data/sweden.mbtiles (use ghcr.io/onthegomap/planetiler:latest with --download --area=sweden --output=/data/sweden.mbtiles)
- [x] T005 [P] Download Noto Sans Regular and Bold TTF font files to fonts/ directory (from Google Fonts or notofonts.github.io)
- [x] T006 [P] Download OSM Liberty SVG sprite icons to sprites/osm-liberty/ directory (from maputnik/osm-liberty gh-pages branch or icons directory)
- [x] T007 Run scripts/generate-tiles.sh to generate data/sweden.mbtiles (depends on T004)

**Checkpoint**: Tiles generated, fonts and sprites in place. User story implementation can begin.

---

## Phase 3: User Story 1 - Serve Vector Tiles (Priority: P1) MVP

**Goal**: Martin serves vector tiles from MBTiles over HTTP, returning
valid MVT data at z/x/y endpoints and TileJSON metadata.

**Independent Test**: `curl http://localhost:3000/sweden/10/546/280`
returns valid PBF data; `curl http://localhost:3000/sweden` returns
TileJSON; `curl http://localhost:3000/health` returns 200.

- [x] T008 [US1] Update docker-compose.yml to configure Martin with the MBTiles source (/data/sweden.mbtiles), font directory (--font /fonts), and sprite directory (--sprite /sprites)
- [x] T009 [US1] Start Martin via docker compose up and verify /health endpoint returns 200
- [x] T010 [US1] Verify tile endpoint: request /sweden/10/546/280 returns response with content-type application/x-protobuf and non-empty body
- [x] T011 [US1] Verify TileJSON endpoint: request /sweden returns JSON with layers, bounds, minzoom, maxzoom fields
- [x] T012 [US1] Verify empty tile handling: request a tile outside Sweden coverage area returns 204 or empty tile (not an error)
- [x] T013 [US1] Verify /catalog endpoint returns JSON listing the sweden tileset and available fonts/sprites

**Checkpoint**: Tile server is running and serving valid vector tiles. MVP functional.

---

## Phase 4: User Story 2 - Custom Map Styling (Priority: P2)

**Goal**: Serve multiple MapLibre Style Spec JSON files with self-hosted
source URLs, font glyphs, and sprites. Style edits are visible on
browser refresh without tile regeneration.

**Independent Test**: Request /style/osm-liberty returns valid style
JSON; load style in a map viewer and see styled map; edit a color in
the style file, refresh, and see the change.

- [x] T014 [US2] Download OSM Liberty style JSON from maputnik/osm-liberty and save to styles/osm-liberty.json, rewriting source URLs to point to http://localhost:3000/sweden, glyphs to http://localhost:3000/font/{fontstack}/{range}, and sprite to http://localhost:3000/sprite/osm-liberty
- [x] T015 [P] [US2] Download Positron style JSON from openmaptiles/positron-gl-style and save to styles/positron.json, rewriting source/glyph/sprite URLs to point to localhost:3000
- [x] T016 [P] [US2] Download Dark Matter style JSON from openmaptiles/dark-matter-gl-style and save to styles/dark-matter.json, rewriting source/glyph/sprite URLs to point to localhost:3000
- [x] T017 [US2] Verify Martin serves styles: request /style/osm-liberty, /style/positron, /style/dark-matter each returns valid JSON with correct source, glyphs, and sprite URLs
- [x] T018 [US2] Verify font endpoint: request /font/Noto%20Sans%20Regular/0-255 returns PBF glyph data
- [x] T019 [US2] Verify sprite endpoint: request /sprite/sprites.json returns JSON index and /sprite/sprites.png returns PNG image (both 1x and @2x)
- [x] T020 [US2] Verify style edit workflow: change a road color value in styles/osm-liberty.json, request the style endpoint again, confirm the changed value is present in the response

**Checkpoint**: Three style variants served with self-hosted fonts and sprites. Style editing works without tile regeneration.

---

## Phase 5: User Story 3 - MapLibre GL JS Integration (Priority: P3)

**Goal**: A demo HTML page using MapLibre GL JS renders a fully styled,
interactive map from the self-hosted tile server.

**Independent Test**: Open examples/maplibre-demo.html in a browser;
map renders Sweden with roads, water, buildings, labels; zoom/pan works;
clicking a feature shows its attributes.

- [x] T021 [US3] Create examples/maplibre-demo.html: a standalone HTML page that loads MapLibre GL JS from CDN, initializes a map centered on Sweden using the self-hosted style URL (http://localhost:3000/style/osm-liberty), and includes a style switcher to toggle between osm-liberty, positron, and dark-matter
- [x] T022 [US3] Add feature interaction to examples/maplibre-demo.html: on click, display a popup showing the clicked feature's layer name and attributes
- [x] T023 [US3] Verify the demo page renders all expected layers: roads, water bodies, buildings, labels, and POI icons are visible at appropriate zoom levels

**Checkpoint**: MapLibre GL JS demo fully functional with style switching and feature interaction.

---

## Phase 6: User Story 4 - Leaflet Integration (Priority: P4)

**Goal**: A demo HTML page using Leaflet with maplibre-gl-leaflet renders
vector tiles from the self-hosted server with the same styles.

**Independent Test**: Open examples/leaflet-demo.html in a browser;
map renders Sweden with styled vector tiles; pan and zoom work smoothly.

- [x] T024 [US4] Create examples/leaflet-demo.html: a standalone HTML page that loads Leaflet and maplibre-gl-leaflet from CDN, initializes a Leaflet map with an L.maplibreGL layer using the self-hosted style URL (http://localhost:3000/style/osm-liberty)
- [x] T025 [US4] Verify the Leaflet demo renders styled vector tiles and supports zoom/pan across the Sweden coverage area

**Checkpoint**: Leaflet integration working with shared style definitions.

---

## Phase 7: User Story 5 - OSM Data Updates (Priority: P5)

**Goal**: A documented, scripted process to download a fresh OSM extract,
regenerate tiles, and swap the live tileset with minimal downtime.

**Independent Test**: Run scripts/update-tiles.sh; the script downloads
a new extract, generates new MBTiles, swaps the file, restarts Martin,
and the server continues serving tiles.

- [x] T026 [US5] Write scripts/update-tiles.sh that: (1) runs Planetiler to generate data/sweden-new.mbtiles, (2) swaps data/sweden.mbtiles with the new file, (3) restarts the Martin container, (4) verifies /health returns 200, (5) cleans up the old file. The script MUST exit with an error if the download or generation fails, leaving the existing tiles untouched.
- [ ] T027 [US5] Verify scripts/update-tiles.sh runs end-to-end: tiles are regenerated, server restarts, and /health returns 200 after the swap (requires ~30 min manual run)

**Checkpoint**: Data update process documented and scripted. Existing tiles preserved on failure.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final documentation and validation

- [x] T028 [P] Make style JSON URLs configurable: created scripts/set-tile-server-url.sh to rewrite URLs in all style files for production deployment
- [ ] T029 Run the full quickstart.md walkthrough from a clean state (no data/ directory) and verify every step works as documented (manual walkthrough)
- [x] T030 [P] Add a README.md at the repository root with project overview, prerequisites, quickstart reference, and links to specs/001-vector-tile-server/ documentation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (directory structure must exist)
- **US1 (Phase 3)**: Depends on Phase 2 (tiles must be generated)
- **US2 (Phase 4)**: Depends on Phase 3 (Martin must be running and serving tiles)
- **US3 (Phase 5)**: Depends on Phase 4 (styles must be served for the demo page)
- **US4 (Phase 6)**: Depends on Phase 4 (styles must be served)
- **US5 (Phase 7)**: Depends on Phase 3 (Martin must be running to test updates)
- **Polish (Phase 8)**: Depends on all user stories

### User Story Dependencies

- **US1 (P1)**: Depends on Foundational only — MVP, no other story dependencies
- **US2 (P2)**: Depends on US1 (needs running Martin)
- **US3 (P3)**: Depends on US2 (needs served styles for demo page)
- **US4 (P4)**: Depends on US2 (needs served styles). Can run in parallel with US3
- **US5 (P5)**: Depends on US1 (needs running Martin). Can run in parallel with US2-US4

### Parallel Opportunities

- T005 and T006 can run in parallel (independent asset downloads)
- T015 and T016 can run in parallel (independent style downloads)
- US3 and US4 can run in parallel after US2 completes
- US5 can run in parallel with US2-US4 after US1 completes
- T028 and T030 can run in parallel

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (generate tiles, get fonts/sprites)
3. Complete Phase 3: User Story 1 (Martin serves tiles)
4. **STOP and VALIDATE**: curl tile endpoints, verify data
5. Working tile server with no styling or demo pages

### Incremental Delivery

1. Setup + Foundational → Raw materials ready
2. US1 → Tiles served (MVP!)
3. US2 → Styles, fonts, sprites working → Styled maps
4. US3 → MapLibre GL JS demo → Visual proof
5. US4 → Leaflet demo → Secondary client validated
6. US5 → Update script → Operational readiness
7. Polish → Documentation complete

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- This is an infrastructure project — most tasks create config files or run/verify Docker commands, not application code
