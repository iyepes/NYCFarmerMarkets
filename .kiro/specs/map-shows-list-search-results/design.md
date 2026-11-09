# Design: Map shows the list's search results (issue #3)

## Overview

The Markets tab owns a private `@State var query` and the Map tab reads `store.markets` unfiltered. The design moves the query into the existing shared `MarketStore` (an `@Observable` already injected into every tab, which already holds UI-shared state in `selectedMarket`), adds one pure `nonisolated` type `MarketSearch` that defines "active search", "matching markets" and the indicator text, and makes both `MarketListView` and `MarketMapView` derive their markets from it. The map gets a small display-only indicator view. The map's camera `@State` is never touched, so zoom and position are preserved. No project file edits are needed (synchronized groups).

Technology stack (locked): Swift, SwiftUI, MapKit (`Map` with `Annotation`), Observation framework (`@Observable`), Swift Testing for unit tests, XCTest for UI tests. No new dependencies.

## Key decisions

**Where the query lives.** Options: (a) a `@Binding` threaded from `RootTabView`; (b) a new `@Observable SearchState` injected in the app; (c) a property on `MarketStore`. Chosen: (c) `var searchQuery = ""` on `MarketStore`, next to `selectedMarket`. It needs no new environment plumbing in `NYCFarmerMarketsApp`, and views already have the store. It is plain in-memory state (not persisted, requirement assumption). `MarketStore` is not `nonisolated` (main-actor by project default), and the property is only touched from views. `MarketListView` reads it through `@Bindable var store = store` and passes `$store.searchQuery` to `.searchable(text:)`. The existing `SectionExpansionState` logic keeps using the same string (`query` becomes a computed alias of `store.searchQuery`), so expansion behavior is unchanged.

**One shared rule.** New file `NYCFarmerMarkets/Models/MarketSearch.swift`:

```swift
nonisolated enum MarketSearch {
    /// Query with surrounding whitespace/newlines removed.
    static func normalized(_ query: String) -> String
    /// True when the normalized query is non-empty (same rule as SectionExpansionState.isSearching).
    static func isActive(_ query: String) -> Bool
    /// Markets matching the query; all markets (same order) when not active.
    static func filter(_ markets: [Market], query: String) -> [Market]
    /// Indicator text, e.g. Showing 12 results for "cafe" / Showing 1 result for "x" / Showing 0 results for "x".
    static func summary(query: String, count: Int) -> String
}
```

`filter` is implemented as `markets.filter { MarketGrouping.matches($0, query: query) }`. `MarketGrouping.matches` is left untouched (it already trims, case- and diacritic-insensitive on name, address, borough), and `MarketGrouping.sections(from:query:)` is changed to call `MarketSearch.filter` instead of its inline filter, so list and map provably share one code path and list results are unchanged. `SectionExpansionState.isSearching` stays as is but is changed to delegate to `MarketSearch.isActive` so there is a single definition of "active". `summary` uses the trimmed query, singular when `count == 1`, plural otherwise (including 0), straight double quotes.

**Map filtering.** In `MarketMapView`: `private var visibleMarkets: [Market] { MarketSearch.filter(store.markets, query: store.searchQuery) }`; `mappable` becomes `visibleMarkets.filter { $0.coordinate != nil }` (markets without coordinates stay off the map). `selectedMarket` is looked up in `visibleMarkets`, so if the selected pin is filtered out the card disappears, and an `.onChange(of: store.searchQuery)` clears `selectedID` when it no longer maps to a visible market (avoids a stale selection when the filter is later cleared and the card reappears unexpectedly). `position` is only mutated by the user's gestures; nothing in this feature writes to it, which satisfies Requirement 2. The `MarketMapView` instance persists across tab switches in `TabView`, so camera state survives; a query change while on the list tab simply re-evaluates `body` on return.

**Indicator.** New `NYCFarmerMarkets/Views/Shared/MapFilterIndicator.swift`: an `HStack` with `IconView(.searchFilter, size: 16)` and `Text(summary)`, `.font(.footnote.weight(.medium))`, `foregroundStyle(AppPalette.textPrimary.color)`, `.background(AppPalette.cardSelected.color)` (same tokens as `OfflineBanner`), `.accessibilityElement(children: .combine)`, `.accessibilityIdentifier("map-filter-indicator")`. The icon is hidden from VoiceOver by `IconView`, so VoiceOver reads only the summary text. In `MarketMapView` the existing top `.overlay` becomes a `VStack(spacing: 0)` containing the offline banner (when cached) and then the indicator (when `MarketSearch.isActive(store.searchQuery)`), so they stack and never overlap. Display-only, no clear button. A new icon case `searchFilter` is added to `AppIcon` (`.symbol("line.3.horizontal.decrease.circle.fill")`, accessibilityName "Filtered"). No new colors.

