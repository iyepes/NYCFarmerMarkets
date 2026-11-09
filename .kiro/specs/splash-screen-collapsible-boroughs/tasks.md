# Implementation Plan: Splash Screen and Collapsible Boroughs

## Overview

Implementation language: Swift (SwiftUI, Swift Testing, XCUITest). The plan starts with pure `nonisolated` logic types and their tests, then adds the palette token, logo asset and icon cases, then builds the splash views and wires the app root, then makes the Markets list sections collapsible, then updates and extends the UI tests, and ends with a full build and test run. New source files go in the existing `NYCFarmerMarkets` file-system-synchronized group, so `project.pbxproj` needs no change.

## Tasks

- [x] 1. Pure logic types and their tests
  - [x] 1.1 Create `Models/SplashDecision.swift`
    - Add `nonisolated enum SplashPhase` (`loading`, `failed(message:)`, `dismissed`) and `nonisolated enum SplashDecision` with `minimumDisplayTime` (1 second) and `phase(dataAvailable:minimumTimeElapsed:errorMessage:)`
    - Data wins over error; error is shown without waiting for the minimum time
    - _Requirements: 1.4, 2.1, 2.2, 2.3, 3.1, 3.4, 3.5, 3.6_

  - [x] 1.2 Create `Models/SectionExpansion.swift`
    - Add `nonisolated struct SectionExpansionState` with `userExpanded`, `searchOverrides`, `isSearching(_:)`, `isExpanded(_:query:)`, `toggle(_:query:)` and `endSearch()`
    - _Requirements: 6.1, 6.2, 6.3, 6.6, 7.1, 7.3, 7.4_

  - [x] 1.3 Create `Models/SectionHeaderAccessibility.swift`
    - Add `nonisolated enum SectionHeaderAccessibility` with `label`, `value`, `hint` and `identifier` functions
    - _Requirements: 8.2, 8.3, 8.4, 8.5_

  - [x] 1.4 Create `Models/LaunchOptions.swift`
    - Add `nonisolated struct LaunchOptions` parsing `-uiTestingReset` and `-uiTestingFailDownload` from an arguments array
    - _Requirements: 3.1, 3.2, 9.1_

  - [x]* 1.5 Write tests for `SplashDecision` in `SplashDecisionTests.swift`
    - **Property 1: Splash is dismissed exactly when data is available and the minimum time has elapsed**
    - **Property 2: Failure without data shows the error, retry hides it**
    - Add the explicit truth-table examples
    - **Validates: Requirements 1.4, 2.1, 2.2, 3.1, 3.4, 3.5, 3.6, 9.3**

  - [x]* 1.6 Write tests for `SectionExpansionState` in `SectionExpansionTests.swift`
    - **Property 3: Sections start collapsed**
    - **Property 4: Toggling twice restores the state**
    - **Property 5: Search auto-expands untouched sections**
    - **Property 7: Clearing a search restores the earlier expansion state**
    - Add examples for search-collapse then clear, and manual expand then search-collapse then clear
    - **Validates: Requirements 6.1, 6.2, 6.3, 6.6, 7.1, 7.3, 7.4, 9.4**

  - [x]* 1.7 Write tests for `SectionHeaderAccessibility` in `SectionHeaderAccessibilityTests.swift`
    - **Property 8: Section header accessibility text is consistent with its state**
    - **Property 9: Section header identifier has no spaces and encodes the borough**
    - **Validates: Requirements 8.2, 8.3, 8.4, 8.5**

  - [x]* 1.8 Extend `MarketGroupingTests` with a search property test
    - **Property 6: Search results contain exactly the matching markets**
    - **Validates: Requirements 7.2**

  - [x]* 1.9 Write unit tests for `LaunchOptions` in `LaunchOptionsTests.swift`
    - Cover each argument alone, both together and neither
    - _Requirements: 9.1_

