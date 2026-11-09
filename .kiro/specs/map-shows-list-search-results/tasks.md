# Implementation Plan: Map shows the list's search results (issue #3)

Build: `xcodebuild -project /Users/isabelyepes/Documents/XCode/NYCFarmerMarkets/NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination 'platform=iOS Simulator,name=<available iPhone>' build`

Unit tests: same command with `test -only-testing:NYCFarmerMarketsTests`. Each task leaves the project buildable. New files are auto-included (synchronized groups). No colors/icons outside `NYCFarmerMarkets/Theme/`.

- [x] 1. Add the pure shared search rule `MarketSearch` (`nonisolated enum`)
  - Create `/Users/isabelyepes/Documents/XCode/NYCFarmerMarkets/NYCFarmerMarkets/Models/MarketSearch.swift` with `normalized(_:)`, `isActive(_:)`, `filter(_:query:)` (`markets.filter { MarketGrouping.matches($0, query: query) }`, original order), and `summary(query:count:)` (`Showing N results for "q"`, singular `1 result`, plural for 0, trimmed query, straight quotes).
  - Requirements: 1.2, 1.5, 3.1, 3.3, 4.1
  - Verify: build succeeds.

- [x] 2. Unit tests for `MarketSearch` (Swift Testing)
  - Create `/Users/isabelyepes/Documents/XCode/NYCFarmerMarkets/NYCFarmerMarketsTests/MarketSearchTests.swift` using `Fixture` from `NYCFarmerMarketsTests.swift` (parse via `MarketService.parse`). Cover: empty and whitespace-only return all markets in order and `isActive == false`; match on name, address, borough; case and diacritic insensitivity; trimmed query; no results; `filter` equals flattened `MarketGrouping.sections` markets (as a set) for several queries; `summary` for 0, 1, many and trimmed query; `SectionExpansionState.isSearching` agrees with `MarketSearch.isActive`.
  - Requirements: 4.1, 4.2, 1.2
  - Verify: `-only-testing:NYCFarmerMarketsTests/MarketSearchTests` passes.

- [x] 3. Route list grouping and expansion state through the shared rule
  - Modify `NYCFarmerMarkets/Models/MarketGrouping.swift`: in `sections(from:query:)` replace `markets.filter { matches($0, query: query) }` with `MarketSearch.filter(markets, query: query)`. Modify `NYCFarmerMarkets/Models/SectionExpansion.swift`: `isSearching` returns `MarketSearch.isActive(query)`.
  - Requirements: 1.2, 4.2
  - Verify: full `NYCFarmerMarketsTests` run passes, including existing `SectionExpansionTests` and grouping tests in `NYCFarmerMarketsTests.swift`, plus the parity test from task 2.

- [x] 4. Move the query into `MarketStore` and bind the list to it
  - Modify `NYCFarmerMarkets/Stores/MarketStore.swift`: add `var searchQuery = ""` next to `selectedMarket`. Modify `NYCFarmerMarkets/Views/MarketListView.swift`: remove `@State private var query`; add `private var query: String { store.searchQuery }`; in `body` use `@Bindable var store = store` and `.searchable(text: $store.searchQuery, prompt: ...)`. Leave all other uses of `query` as is.
  - Requirements: 1.3, 4.2, Assumptions (query survives tab switches)
  - Verify: build succeeds; existing UI test `testSearchFiltersList` and `testSearchAutoExpandsMatchingBoroughs` still pass.

- [x] 5. Add the `searchFilter` icon
  - Modify `NYCFarmerMarkets/Theme/AppIcon.swift`: add `case searchFilter`; in the source switch `.symbol("line.3.horizontal.decrease.circle.fill")`; in `accessibilityName` `"Filtered"` (both switches are exhaustive).
  - Requirements: 3.4
  - Verify: build succeeds.

- [ ] 6. Add `MapFilterIndicator` view
  - Create `NYCFarmerMarkets/Views/Shared/MapFilterIndicator.swift`: takes `query` and `count`; `HStack` with `IconView(.searchFilter, size: 16)` and `Text(MarketSearch.summary(query:count:))`, `.font(.footnote.weight(.medium))`, `AppPalette.textPrimary.color`, background `AppPalette.cardSelected.color` (mirror `OfflineBanner`), `.accessibilityElement(children: .combine)`, `.accessibilityIdentifier("map-filter-indicator")`. Check `OfflineBanner` for exact styling before copying.
  - Requirements: 3.1, 3.3, 3.4
  - Verify: build succeeds; no `Color(`/hex/raw symbol names in the file.

- [ ] 7. Filter the map and show the indicator
  - Modify `NYCFarmerMarkets/Views/MarketMapView.swift`: add `visibleMarkets = MarketSearch.filter(store.markets, query: store.searchQuery)`; `mappable` uses `visibleMarkets`; `selectedMarket` looks up in `visibleMarkets`; add `.onChange(of: store.searchQuery)` clearing `selectedID` if it is not in `visibleMarkets`; change the top `.overlay` to a `VStack(spacing: 0)` with `OfflineBanner` (when `store.isShowingCachedData`) then `MapFilterIndicator` (when `MarketSearch.isActive(store.searchQuery)`, count = `visibleMarkets.count`). Do not write to `position`.
  - Requirements: 1.1, 1.3-1.7, 2.1, 2.2, 3.1, 3.2
  - Verify: build succeeds; manual check noted in step output if simulator is unavailable.

- [ ] 8. UI tests for the indicator
  - Modify `NYCFarmerMarketsUITests/NYCFarmerMarketsUITests.swift` (XCTest; reuse `selectTab`, `waitForSectionHeader`, `element(_:)`, search-field pattern from `testSearchFiltersList`): (a) search on Markets, switch to Map, assert `map-filter-indicator` exists and its label contains the query; (b) clear search, switch to Map, assert indicator absent.
  - Requirements: 3.1, 3.2, 1.4
  - Verify: `-only-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITests/<new test names>` pass.

- [ ] 9. Full verification
  - Run the full unit and UI test suites; confirm existing tests (including `SingleMarketMapTests` and `testMapPinMoreInfoAndClose`) still pass.
  - Requirements: 1.5, 4.2
  - Verify: `xcodebuild ... test` exits 0.
