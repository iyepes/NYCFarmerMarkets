# Implementation Plan: Internal map and directions button (issue #1)

## Overview
Swift, SwiftUI, MapKit `Map`, Swift Testing (unit), XCTest (UI). Work happens on branch `feature/1-internal-map-and-directions-button`. New files under `NYCFarmerMarkets/` are auto-included (synchronized groups), so `project.pbxproj` is not edited. Colors only from `AppPalette`, icons only from `AppIcon`. Pure logic is `nonisolated`. Build: `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination 'platform=iOS Simulator,name=<an installed iPhone>' build`. Unit tests: same command with `test -only-testing:NYCFarmerMarketsTests`. UI tests: `-only-testing:NYCFarmerMarketsUITests`. Every task leaves the app building. Do not stage or commit anything under `.agents/`.

Decision on the pin identifier (the design leaves it conditional): `MarketPin` gets an `identifier` parameter defaulting to `"market-pin"`. The pushed screen passes `"selected-market-pin"`. This keeps the Map tab untouched and means the UI test never counts the Map tab's pins, whatever MapKit does with the hierarchy.

## Tasks

- [x] 1. Add the `directions` icon to the AppIcon registry
  - Files: `NYCFarmerMarkets/Theme/AppIcon.swift`, `NYCFarmerMarketsTests/NYCFarmerMarketsTests.swift`
  - Add `case directions` after `openInMaps`; in `source` add `.directions: .symbol("arrow.triangle.turn.up.right.diamond.fill")`; in `accessibilityName` add `.directions: "Look for directions"`. `openInMaps` keeps `map.fill`.
  - In `NYCFarmerMarketsTests.swift`, add a `@Test` next to `splashIconsAndLabels` asserting `AppIcon.directions.source == .symbol("arrow.triangle.turn.up.right.diamond.fill")` and `AppIcon.directions.accessibilityName == "Look for directions"` (runs on macOS too; `everyIconResolves` is `canImport(UIKit)` only, so it covers iOS only). No new import.
  - Requirements: 2.1, 3.1
  - Verify: build; unit tests pass, including the new test and `everyIconResolves` (checks the symbol exists on iOS).

- [ ] 2. Add the pure `SingleMarketMap` logic with unit tests
  - Files: create `NYCFarmerMarkets/Models/SingleMarketMap.swift`; create `NYCFarmerMarketsTests/SingleMarketMapTests.swift`
  - Implement `nonisolated enum SingleMarketMap` as in the design: nested `nonisolated struct Pin: Identifiable, Equatable, Sendable` (explicit `nonisolated`, project default isolation is MainActor) with `id`, `name`, `latitude`, `longitude` and computed `coordinate`; `static let span = MKCoordinateSpan(0.01, 0.01)`; `static func pins(for: Market) -> [Pin]` (empty unless both latitude and longitude exist); `static func region(for: Market) -> MKCoordinateRegion?`. Read `Market`'s `latitude`/`longitude`/`coordinate` in `NYCFarmerMarkets/Models/` first and use the actual property types.
  - Tests (`import MapKit`, `import Testing`, `@testable import NYCFarmerMarkets`, using `Fixture.market(...)` from `NYCFarmerMarketsTests.swift`): one pin with the market's id, name and coordinates; `[]` when `lat: nil, lon: nil`; `[]` when only one is nil; `region(for:)` centered on the coordinate with `SingleMarketMap.span`; `region(for:)` nil without a coordinate.
  - Requirements: 1.4, 1.5, 2.3
  - Verify: unit tests pass, including the new suite.

- [ ] 3. Move `MarketPin` to a shared file
  - Files: create `NYCFarmerMarkets/Views/Shared/MarketPin.swift`; modify `NYCFarmerMarkets/Views/MarketMapView.swift`
  - Cut `private struct MarketPin` from `MarketMapView.swift` (line ~67) into the new file as an internal struct, body unchanged. Add `var identifier: String = "market-pin"` after `isSelected` and use it in `.accessibilityIdentifier(identifier)`. Existing `MarketPin(name:isFavorite:isSelected:)` call in `MarketMapView` keeps compiling (memberwise init default).
  - Requirements: 3.2 (pin label unchanged), keeps Map tab behavior (Out of Scope)
  - Verify: build; existing UI test `testMapPinMoreInfoAndClose` still passes (it queries `market-pin`).

