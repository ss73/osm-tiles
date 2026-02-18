# Tasks: Protomaps Evaluation

**Input**: Design documents from `/specs/002-protomaps-evaluation/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: No automated tests requested. Validation is manual (open HTML in browser).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Create project structure and directory isolation

- [x] T001 Create directory structure: `protomaps/examples/` at repository root
- [x] T002 [P] Create Protomaps README with evaluation overview in `protomaps/README.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: No foundational phase needed. This feature has no shared infrastructure, database, or framework setup. All dependencies are CDN-hosted. User stories can begin immediately after setup.

**Checkpoint**: Directory structure ready — user story implementation can begin.

---

## Phase 3: User Story 1 — View a Protomaps-powered map (Priority: P1) MVP

**Goal**: A standalone HTML demo that renders a fully styled vector map from a remote PMTiles source using MapLibre GL JS, with pan/zoom/click-inspect.

**Independent Test**: Open `protomaps/examples/maplibre-demo.html` in a browser and verify the map renders with land, water, roads, buildings, and labels. Click a feature to see its layer and properties in a popup.

### Implementation for User Story 1

- [x] T003 [US1] Create the MapLibre GL JS demo HTML scaffold with CDN imports (maplibre-gl 5.x, pmtiles 4.x, @protomaps/basemaps 5.x) in `protomaps/examples/maplibre-demo.html`
- [x] T004 [US1] Register the pmtiles protocol handler and configure the PMTiles vector source pointing to a public Protomaps daily build URL in `protomaps/examples/maplibre-demo.html`
- [x] T005 [US1] Generate the default "light" style using `basemaps.layers()` and `basemaps.namedFlavor()` with Protomaps-hosted glyphs and sprites in `protomaps/examples/maplibre-demo.html`
- [x] T006 [US1] Add navigation controls (zoom, pan, rotation) and set default view to Stockholm (18.07, 59.33) at zoom 10 in `protomaps/examples/maplibre-demo.html`
- [x] T007 [US1] Implement feature inspector: on map click, show a popup with layer ID and feature properties in `protomaps/examples/maplibre-demo.html`

**Checkpoint**: Map renders with all base layers, supports pan/zoom, and click-inspect works. Single "light" style.

---

## Phase 4: User Story 2 — Switch between map styles (Priority: P2)

**Goal**: A style switcher UI that toggles between at least 3 visually distinct Protomaps flavors (light, dark, grayscale) without page reload.

**Independent Test**: Click each style button and verify the map re-renders with the correct color scheme. Labels, roads, and land cover should be visible in all styles.

### Implementation for User Story 2

- [x] T008 [US2] Add a style switcher control panel (radio buttons or buttons) for light, dark, and grayscale flavors in `protomaps/examples/maplibre-demo.html`
- [x] T009 [US2] Implement style switching logic: regenerate the MapLibre style object with the selected flavor's layers, glyphs, and sprites, then call `map.setStyle()` preserving map position in `protomaps/examples/maplibre-demo.html`

**Checkpoint**: All 3 styles render correctly and switch without page reload. Feature inspector still works after switching.

---

## Phase 5: User Story 3 — Serve tiles without a dedicated tile server (Priority: P3)

**Goal**: Verify and document that the demo works from a simple static HTTP server with no tile server process running.

**Independent Test**: Stop any running Docker containers, serve the project root with `python3 -m http.server 8080`, open `http://localhost:8080/protomaps/examples/maplibre-demo.html`, and confirm tiles load.

### Implementation for User Story 3

- [x] T010 [US3] Verify the demo works when served from `python3 -m http.server` (no Martin, no Docker) and document any CORS or range-request requirements in `protomaps/README.md`
- [x] T011 [US3] Add a "How to run" section to `protomaps/README.md` documenting the static serving approach and comparison with the Martin-based setup

**Checkpoint**: Demo is fully functional from a static file server. README documents the serverless approach.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final documentation and cleanup

- [x] T012 [P] Add inline HTML comments to the demo explaining key Protomaps concepts (PMTiles protocol, Tilezen schema, basemaps library) in `protomaps/examples/maplibre-demo.html`
- [x] T013 Run quickstart.md validation: follow `specs/002-protomaps-evaluation/quickstart.md` steps end-to-end and fix any discrepancies

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **User Story 1 (Phase 3)**: Depends on Setup (T001)
- **User Story 2 (Phase 4)**: Depends on User Story 1 (T003–T007)
- **User Story 3 (Phase 5)**: Depends on User Story 1 (T003–T007); can run in parallel with US2
- **Polish (Phase 6)**: Depends on all user stories complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Setup — no other dependencies
- **User Story 2 (P2)**: Requires the base demo from US1 to exist (adds style switcher to it)
- **User Story 3 (P3)**: Requires the base demo from US1 to exist (tests serving model); independent of US2

### Within Each User Story

- Tasks are sequential within a story (each builds on the previous)
- T003–T005 form the core map rendering pipeline
- T006–T007 add UI controls on top

### Parallel Opportunities

- T001 and T002 can run in parallel (different files)
- US2 (Phase 4) and US3 (Phase 5) can run in parallel after US1 completes
- T012 can run in parallel with T013

---

## Parallel Example: After User Story 1

```text
# These can run concurrently after US1 is complete:
Agent A: T008, T009 (style switcher — US2)
Agent B: T010, T011 (static serving verification — US3)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T002)
2. Complete Phase 3: User Story 1 (T003–T007)
3. **STOP and VALIDATE**: Open the demo, verify map renders with all layers
4. This alone demonstrates whether Protomaps is a viable alternative

### Incremental Delivery

1. Setup → US1 → Validate map rendering (MVP!)
2. Add US2 → Validate style switching
3. Add US3 → Validate serverless serving model
4. Polish → Final documentation and cleanup
5. Each story adds evaluation insight without breaking previous work

---

## Notes

- All tasks target a single HTML file (`protomaps/examples/maplibre-demo.html`) plus a README
- No build tooling, no npm, no Docker — CDN dependencies only
- The PMTiles daily build URL may need updating if it expires; document the URL pattern
- Commit after each phase checkpoint
