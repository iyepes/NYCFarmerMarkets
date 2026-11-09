# Design: Internal map and directions button (issue #1)

## Overview
`MarketDetailView` currently has one button, "Go to Map", which calls `MKMapItem.openInMaps()`. After this change, "Go to Map" pushes a new in-app screen (`MarketLocationMapView`) onto the NavigationStack the sheet already owns. That screen shows a MapKit `Map` with exactly one annotation, for the selected market, and keeps the sheet's Close and favorite toolbar. A second button, "Directions", takes over the old `openInMaps()` code unchanged. Both buttons appear only when `market.coordinate != nil`, as today.

**Technology stack (locked):** Swift, SwiftUI, MapKit's SwiftUI `Map` (already used by `MarketMapView`), Swift Testing for unit tests, XCTest for UI tests. No new dependencies, no project file edits (synchronized groups).

## Key decisions

**Navigation: `navigationDestination(isPresented:)` driven by `@State private var showsMap = false`.** The alternatives were `NavigationLink(value:)` with a Hashable route type, or a `NavigationPath`. A link would force `ThemedButtonStyle` onto a NavigationLink, which renders inconsistently on macOS, and a path needs a route type for a single destination. A `Button` that sets `showsMap = true` keeps `ThemedButtonStyle`, the `open-in-maps` identifier, and the Button element type UI tests query. The destination modifier goes on the `ScrollView` inside the `NavigationStack`, so the screen is pushed (Req 1.2/1.3) and the standard back button returns to the same `MarketDetailView` (Req 1.7). Nothing is presented as a sheet or cover.

**New view instead of reusing `MarketMapView`.** `MarketMapView` is the Map tab: it depends on `MarketStore`, shows every market, and has selection, a card and an offline banner. Adding a "single market" mode would add branches to a working screen and risk the Map tab (out of scope). A small new view is simpler. The pin is shared: `MarketPin` is `private` in `MarketMapView.swift`, so it moves unchanged to `NYCFarmerMarkets/Views/Shared/MarketPin.swift` as an internal struct (visuals, accessibility and `market-pin` identifier unchanged).

**Pure logic in a `nonisolated` type.** New file `NYCFarmerMarkets/Models/SingleMarketMap.swift`:

```swift
import MapKit

/// What the single-market map screen shows. Pure so it can be unit tested.
nonisolated enum SingleMarketMap {
    struct Pin: Identifiable, Equatable, Sendable {
        let id: String
        let name: String
        let latitude: Double
        let longitude: Double
        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }

    /// Degrees visible around the pin (about 1 km, neighborhood level).
    static let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)

    /// The only annotations the screen may show: one pin, or none when the market has no coordinate.
    static func pins(for market: Market) -> [Pin]

    /// Region centered on the market's coordinate with `span`, or nil without a coordinate.
    static func region(for market: Market) -> MKCoordinateRegion?
}
```

`pins(for:)` returns `[]` when `latitude` or `longitude` is nil, otherwise exactly one `Pin` built from the market's id, name and coordinates. The screen renders `ForEach(pins)`, so "exactly one annotation, only the selected market" (Req 1.4) holds by construction. `Pin` stores raw doubles because `CLLocationCoordinate2D` is not `Equatable` or `Sendable`.

**New screen** `NYCFarmerMarkets/Views/MarketLocationMapView.swift`:

```swift
struct MarketLocationMapView: View {
    let market: Market
    let onClose: () -> Void          // the SHEET's dismiss action, passed down from MarketDetailView
    @Environment(FavoritesStore.self) private var favorites
    @State private var position: MapCameraPosition   // set in init from SingleMarketMap.region(for:); .automatic if nil

    var body: some View {
        Map(position: $position) {
            ForEach(SingleMarketMap.pins(for: market)) { pin in
                Annotation(pin.name, coordinate: pin.coordinate, anchor: .center) {
                    MarketPin(name: pin.name, isFavorite: favorites.isFavorite(market), isSelected: false)
                }
            }
        }
        .mapStyle(.standard)
        .navigationTitle(market.name)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar { MarketDetailToolbar(market: market, onClose: onClose) }
        .accessibilityIdentifier("market-location-map")
    }
}
```

The pin's existing accessibility label (market name, plus ", favorite" when applicable) satisfies VoiceOver (Req 3.2). The title shows the market name (Req 1.6). The map stays interactive (pan/zoom) and shows no user location (Out of Scope). The screen has no card, offline banner or `MarketStore` dependency, so it cannot show other markets. Its environment dependency is `FavoritesStore` (pin state and the favorite toggle), which `MarketDetailView` already reads; it also takes the `onClose` closure. It does not use `@Environment(\.dismiss)`: inside a pushed destination `dismiss` pops the screen instead of closing the sheet, so the sheet-level dismiss held by `MarketDetailView` is passed in.

The annotation anchor is `.center` because `MarketPin` is a circular badge, so the circle sits on the coordinate. `MarketMapView` anchors the same pin at `.bottom`; that is existing Map-tab behavior and stays untouched (out of scope), so the screens intentionally differ.