- [ ] 4. Extract the shared detail toolbar
  - Files: create `NYCFarmerMarkets/Views/Shared/MarketDetailToolbar.swift`; modify `NYCFarmerMarkets/Views/MarketDetailView.swift`
  - Create `struct MarketDetailToolbar: ToolbarContent` with `market`, `onClose`, and `@Environment(FavoritesStore.self)`. Move the two `ToolbarItem`s from `MarketDetailView` verbatim (`.cancellationAction` Close with `IconView(.close, size: 24)`, label "Close", id `close-detail`; `.primaryAction` favorite toggle with scale, spring animation, labels, id `favorite-toggle`, `.sensoryFeedback`). Compute `isFavorite` inside the type. In `MarketDetailView` replace the toolbar closure with `.toolbar { MarketDetailToolbar(market: market, onClose: { dismiss() }) }`. If the `ToolbarContent` type cannot read the environment on a target, report it rather than redesigning.
  - Requirements: design decision 9 (Close and favorite stay available on the pushed screen)
  - Verify: build; existing UI tests `testOpenDetailFromListAndClose` and `testFavoriteAppearsInFavoritesTabAndSwipeRemoves` still pass.

- [ ] 5. Create the pushed screen `MarketLocationMapView`
  - Files: create `NYCFarmerMarkets/Views/MarketLocationMapView.swift`
  - `struct MarketLocationMapView: View` with `let market: Market`, `let onClose: () -> Void`, `@Environment(FavoritesStore.self)`, `@State private var position: MapCameraPosition`. Write the init explicitly: set `self.market`, `self.onClose`, and `_position = State(initialValue: SingleMarketMap.region(for: market).map { MapCameraPosition.region($0) } ?? .automatic)`.
  - Body: `Map(position: $position) { ForEach(SingleMarketMap.pins(for: market)) { pin in Annotation(pin.name, coordinate: pin.coordinate, anchor: .center) { MarketPin(name: pin.name, isFavorite: favorites.isFavorite(market), isSelected: false, identifier: "selected-market-pin") } } }`, `.mapStyle(.standard)`, `.navigationTitle(market.name)`, `#if !os(macOS) .navigationBarTitleDisplayMode(.inline) #endif`, `.toolbar { MarketDetailToolbar(market: market, onClose: onClose) }`. Put `.accessibilityIdentifier("market-location-map")` on a wrapping `ZStack` around the `Map` (not on the `Map`) so child pins stay queryable. No `MarketStore`, no `@Environment(\.dismiss)`, no raw colors or symbol names.
  - Requirements: 1.4, 1.5, 1.6, 3.2, 3.3
  - Verify: build succeeds for iOS; also build for macOS (`-destination 'platform=macOS'`) to confirm the view and toolbar compile there.

- [ ] 6. Wire the two buttons and the push in `MarketDetailView`
  - Files: modify `NYCFarmerMarkets/Views/MarketDetailView.swift`
  - Add `@State private var showsMap = false`. Replace the single button inside `if market.coordinate != nil` with `VStack(spacing: 10)` holding: (a) "Open in Maps" (existing label, `IconView(.openInMaps, size: 18)`, `ThemedButtonStyle()`, id `open-in-maps`, action `showsMap = true`); (b) "Look for directions" (`Label { Text("Look for directions") } icon: { IconView(.directions, size: 18) }`, `ThemedButtonStyle()`, id `look-for-directions`, action `openInExternalMaps()`).
  - Rename private `openInMaps()` to `openInExternalMaps()` with the body unchanged (not unit tested, per the design).
  - Attach `.navigationDestination(isPresented: $showsMap) { MarketLocationMapView(market: market, onClose: { dismiss() }) }` to the `ScrollView` (inside the `NavigationStack`), before or after `.navigationTitle("Market details")`.
  - Requirements: 1.1, 1.2, 1.3, 1.7, 1.8, 2.1, 2.2, 2.3, 3.1
  - Verify: build for iOS and macOS; existing UI tests still pass; manual check below (task 8).

