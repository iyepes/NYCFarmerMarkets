# Design Review: Internal map and directions button (issue #1)

Verdict: CHANGES_REQUESTED (2 MEDIUM, 5 NIT)

## Findings

1. MEDIUM, Testing step 3 (pushed-map assertion): `app.maps.firstMatch` does not prove the pushed screen appeared. The Map tab's `Map` stays in the hierarchy under the sheet, because the test starts from the Map tab. `app.maps.firstMatch` therefore exists before the tap, and the assertion passes vacuously. The design hedges with "Fallback if that does not distinguish the screens", which leaves the implementer to guess.
   Fix: make one deterministic rule. After tapping `open-in-maps`, wait on `app.descendants(matching: .any).matching(identifier: "market-location-map").firstMatch.waitForExistence(timeout: 10)`. Drop `app.maps.firstMatch` from this step. Drop the "if MapKit keeps pins..." hedge in step 4. State instead that the pin count is taken only after `market-location-map` exists. Count `market-pin` within that element's descendants. If an identifier on `Map` hides its children, put the identifier on a wrapping `ZStack` or `Group` and say so in the view snippet. Also add: "the Map tab's pins are in the hierarchy and must not be counted".

2. MEDIUM, Testing step 5 (Back button query): `app.navigationBars.buttons.element(boundBy: 0)` is ambiguous. The pushed bar has Back, Close and favorite buttons, and their order is not guaranteed. On macOS there are no `navigationBars`, so the query fails there. Req 3.3 and the manual macOS check make macOS a target, and the existing `selectTab` helper already branches for it.
   Fix: name the Back button by label: `app.navigationBars.buttons["Market details"]`. This is the previous screen's title. Add a macOS-safe fallback: `app.buttons["Market details"]`, or `app.buttons["Back"]`. Alternatively state that the push/back UI test is iOS-only (`#if os(iOS)` or a skip) and that macOS is covered by the manual check.

3. NIT, `MarketLocationMapView` `@State position` "set in init": the init is not shown. Specify `init(market:onClose:) { self.market = market; self.onClose = onClose; _position = State(initialValue: SingleMarketMap.region(for: market).map(MapCameraPosition.region) ?? .automatic) }`.

4. NIT, `SingleMarketMap.Pin` isolation: the project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (verified in project.pbxproj). The design marks only the outer enum `nonisolated`. Mark `Pin` `nonisolated` explicitly as well, so its Equatable/Sendable conformances and its use from the nonisolated statics do not depend on how nested types inherit isolation.

5. NIT, Testing: `everyIconResolves` is wrapped in `#if canImport(UIKit)` (verified), so it does not run on macOS. The design says it verifies the symbol exists. Note that the check covers iOS only. The explicit `AppIcon.directions.source == .symbol(...)` assertion still runs on macOS.

6. NIT, Scope: the design ends with a "Responses to design review" section that is process history, not design content. Remove it before it is copied into `.kiro/specs/.../design.md`.

7. NIT, Req 2.2 / Acceptance 5: "same map item as before" is covered only by manual verification. The Non-Functional Requirements ask for pure logic to be unit tested "e.g. the external map item". Optional fix: state explicitly that the body is left unchanged and untested by design. The rename to `openInExternalMaps()` is the only edit.

## Verified Assumptions
- `MarketDetailView` has a single "Open in Maps" button. It is guarded by `market.coordinate != nil`, uses `ThemedButtonStyle` and identifier `open-in-maps`, and calls a private `openInMaps()` built from `MKMapItem(location:address:)`, with `name` set and `openInMaps()` called. Verified.
- `MarketDetailView` owns the `NavigationStack`, and `@Environment(\.dismiss)` is read at the sheet level, outside the stack. Passing `{ dismiss() }` down closes the sheet. Verified.
- The toolbar contents (`close-detail`, `favorite-toggle`, labels, spring animation, `sensoryFeedback`) match the design's description and can be moved verbatim. Verified.
- `MarketPin` is `private` in `MarketMapView.swift`, has a `market-pin` identifier, and is used only there. Moving it causes no name collision. Verified.
- `MarketMapView` anchors the pin at `.bottom`, as the design states. Verified.
- `Market.latitude` and `longitude` are `Double?`. `coordinate` is nil if either is nil. `parseCoordinate` rejects nil, non-numeric and zero. Verified.
- `AppIcon` is `nonisolated`. It has `source` and `accessibilityName` switches, and `openInMaps` uses `map.fill`. A new `directions` case needs edits in both switches only. `everyIconResolves` iterates `allCases`. Verified.
- The UI test helpers `waitForMarkets`, `selectTab` and `waitUntilGone`, plus the `app.maps.firstMatch` map test and the `more-info` and `close-detail` identifiers, exist. Verified.
- `Fixture.market(_:borough:address:lat:lon:)` exists, with lat/lon optional. Verified.
- The new spec folder name does not collide with existing specs (`nyc-farmer-markets`, `splash-screen-collapsible-boroughs`). Requirement 5.4 exists in `nyc-farmer-markets/requirements.md`. Verified.
- The design matches the requirements: pushed, not presented (Req 1.2/1.3); one pin (1.4); title (1.6); no coordinate gives no buttons (2.3); the assumption that the sheet's toolbar stays is respected.

## Unverified/Wrong Assumptions
- Unverified: the `.cancellationAction` toolbar item renders on a pushed screen on iOS and macOS. The design defers this to a UI assertion and a manual check. That is acceptable, but it is untested.
- Unverified: an `accessibilityIdentifier` on a SwiftUI `Map` is exposed to XCUITest, and it does not hide child pin identifiers. See finding 1.
- Unverified: the pushed Back button's accessibility label is "Market details" on the OS 26 toolbar. See finding 2.
- Unverified: the symbol `arrow.triangle.turn.up.right.diamond.fill` exists on the deployment targets (iOS 26.5, macOS 26.4). It is a long-standing symbol and `everyIconResolves` will confirm it on iOS.
- Wrong/weak: the Testing step 3 premise that `app.maps.firstMatch` identifies the pushed screen. See finding 1.
