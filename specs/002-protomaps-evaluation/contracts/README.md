# Contracts: Protomaps Evaluation

This feature has no custom APIs or server-side endpoints. All interactions are client-side:

- **Tile fetching**: HTTP GET with `Range` header to remote PMTiles URL (handled by `pmtiles` JS library)
- **Font loading**: HTTP GET to `https://protomaps.github.io/basemaps-assets/fonts/{fontstack}/{range}.pbf`
- **Sprite loading**: HTTP GET to `https://protomaps.github.io/basemaps-assets/sprites/v4/{flavor}[.json|.png|@2x.json|@2x.png]`

No custom contracts are needed — all protocols are standard HTTP and are handled by MapLibre GL JS and the pmtiles library.