- [ ] 7. Add UI tests for the push, pin, toolbar, back and close
  - Files: modify `NYCFarmerMarketsUITests/NYCFarmerMarketsUITests.swift`
  - Reuse `waitForMarkets()`, `selectTab(_:)`, `element(_:)`, `waitUntilGone(_:_:)` and the `closeButton` used by `testMapPinMoreInfoAndClose`. Add, after that test:
    1. `testOpenInMapsPushesSingleMarketMap`: `waitForMarkets()`, `selectTab("Map")`, tap `market-pin` (first match), tap `more-info`, wait for `close-detail`. Assert buttons `open-in-maps` and `look-for-directions` exist. Do not tap "Look for directions" (it leaves the app). Tap `open-in-maps`. Wait on `app.descendants(matching: .any).matching(identifier: "market-location-map").firstMatch.waitForExistence(timeout: 10)`; do NOT use `app.maps.firstMatch` for this (the Map tab's map stays in the hierarchy). Only after it exists, assert `app.descendants(matching: .any).matching(identifier: "selected-market-pin").count == 1`. Assert `open-in-maps` is gone via `waitUntilGone`, and `close-detail` and `favorite-toggle` exist. No `app.sheets` assertion (or label it best-effort). Then go back: on iOS tap `app.navigationBars.buttons["Market details"]`; fallbacks `app.buttons["Market details"]`, `app.buttons["Back"]`; never `boundBy: 0`. Assert `open-in-maps` and `look-for-directions` exist again. Wrap the Back-button part in `#if os(iOS)` if no query is reliable on macOS after running; record that in the task notes.
    2. `testCloseFromPushedMapDismissesSheet`: same path to the pushed map, tap `close-detail`, assert `more-info` reappears and `close-detail` is gone.
  - Requirements: 1.2, 1.3, 1.4, 1.7, 3.1, acceptance criteria 1-4, 6, 7, design decision 9
  - Verify: `xcodebuild ... test -only-testing:NYCFarmerMarketsUITests` passes on an iOS simulator, including the two new tests and all existing ones. If the Back query fails, fix it empirically and rerun before moving on.

- [ ] 8. Full verification and manual check
  - Files: none
  - Run the complete unit and UI test suites for the `NYCFarmerMarkets` scheme and a macOS build. Check that no `Color(` literals, hex literals or raw SF Symbol names were added outside `NYCFarmerMarkets/Theme/` (a code review of the diff, supplementing the tests).
  - Manual (macOS and iOS): both buttons render for a market with a coordinate; "Open in Maps" pushes the map showing one pin and the market name, without opening Apple Maps; Back returns to the same market; Close on the pushed screen dismisses the whole sheet; "Look for directions" opens the market in external Apple Maps as before. Report any platform where the `.cancellationAction` Close item does not show on the pushed bar, without redesigning.
  - Requirements: all; acceptance criteria 1-7
  - Verify: all unit and UI tests green; macOS and iOS builds succeed.

- [ ] 9. Record the spec and amend the original requirement
  - Files: create `.kiro/specs/internal-map-and-directions-button/requirements.md` (from `.agents/tasks/feature-to-pr/01-requirements.md`), `design.md` (from `02-design.md`, omitting the "Responses to design review" section and applying the "Implementation notes" overrides in place), `tasks.md` (this plan with completed items checked); modify `.kiro/specs/nyc-farmer-markets/requirements.md` line 92 (Requirement 5.4).
  - Add a note under 5.4 that "Open in Maps" now pushes the in-app single-market map, and "Look for directions" opens external Apple Maps, pointing to the new spec. Do not stage anything under `.agents/`.
  - Requirements: documentation convention (.kiro/specs/<feature>/{requirements,design,tasks}.md)
  - Verify: the three files exist with the content above; build and tests are unaffected (docs only).