**Shared toolbar (user decision: Close and favorite stay available on the pushed screen).** New file `NYCFarmerMarkets/Views/Shared/MarketDetailToolbar.swift`:

```swift
struct MarketDetailToolbar: ToolbarContent {
    let market: Market
    let onClose: () -> Void
    @Environment(FavoritesStore.self) private var favorites

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) { /* Close button, moved verbatim, action: onClose */ }
        ToolbarItem(placement: .primaryAction) { /* favorite toggle, moved verbatim */ }
    }
}
```

The two `ToolbarItem`s move verbatim from `MarketDetailView` (same icons, `close-detail` and `favorite-toggle` identifiers, accessibility labels, spring animation, sensory feedback). `MarketDetailView` uses `.toolbar { MarketDetailToolbar(market: market, onClose: { dismiss() }) }` and the pushed screen uses the same type, so behavior cannot drift. Close on the pushed screen dismisses the whole sheet; the system back button pops. If the `.cancellationAction` item does not render on the pushed bar on some platform, that is caught by the UI assertion below and the manual iOS/macOS check, and the implementer reports it rather than redesigning.

**Detail view changes** (`MarketDetailView.swift`): inside `if market.coordinate != nil`, a `VStack(spacing: 10)` with two buttons.
1. "Go to Map": the existing `Label { Text("Go to Map") } icon: { IconView(.openInMaps, size: 18) }`, `ThemedButtonStyle()`, identifier `open-in-maps` (kept), action `showsMap = true`.
2. "Directions": the label mirrors the first one exactly, `Label { Text("Directions") } icon: { IconView(.directions, size: 18) }`, `ThemedButtonStyle()`, identifier `look-for-directions`, action: the existing private `openInMaps()` renamed `openInExternalMaps()` with an unchanged body (`MKMapItem(location:address:)`, `name = market.name`, `openInMaps()`). The accessibility label is the visible title (the icon is hidden by `IconView`), so Req 3.1 needs no extra modifier.

`.navigationDestination(isPresented: $showsMap) { MarketLocationMapView(market: market, onClose: { dismiss() }) }` is attached to the `ScrollView`; `dismiss` is the sheet-level action `MarketDetailView` already holds.

**Icons.** `AppIcon` gets one new case, `directions`: source `.symbol("arrow.triangle.turn.up.right.diamond.fill")`, accessibilityName `"Directions"`. `openInMaps` keeps `map.fill`, so the buttons have distinct icons. The existing `everyIconResolves` test verifies the symbol exists. No colors are added.

## Error handling and validation
- Input: the only external input is `Market`, already validated at parse time by `Market.parseCoordinate` (rejects nil, non-numeric and zero). Latitude and longitude are optional; if either is nil there is no coordinate. No range validation is added; that is the data layer's concern and unchanged.
- No coordinate: the buttons are not rendered, so the screen is unreachable (Req 2.3). Defensively, `pins(for:)` returns `[]` and `region(for:)` returns nil, and the screen falls back to an `.automatic` camera with an empty map. Not an error, not logged.
- `MKMapItem.openInMaps()` returns `Void` and surfaces no failure, same as today. The caller gets nothing and nothing is logged; behavior is unchanged (Out of Scope).
- Map tile failures (offline) are handled by MapKit (blank tiles, pin remains). Nothing to handle or log.
- Invariant "only the selected market appears on the in-app map" is owned by `SingleMarketMap.pins(for:)`, a pure function of one `Market`; the screen has no access to `MarketStore`.
- Invariant "toolbar behaves the same on both screens" is owned by the single `MarketDetailToolbar` type.

## Files
- Add `NYCFarmerMarkets/Models/SingleMarketMap.swift`.
- Add `NYCFarmerMarkets/Views/MarketLocationMapView.swift`.
- Add `NYCFarmerMarkets/Views/Shared/MarketDetailToolbar.swift` (extracted from `MarketDetailView`).
- Add `NYCFarmerMarkets/Views/Shared/MarketPin.swift` (moved from `MarketMapView.swift`, `private` removed).
- Modify `NYCFarmerMarkets/Views/MarketMapView.swift` (remove `MarketPin`).
- Modify `NYCFarmerMarkets/Views/MarketDetailView.swift` (buttons, destination, shared toolbar).
- Modify `NYCFarmerMarkets/Theme/AppIcon.swift` (`directions` case in `source` and `accessibilityName`).
- Tests: `NYCFarmerMarketsTests/SingleMarketMapTests.swift` (new; `import MapKit`, `import Testing`, `@testable import NYCFarmerMarkets`), `NYCFarmerMarketsTests/NYCFarmerMarketsTests.swift` (icon assertion; uses no MapKit types, so no new import), `NYCFarmerMarketsUITests/NYCFarmerMarketsUITests.swift` (new UI tests).
- Spec docs: `.kiro/specs/internal-map-and-directions-button/{requirements,design,tasks}.md`, plus a note amending Requirement 5.4 in `.kiro/specs/nyc-farmer-markets/requirements.md`.

