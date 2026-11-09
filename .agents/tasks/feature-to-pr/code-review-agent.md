# Code review: feature/1-internal-map-and-directions-button

Verdict: no blockers.

Checked against issue #1, the spec in `.kiro/specs/internal-map-and-directions-button/`, and the project conventions.

- Open in Maps now sets `showsMap`. `.navigationDestination` pushes `MarketLocationMapView` inside the sheet's existing NavigationStack (`MarketDetailView.swift`). It is not a separate sheet and does not open external Maps (Req 1.2, 1.3, 1.8).
- The pushed map shows exactly one annotation, via `SingleMarketMap.pins`. It is centered with a 0.01 span and uses the market name as its title (Req 1.4 to 1.6).
- Look for directions calls `openInExternalMaps()`. This is the old `openInMaps` body, unchanged and renamed, so the external map item is built exactly as before (Req 2.2).
- Both buttons sit inside the existing `market.coordinate != nil` guard (Req 2.1, 2.3).
- Accessibility identifiers are `open-in-maps` (kept) and `look-for-directions` (new). The label text matches the titles (Req 3.1). The pin is labelled with the market name (Req 3.2).
- Conventions:
  - The new icon is registered in `AppIcon`. I found no color literals or raw SF Symbol names outside Theme in the diff.
  - `SingleMarketMap` is `nonisolated` and has Swift Testing tests. UI tests use XCTest.
  - New files are in existing folders. There are no project file edits and nothing under `.agents/` is committed.
- Refactors (`MarketPin` moved to a shared file, `MarketDetailToolbar` extracted) keep behavior. The default pin identifier is still `market-pin`, so the existing Map tab UI test is unaffected.
- Security: no secrets, network calls, logging or force-unwraps were added.
- Verification evidence from the commit messages:
  - The final commit records a full iOS test run (78 cases) as TEST SUCCEEDED. Launch performance and launch tests were excluded. There was one transient xctrunner launch error, which xcodebuild retried.
  - The macOS build succeeded.
  - New UI tests for the push, back and close paths passed.
  - Manual checks on both platforms and of Look for directions were not performed. That is acceptable because tapping the button leaves the app, and the action body is unchanged.

Non-blocking notes: none that require action.
