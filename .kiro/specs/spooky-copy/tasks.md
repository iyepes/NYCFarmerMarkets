# Implementation Plan: Spooky Copy

## Overview

Add `AppCopy` and move the covered text into it, then update the views, then the tests. Pure strings and their unit tests come first. New files in the `NYCFarmerMarkets` folders are picked up automatically.

## Tasks

- [ ] 1. Central copy type
  - [ ] 1.1 Create `Theme/AppCopy.swift`
    - Add `nonisolated enum AppCopy` with the strings and pure functions listed in the design (`mapFilterSummary`, `mapFilterAccessibility`, `noResultsHint`)
    - Trim the query the same way as `MarketSearch.normalized`
    - _Requirements: 1.1-1.4, 3.1, 3.2, 4.1-4.3, 5.1-5.5, 6.1, 6.2_
  - [ ]* 1.2 Create `AppCopyTests.swift`
    - Singular, plural and zero forms; trimming; accessibility forms
    - No technical error text; plain accessibility strings contain no spooky vocabulary
    - _Requirements: 7.4, 7.5, 8.1, 8.2_

- [ ] 2. Wire the views
  - [ ] 2.1 Splash: add the visible caption "Summoning markets…" inside `SplashLoadingIndicator`, keeping one accessibility element, the plain label and the `splash-loading` identifier
    - _Requirements: 2.1-2.4_
  - [ ] 2.2 Offline banner: use `AppCopy.offlineBanner` with the plain accessibility label; keep `offline-banner`
    - _Requirements: 3.1-3.3_
  - [ ] 2.3 Markets tab: search prompt, no-results title and hint, with the plain label for the title
    - _Requirements: 4.1-4.3_
  - [ ] 2.4 Map filter indicator: use `AppCopy.mapFilterSummary` and the plain accessibility label; remove `MarketSearch.summary` and update its callers; keep `map-filter-indicator`
    - _Requirements: 5.1-5.6_
  - [ ] 2.5 Detail view: show `AppCopy.missingValue` for blank fields with the plain accessibility value "Not listed"
    - _Requirements: 6.1, 6.2_
  - [ ] 2.6 Check no view covered by this spec still has a string literal for the replaced text
    - _Requirements: 1.3, 7.1-7.3_

- [ ] 3. Update existing tests
  - [ ] 3.1 Remove the old `summary` expectations from `MarketSearchTests`
    - _Requirements: 8.3_
  - [ ] 3.2 Update `testSearchFiltersList` to wait for the element with identifier `search-no-results-title` and assert its label is "No markets found"; make sure other UI tests that read the indicator or banner still pass
    - _Requirements: 8.3, 8.4_

- [ ] 4. Verification
  - Build for the iOS simulator and macOS
  - Run the full unit and UI test suites
  - Search for color literals, hex values and raw symbol names outside `Theme/`
  - Check the splash, banner, search empty state, map indicator and a blank detail field in the simulator, including a large Dynamic Type size, and note anything not verified
  - _Requirements: 8.5_

## Notes

- Tasks marked `*` are optional, but Requirement 8 asks for them.
- To run this through the feature workflow, use the one-line description: "Give visible text a light spooky tone through a central AppCopy type (see .kiro/specs/spooky-copy)".