- [x] 2. Palette token, logo asset and icon registry
  - [x] 2.1 Add `AppPalette.onAppIconBackground`
    - Define `static let onAppIconBackground = ColorToken(Base.surface)` with a doc comment
    - _Requirements: 1.2, 1.5_

  - [x] 2.2 Create the `logo-carrot` imageset
    - Add `Assets.xcassets/logo-carrot.imageset/Contents.json` and `logo-carrot.svg`, following the existing `icon-*.imageset` structure (universal SVG, preserves vector representation, template rendering)
    - Derive the SVG from `Design/AppIcon.svg`: same 1024 viewBox and stroke paths, background `<rect>` removed, single opaque stroke color
    - _Requirements: 1.2, 1.3_

  - [x] 2.3 Add `AppIcon.logo` and `AppIcon.sectionChevron`
    - `logo`: asset `logo-carrot`, accessibility name "NYC Farmer Markets"
    - `sectionChevron`: symbol `chevron.right`, accessibility name "Section"
    - _Requirements: 1.3, 1.5, 5.2, 6.4, 6.7_

  - [x]* 2.4 Extend icon and contrast tests
    - Include `logo` and `sectionChevron` in `everyIconResolves` and assert `AppIcon.logo.accessibilityName == "NYC Farmer Markets"`
    - Add `onAppIconBackground` over `appIconBackground` to the contrast checks (3:1 for the logo and indicator, 4.5:1 for message text or switch the message to a large or semibold style)
    - _Requirements: 1.2, 1.3, 5.2_

- [x] 3. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Splash views and app root wiring
  - [x] 4.1 Create `Views/SplashLoadingIndicator.swift`
    - Three `Circle` dots filled with `AppPalette.onAppIconBackground`, staggered pulse via `.easeInOut(duration: 0.6).repeatForever()` started in `.onAppear`
    - With Reduce Motion on, never start the animation and render all dots at full opacity
    - Single accessibility element with label "Loading farmers markets" and identifier `splash-loading`
    - _Requirements: 4.1, 4.2, 5.1_

  - [x] 4.2 Create `Views/SplashView.swift`
    - Logo (`IconView(.logo, size: 160)` wrapped as one accessibility element labelled "NYC Farmer Markets") on `AppPalette.appIconBackground`, content tinted with `onAppIconBackground`
    - Footer shows `SplashLoadingIndicator` for `.loading`, or the error text (`splash-error`) and a Retry button (`splash-retry`, label "Retry loading markets") for `.failed`
    - Root identifier `splash-screen`
    - _Requirements: 1.1, 1.2, 1.5, 3.1, 3.2, 3.4, 5.1, 5.2, 5.3, 5.4, 5.5_

  - [x] 4.3 Create `Views/AppRootView.swift`
    - Compute `errorMessage` (error state, or loaded with empty list), derive `phase` with `SplashDecision`, latch `hasDismissed` with `.onChange(of: phase)`
    - Run `store.load()` once and a minimum-display-time timer in separate `.task` modifiers (duration as an init parameter, default 1 s)
    - Retry calls `store.refresh()`; use `.opacity` transition and animation when Reduce Motion is off, `.identity` and no animation when it is on
    - _Requirements: 1.4, 2.1, 2.2, 2.3, 2.4, 2.5, 3.3, 3.4, 3.5, 3.6, 4.3_

  - [x] 4.4 Wire `NYCFarmerMarketsApp` and remove the `RootTabView` load task
    - Parse `LaunchOptions` from `ProcessInfo.processInfo.arguments`; keep the `favoriteMarketIDs` reset for `resetFavorites`
    - For `failDownload`, build `MarketStore` with a `MarketCache` pointing at a non-existent temporary file and a fetch that throws `URLError(.notConnectedToInternet)`
    - Render `AppRootView()` instead of `RootTabView()` with both stores in the environment
    - Remove `.task { await store.load() }` from `RootTabView`
    - _Requirements: 1.4, 2.4, 2.5, 3.1, 9.1_

  - [x]* 4.5 Extend `MarketStoreTests`
    - With a temporary cache file, cached data makes `markets` non-empty after `load()`
    - A fetch that fails then succeeds ends in `.loaded` after `refresh()`
    - _Requirements: 2.3, 3.3, 3.5_

