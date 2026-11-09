## Plan recorded

Spec: `.kiro/specs/internal-map-and-directions-button/` (requirements.md, design.md, tasks.md) on branch `feature/1-internal-map-and-directions-button`.

### Key requirements
- "Go to Map" pushes an in-app map screen onto the detail sheet's existing NavigationStack (no new sheet or cover). It shows exactly one annotation, the selected market, centered and zoomed, with the market name as the title. Back returns to the same market. It no longer opens Apple Maps.
- New "Directions" button opens the market in external Apple Maps exactly as "Go to Map" does today.
- Both buttons appear only when the market has a coordinate, have accessibility labels and identifiers (`open-in-maps` kept, `look-for-directions` new), and work on iOS and macOS.
- Amends Requirement 5.4 of the original nyc-farmer-markets spec.

### Design approach
- `nonisolated enum SingleMarketMap` (pure, unit tested) returns the single pin and the map region.
- New `MarketLocationMapView` using MapKit `Map`; no `MarketStore` dependency, so it cannot show other markets.
- `MarketPin` moves to a shared file; the Close and favorite toolbar is extracted to a shared `MarketDetailToolbar` used on both screens.
- `MarketDetailView` uses `navigationDestination(isPresented:)`; the old external-Maps code becomes `openInExternalMaps()` behind "Directions".
- New `AppIcon.directions` entry; colors and icons only from the theme tokens.

### Tasks
- [ ] 1. Add the `directions` icon to the AppIcon registry
- [ ] 2. Add the pure `SingleMarketMap` logic with unit tests
- [ ] 3. Move `MarketPin` to a shared file
- [ ] 4. Extract the shared detail toolbar
- [ ] 5. Create the pushed screen `MarketLocationMapView`
- [ ] 6. Wire the two buttons and the push in `MarketDetailView`
- [ ] 7. Add UI tests for the push, pin, toolbar, back and close
- [ ] 8. Full verification and manual check
- [ ] 9. Record the spec and amend the original requirement
