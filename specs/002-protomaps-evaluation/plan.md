# Implementation Plan: Protomaps Evaluation

**Branch**: `002-protomaps-evaluation` | **Date**: 2026-02-18 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-protomaps-evaluation/spec.md`

## Summary

Evaluate Protomaps as an alternative to the current Martin/Planetiler tile serving stack by building a standalone MapLibre GL JS demo that loads vector tiles from a publicly available PMTiles source via HTTP range requests. All Protomaps assets are isolated in a `protomaps/` directory, leaving existing infrastructure untouched. Styles are generated at runtime using the `@protomaps/basemaps` library (5 flavors: light, dark, white, black, grayscale).

## Technical Context

**Language/Version**: HTML5 + vanilla JavaScript (no build tooling)
**Primary Dependencies**:
- MapLibre GL JS 5.x (CDN)
- pmtiles 4.4.0 (CDN) — protocol handler for range-request tile fetching
- @protomaps/basemaps 5.x (CDN) — programmatic style generation for Tilezen schema

**Storage**: N/A — no server-side storage; tiles fetched from remote PMTiles URL
**Testing**: Manual browser testing (open HTML file, verify rendering)
**Target Platform**: Modern web browsers (Chrome, Firefox, Safari, Edge)
**Project Type**: Static web — single HTML file with CDN dependencies
**Performance Goals**: Initial map render within 5 seconds on broadband
**Constraints**: Must work from a static file server; no tile server process; no build step
**Scale/Scope**: Single demo page with 5 styles, feature inspector, nav controls

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| **I. Open Standards** | PASS | MVT tiles via PMTiles (open format), MapLibre Style Spec, self-hostable assets |
| **II. Leverage Existing Tools** | PASS | Uses pmtiles library, @protomaps/basemaps, MapLibre GL JS — no custom tile engine |
| **III. Client Compatibility** | PASS | MapLibre GL JS is the primary client; Leaflet evaluation deferred (out of scope for PoC) |
| **IV. Style Ownership** | PASS | Styles generated programmatically from open-source basemaps package; customizable via flavor overrides; can export to static JSON for version control |
| **V. Operational Simplicity** | PASS | Zero server infrastructure — static HTML file + remote tiles. Simplest possible deployment |

**Post-Phase 1 re-check**: All gates still pass. The static-file serving model exceeds the operational simplicity bar. PMTiles is explicitly listed as an approved format in the constitution's Technology Constraints.

## Project Structure

### Documentation (this feature)

```text
specs/002-protomaps-evaluation/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (minimal — no custom APIs)
│   └── README.md
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
protomaps/
├── examples/
│   └── maplibre-demo.html    # Standalone PoC — MapLibre + PMTiles + basemaps styles
└── README.md                 # Protomaps evaluation notes and comparison
```

**Structure Decision**: A top-level `protomaps/` directory mirrors the existing project layout (`examples/`, `styles/`, `scripts/`) but keeps all Protomaps assets fully isolated. No `styles/` or `scripts/` subdirectories are needed for this evaluation since styles are generated at runtime and no tile generation scripts are required.

## Complexity Tracking

No constitution violations. No complexity justifications needed.