## Files

- Modify `NYCFarmerMarkets/Stores/MarketStore.swift`: add `var searchQuery = ""`.
- Add `NYCFarmerMarkets/Models/MarketSearch.swift` (above).
- Modify `NYCFarmerMarkets/Models/MarketGrouping.swift`: `sections` uses `MarketSearch.filter`.
- Modify `NYCFarmerMarkets/Models/SectionExpansion.swift`: `isSearching` delegates to `MarketSearch.isActive`.
- Modify `NYCFarmerMarkets/Views/MarketListView.swift`: remove `@State query`; use store query via `@Bindable`; the rest unchanged.
- Modify `NYCFarmerMarkets/Views/MarketMapView.swift`: filtering, selection guard, overlay stack.
- Add `NYCFarmerMarkets/Views/Shared/MapFilterIndicator.swift`.
- Modify `NYCFarmerMarkets/Theme/AppIcon.swift`: add `searchFilter` (source and accessibilityName switches are exhaustive, so both must be updated).
- Add `NYCFarmerMarketsTests/MarketSearchTests.swift`; extend UI tests in `NYCFarmerMarketsUITests/NYCFarmerMarketsUITests.swift`.
- Add `.kiro/specs/map-shows-list-search-results/{requirements,design,tasks}.md` (a later step).

## Inputs and validation

The only external input is the user-typed query (a `String`, optional in effect: empty is valid). No length limit is imposed (matching today's list). Whitespace-only is treated as inactive. There is no failure path: `filter` and `summary` are total functions with no throwing and no force-unwraps. `count` in `summary` is derived from an array length, so it is never negative; a negative value would still produce the plural form. Nothing is logged; the query is never written to logs or storage.

## Error handling

No new operation can fail. Existing load/offline behavior in `MarketStore` is unchanged. Empty results: the map renders zero annotations and the indicator with count 0; `Map` with an empty `ForEach` is valid, so no crash (Req 1.6). Markets lacking coordinates are skipped by the existing `coordinate` check (nil is the normal, non-error case).

## Invariants and ownership

- "Active search" and "matching markets" are defined only in `MarketSearch` (pure layer); views never re-implement filtering. Enforced by the unit tests and by `MarketGrouping.sections` using the same function.
- The camera is owned only by `MarketMapView.position` and changed only by user gestures; enforced by code review (no assignment in the filter path) and a UI test.
- The query is owned by `MarketStore` so it outlives either tab view.

## Edge cases

- Query typed, user switches to Map, then back to Markets: query is retained (store-owned), list unchanged.
- Query changes while a market is selected on the map: card hides if the market is filtered out; selection is cleared.
- Offline cached data plus active search: both banners show, stacked.
- Detail sheet opened from a filtered pin works as today (`store.selectedMarket`).
- Favorites tab ignores the query.
- Search changes while the markets are still loading: `filter` over an empty array returns empty; the existing spinner overlay still shows.
- macOS: `searchable` placement is unchanged; the shared store makes the same behavior apply.

## Testing

Unit (Swift Testing, `MarketSearchTests`, using the existing `Fixture` helper in `NYCFarmerMarketsTests.swift`): empty and whitespace-only queries return all markets in original order and `isActive == false`; match on name, address and borough; case- and diacritic-insensitivity; trimmed query; no results; `filter` equals the flattened `MarketGrouping.sections` markets (as a set) for a range of queries (list/map parity); `sections(from:query:)` output unchanged for pre-existing cases (existing tests keep passing); `summary` for 0, 1, many, and that it uses the trimmed query; `SectionExpansionState.isSearching` agrees with `MarketSearch.isActive`.

UI (XCTest, live data like the existing tests): search on the Markets tab, switch to Map, assert `map-filter-indicator` exists and its label contains the query; clear the search, switch to Map, assert the indicator is absent. Pin counts and camera are not reliably queryable via XCUITest, so pin filtering is covered by the unit-tested shared rule and camera preservation by design (no code writes `position`); this is a stated limitation. SwiftUI view bodies are not unit tested.