- [x] 5. Collapsible Markets list sections
  - [x] 5.1 Update `Views/MarketListView.swift`
    - Add `@State private var expansion = SectionExpansionState()` and the Reduce Motion environment value
    - Remove the loading (`ProgressView`) and `LoadErrorView` branches; the content is now just the list and the existing empty state
    - Render rows only when the section is expanded; turn the header into a full-width `Button` toggling via `withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25))`, with borough name, count and `IconView(.sectionChevron, size: 12)` rotated 90 degrees when expanded
    - Apply `SectionHeaderAccessibility` label, value, hint, identifier and the `.isHeader` trait; keep only `AppPalette` colors and `AppIcon` icons
    - Call `expansion.endSearch()` when the search query goes from non-empty to empty
    - _Requirements: 2.5, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 7.1, 7.2, 7.3, 7.4, 8.1, 8.2, 8.3, 8.4, 8.5_

  - [x] 5.2 Delete `LoadErrorView`
    - Grep the sources and tests for `LoadErrorView` and `retry-button`; if nothing besides its definition remains, remove it from `Views/Shared/OfflineBanner.swift` and keep `offlineBanner(_:)`
    - _Requirements: 2.5_

- [x] 6. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. UI tests
  - [x] 7.1 Update existing UI tests for collapsed sections
    - Replace `waitForMarkets` with the helper that waits for the first `section-header-` element (30 s), expands it if no `market-row` exists, then waits for a row
    - Call it again after returning to the Markets tab in the favorites test
    - Change `testSearchFiltersList` to wait for a section header rather than a row
    - _Requirements: 9.1, 9.2_

  - [x]* 7.2 Add new UI tests to the existing UI test class
    - `testSplashAppearsAtLaunch`, `testSectionsStartCollapsed`, `testTappingHeaderExpandsAndCollapses`, `testSearchAutoExpandsMatchingBoroughs` (search "Manhattan", toggle by tapping, clearing returns to collapsed)
    - _Requirements: 9.1, 9.5_

  - [x]* 7.3 Create `SplashFailureUITests`
    - Launch with `-uiTestingReset` and `-uiTestingFailDownload`
    - Verify `splash-screen`, `splash-error` and `splash-retry` exist, the retry label is "Retry loading markets", the tab bar is absent, and after tapping retry the splash remains and the error returns
    - _Requirements: 3.1, 3.2, 3.3, 5.4, 5.5, 9.6_

- [x] 8. Final checkpoint - Full build, tests and static checks
  - Build the app for the iPhone 17 simulator with `xcodebuild`
  - Run the unit tests and the UI tests on the iPhone 17 simulator
  - Build the macOS destination
  - Grep for literal colors (`Color(`, `.red`, hex literals and similar) and raw SF Symbol names (`systemName:`, `Image(`) outside `Theme/` and fix any new violations
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- Each task references specific requirements for traceability
- Property tests validate the universal correctness properties in the design; if no property-testing library is available, use seeded random inputs or exhaustive enumeration inside Swift Testing `@Test(arguments:)`
- Reduce Motion and animation behavior (4.1 to 4.3, 6.5) are verified manually, since XCUITest cannot observe animation

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3", "1.4", "2.1", "2.2"] },
    { "id": 1, "tasks": ["1.5", "1.6", "1.7", "1.8", "1.9", "2.3"] },
    { "id": 2, "tasks": ["2.4", "4.1", "4.5", "5.1"] },
    { "id": 3, "tasks": ["4.2", "5.2"] },
    { "id": 4, "tasks": ["4.3"] },
    { "id": 5, "tasks": ["4.4"] },
    { "id": 6, "tasks": ["7.1", "7.3"] },
    { "id": 7, "tasks": ["7.2"] }
  ]
}
```
