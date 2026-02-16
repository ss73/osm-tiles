<!--
Sync Impact Report
  Version change: 0.0.0 → 1.0.0 (initial ratification)
  Modified principles: N/A (initial version)
  Added sections:
    - Core Principles (5 principles)
    - Technology Constraints
    - Development Workflow
    - Governance
  Removed sections: N/A
  Templates requiring updates:
    - .specify/templates/plan-template.md — ✅ no changes needed (generic)
    - .specify/templates/spec-template.md — ✅ no changes needed (generic)
    - .specify/templates/tasks-template.md — ✅ no changes needed (generic)
  Follow-up TODOs: None
-->

# osm-tiles Constitution

## Core Principles

### I. Open Standards

All tile data and styling MUST use open, vendor-neutral formats.

- Vector tiles MUST use the Mapbox Vector Tile (MVT) specification
- Tile storage MUST use MBTiles or PMTiles — no proprietary formats
- Map styles MUST use the MapLibre Style Spec (open fork of the
  Mapbox Style Specification)
- Font glyphs and sprite sheets MUST be self-hosted alongside tiles

**Rationale**: The entire motivation for this project is escaping
vendor lock-in. Every format choice must reinforce that independence.

### II. Leverage Existing Tools

Use proven open-source tooling for tile generation and serving.
Build integration and configuration — not tile engines.

- Tile generation SHOULD use established pipelines (e.g.,
  OpenMapTiles, Planetiler, osm2pgsql + Mapnik)
- Tile serving SHOULD use purpose-built servers (e.g.,
  tileserver-gl, martin, TileServer)
- Custom code MUST be limited to configuration, deployment
  scripting, and style customization
- Evaluate tools by community health, documentation quality,
  and active maintenance before adopting

**Rationale**: Mature OSM tooling exists for every stage of the
pipeline. Re-implementing what already works wastes effort and
introduces bugs that the community has already solved.

### III. Client Compatibility

The tile server MUST work seamlessly with MapLibre GL JS and
Leaflet to minimize migration from Mapbox.

- MapLibre GL JS is the primary client — all features MUST
  work with it
- Leaflet support MUST be maintained via vector tile plugins
  (e.g., maplibre-gl-leaflet or protomaps-leaflet)
- Tile URLs and style endpoints MUST follow conventions that
  MapLibre GL JS and Leaflet expect without custom adapters
- Switching from Mapbox GL JS to MapLibre GL JS SHOULD require
  only a library swap and endpoint change in consuming apps

**Rationale**: The value of this project is measured by how
painlessly existing Mapbox-dependent applications can migrate.

### IV. Style Ownership

Full control over map appearance is a primary goal. Styles MUST
be customizable without regenerating tiles.

- Map styles MUST be stored as version-controlled JSON files
  in this repository
- Style changes MUST NOT require re-processing tile data
- The project MUST support multiple style variants (e.g.,
  light, dark, satellite-hybrid) as independent style files
- Custom fonts, icons, and sprites MUST be self-hosted and
  version-controlled

**Rationale**: Freedom to customize look and feel is an explicit
project goal and a key advantage over subscription services.

### V. Operational Simplicity

The system MUST be straightforward to deploy, update, and maintain
as self-hosted infrastructure.

- Deployment SHOULD use containers (Docker/Podman) with
  documented compose files
- OSM data updates MUST have a documented, repeatable process
- The system MUST run on a single machine — distributed
  deployment is out of scope unless proven necessary
- Resource requirements (disk, memory, CPU) MUST be documented
  for target region coverage

**Rationale**: This replaces a managed subscription. If operating
it becomes burdensome, the project fails its purpose.

## Technology Constraints

- **Tile format**: Mapbox Vector Tile (MVT) served over HTTP(S)
- **Tile packaging**: MBTiles (SQLite) or PMTiles (single-file,
  cloud-native) — choose based on deployment target
- **Primary client**: MapLibre GL JS (drop-in Mapbox GL JS
  replacement)
- **Secondary client**: Leaflet with vector tile plugin
- **Style format**: MapLibre Style Spec JSON
- **OSM data source**: OpenStreetMap planet or regional extracts
  from Geofabrik or similar providers
- **Containerization**: Docker or Podman for reproducible deployment
- **Custom code**: Limited to glue scripts, configuration, and
  style JSON — not tile processing engines

## Development Workflow

- Prefer configuration over code — when a tool supports a
  declarative config file, use it instead of writing a wrapper
- Document every manual step — if a process cannot be scripted,
  it MUST be documented with exact commands
- Test with a small regional extract first (e.g., a single
  country or metro area) before processing larger datasets
- Version-control all configuration, styles, and deployment
  manifests — tile data itself is generated, not committed
- Keep a decision log for tool choices: record what was evaluated,
  what was chosen, and why

## Governance

This constitution defines the non-negotiable principles for the
osm-tiles project. All design decisions, tool selections, and
implementation work MUST align with these principles.

- **Amendments**: Any change to principles requires updating this
  file, incrementing the version, and noting the change in the
  Sync Impact Report comment block above
- **Versioning**: MAJOR for principle removals or redefinitions,
  MINOR for new principles or material expansions, PATCH for
  clarifications and wording fixes
- **Compliance**: Feature specs and implementation plans MUST
  reference applicable principles. The plan template's
  "Constitution Check" section MUST verify alignment before
  work begins

**Version**: 1.0.0 | **Ratified**: 2026-02-16 | **Last Amended**: 2026-02-16
