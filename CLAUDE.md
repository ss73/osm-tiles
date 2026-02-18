# osm-tiles Development Guidelines

## Project Overview

Self-hosted vector tile server replacing a Mapbox subscription. Uses open-source
tooling for tile generation and serving — custom code is limited to configuration,
deployment scripts, and map style customization.

## Constitution

Project principles are defined in `.specify/memory/constitution.md`. All design
decisions and implementation work MUST align with these principles:

1. **Open Standards** — MVT tiles, MBTiles/PMTiles storage, MapLibre Style Spec
2. **Leverage Existing Tools** — use community OSM tooling, don't build tile engines
3. **Client Compatibility** — MapLibre GL JS (primary), Leaflet (secondary)
4. **Style Ownership** — version-controlled style JSON, independent of tile data
5. **Operational Simplicity** — containerized, single-machine, documented processes

## Technology Constraints

- **Tile format**: Mapbox Vector Tile (MVT) over HTTP(S)
- **Tile packaging**: MBTiles or PMTiles
- **Primary client**: MapLibre GL JS
- **Secondary client**: Leaflet with vector tile plugin
- **Style format**: MapLibre Style Spec JSON
- **Data source**: OpenStreetMap extracts (Geofabrik or similar)
- **Deployment**: Docker/Podman with compose files

## Workflow Rules

- Prefer configuration over code
- Test with small regional extracts before processing large datasets
- Version-control all config, styles, and deployment manifests
- Tile data is generated artifacts — never committed to the repo
- Document tool evaluation decisions (what was considered, what was chosen, why)
- When writing commit messages, *never* include auhtor or co-author info

## Speckit

Feature planning uses the Specify workflow in `.specify/`. Key commands:
`/speckit.specify`, `/speckit.plan`, `/speckit.tasks`, `/speckit.implement`

## Active Technologies
- MBTiles (SQLite) — single file per coverage area (001-vector-tile-server)
- HTML5 + vanilla JavaScript (no build tooling) (002-protomaps-evaluation)
- N/A — no server-side storage; tiles fetched from remote PMTiles URL (002-protomaps-evaluation)

## Recent Changes
- 001-vector-tile-server: Added MBTiles (SQLite) — single file per coverage area