## Testing
Unit tests (Swift Testing, using `Fixture.market(...)`):
- `pins(for:)` returns exactly one pin with the market's id, name and coordinates when a coordinate exists.
- `pins(for:)` returns `[]` for `lat: nil, lon: nil` and for only one of them missing.
- `region(for:)` is centered on the coordinate with `SingleMarketMap.span`, and is nil without a coordinate.
- `AppIcon.directions.accessibilityName == "Directions"` and its source is the expected symbol.

UI tests (XCTest), using the Map tab path because pins always have coordinates:
1. `waitForMarkets()`, `selectTab("Map")`, tap `market-pin`, tap `more-info`, wait for `close-detail`.
2. Assert buttons `open-in-maps` and `look-for-directions` exist.
3. Tap `open-in-maps`. Assert the pushed map with `let map = app.maps.firstMatch; XCTAssertTrue(map.waitForExistence(timeout: 10))`, as the existing map test does. Fallback if that does not distinguish the screens: `app.descendants(matching: .any).matching(identifier: "market-location-map").firstMatch`. Do not use `app.otherElements["market-location-map"]`; an identifier on a `Map` may not surface there.
4. Assert one pin: `app.descendants(matching: .any).matching(identifier: "market-pin").count == 1`. If MapKit keeps the Map tab's pins in the hierarchy and the count is larger, scope the query to `map.descendants(matching: .any)`; the single-pin guarantee is also covered by the unit test.
5. Assert push, not a new sheet: `open-in-maps` disappears (`waitUntilGone`) and `app.navigationBars.buttons.element(boundBy: 0)` (Back) exists. No `app.sheets` assertion, since SwiftUI sheets often do not surface as sheet elements and it would pass vacuously.
6. Assert `close-detail` and `favorite-toggle` exist on the pushed screen.
7. Tap Back and assert `open-in-maps` and `look-for-directions` exist again.
8. Second test: push the map, tap `close-detail`, assert `more-info` reappears and `close-detail` is gone (Close dismisses the whole sheet).

The tests do not tap "Directions" because it would leave the app for Maps; that call is unchanged code and is covered by manual verification. Manual check on macOS: both buttons render, the push works, and Close dismisses the sheet from the pushed screen.

## Edge cases
- Favorite toggled on either screen: both read the same `FavoritesStore`, so the pin and toolbar icon stay in sync.
- Very long market names: the inline title truncates; the annotation label is system-managed.
- Dynamic Type, dark mode: no custom layout; `ThemedButtonStyle` and palette tokens handle them.
- Returning from the pushed screen resets `showsMap` to false via the binding, so the button works again.
- visionOS: only cross-platform APIs are used; the `#if !os(macOS)` guard is repeated for the title display mode.


## Implementation notes (from design review round 4; the design loop was ended by the user with these still open)

These items override anything earlier in this document that conflicts with them. Treat them as requirements for the plan and the implementation.

1. **Pushed-map UI assertion (was MEDIUM).** In the UI test, after tapping `open-in-maps`, wait on `app.descendants(matching: .any).matching(identifier: "market-location-map").firstMatch.waitForExistence(timeout: 10)`. Do NOT use `app.maps.firstMatch` for this step: the Map tab's own map stays in the hierarchy under the sheet and would make the assertion pass vacuously. Count pins only after `market-location-map` exists, scoped to that element's descendants, and never count the Map tab's pins. If an identifier on `Map` hides its children, put the identifier on a wrapping `ZStack`/`Group` and keep the pin identifier `selected-market-pin` on the pin.
2. **Back button query (was MEDIUM).** Do not use `navigationBars.buttons.element(boundBy: 0)`. Find the Back button by the previous screen's title: `app.navigationBars.buttons["Market details"]`, with a macOS-safe fallback `app.buttons["Market details"]` or `app.buttons["Back"]`; if neither can be made reliable, make the push/back UI test iOS-only (`#if os(iOS)`) and cover macOS with the build, the unit tests and a manual check. Verify empirically by running the UI test.
3. `MarketLocationMapView` init must be shown explicitly: set `market` (and any close closure), and `_position = State(initialValue: <region for the market> ?? .automatic)`.
4. Mark the nested `SingleMarketMap.Pin` type `nonisolated` explicitly (project default isolation is MainActor).
5. `everyIconResolves` runs only under `canImport(UIKit)`, so it covers iOS only; keep the explicit `AppIcon.directions.source == .symbol(...)` assertion, which runs on macOS too.
6. Drop the `app.sheets.count == 0` assertion or label it best-effort only.
7. Ignore the "Responses to design review" section: it is process history. Do not copy it into the spec (`design.md`) and omit it when recording the spec.
8. The body of the external-Maps action stays unchanged (only the method rename to `openInExternalMaps()`); it is intentionally not unit tested.
9. The Close and favorite toolbar MUST stay available on the pushed screen (shared `MarketDetailToolbar`), as decided by the user (Option A); assert `close-detail` exists on the pushed screen.
