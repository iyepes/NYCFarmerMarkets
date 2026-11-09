# Implementation Plan: NYC Farmer Markets

## Overview

Retroactive task list. The app was built from a nine-task plan agreed in chat, then verified. All tasks are marked complete. The notes under each task say how it was verified. Follow-up work is in `.kiro/specs/splash-screen-collapsible-boroughs/`.

## Tasks

- [x] 1. Theme and icon system
  - Define `AppPalette` (five base colors plus the icon olive, semantic light/dark tokens, WCAG contrast helpers) and `AppIcon` (registry of SF Symbols and custom assets, `IconView`)
  - Draw the ghost (filled and outline), bat and pumpkin template SVGs in the asset catalog
  - Add `ThemeStyling` (backgrounds, cards, button style, tab bar appearance)
  - Verified by: contrast and icon-resolution unit tests; the ghost, bat and pumpkin were checked in a rendered sheet
  - _Requirements: 7.1-7.6, 8.1-8.5_

- [x] 2. Model and network service
  - [x] 2.1 Create `Market` with the raw API record, coordinate parsing, borough normalization and stable ID
  - [x] 2.2 Create `MarketService` with an injectable URL and session, latest-year filtering and de-duplication
  - Verified by: unit tests with a JSON fixture and a mocked `URLProtocol`; the live API was inspected (row count, year spread, borough values, missing coordinates)
  - _Requirements: 1.1-1.8_

- [x] 3. Cache layer and MarketStore
  - [x] 3.1 Create `MarketCache` (atomic JSON file)
  - [x] 3.2 Create `MarketStore` (cache first, then network; keep data on failure; error state when empty; cancellation handling)
  - Verified by: unit tests for the cache round trip and for success, failure with cache, failure without cache, and recovery after offline
  - _Requirements: 2.1-2.8_

- [x] 4. Tabs and Markets list
  - [x] 4.1 Create `RootTabView` and wire the stores in `NYCFarmerMarketsApp`
  - [x] 4.2 Create `MarketGrouping` and `MarketListView` (sections by borough, search, refresh, offline banner, empty state)
  - [x] 4.3 Create `MarketRow` and `OfflineBanner`
  - Verified by: grouping and search unit tests; UI test for search with no result; simulator screenshots
  - _Requirements: 2.6, 2.7, 3.1-3.7_

- [x] 5. Detail sheet
  - Create `MarketDetailView` with all fields, Close, "Open in Maps" and the shared `.sheet(item:)`
  - Verified by: UI test that opens the sheet from a row and closes it; simulator screenshot
  - _Requirements: 5.1-5.4_

- [x] 6. Favorites storage and heart toggle
  - [x] 6.1 Create `FavoritesStore` (persisted IDs, resolve to markets, skip unknown IDs)
  - [x] 6.2 Add the ghost toggle to the detail sheet and indicators to rows
  - Verified by: unit tests for toggle, persistence and unknown IDs; UI test that favorites a market
  - _Requirements: 5.5, 6.1, 6.5_

- [x] 7. Favorites tab
  - Create `FavoritesView` (sorted list, tap for details, swipe to remove, empty state, accessibility action)
  - Verified by: UI test that favorites a market, sees it, opens and closes it, swipes to remove and sees the empty state
  - _Requirements: 6.2-6.7_

- [x] 8. Map tab
  - Create `MarketMapView` (pins, favorite pin style, selection card with "More info", offline banner) and make pins accessible
  - Verified by: UI test from pin to detail and back; simulator screenshot. The pins overlapped at the default zoom, so they were made smaller
  - _Requirements: 4.1-4.7_

- [x] 9. App icon, polish and verification
  - [x] 9.1 Draw `Design/AppIcon.svg`, render opaque PNGs for the iOS and macOS slots and fill in the asset catalog
  - [x] 9.2 Build for the iOS simulator and macOS; add `ENABLE_OUTGOING_NETWORK_CONNECTIONS` for the macOS sandbox
  - [x] 9.3 Search for color literals, hex values and raw symbol names outside `Theme/`
  - [x] 9.4 Run the full unit and UI test suites
  - Verified by: successful iOS and macOS builds, no asset catalog warnings, a clean literal search, and passing tests
  - Not verified: the icon on a real device or Home Screen, iPad and Mac layout in use, Dynamic Type and VoiceOver
  - _Requirements: 9.1-9.4, 10.1-10.4, 11.1-11.4_

## Notes

- The reference image for the app icon was not available as a file, so the icon is a redraw and differs slightly from the original artwork.
- The navigation bar uses the system appearance. A custom opaque appearance made the large title vanish, so only its tint comes from the palette.
- UI tests use the live API and the launch argument `-uiTestingReset`.
