# Open in Maps pushes an in-app single-market map; Look for directions keeps the external Apple Maps action

"Open in Maps" in the market detail sheet now pushes an in-app map (inside the sheet's existing NavigationStack) with exactly one pin for the selected market. A new "Look for directions" button takes over the old behavior of opening the market in external Apple Maps. To support this, the Close/favorite toolbar and the map pin were extracted into shared files so the detail screen and the pushed map reuse them, and pin/region construction lives in a small `nonisolated` pure-logic type with unit tests. The change matches issue #1 and the spec in `.kiro/specs/internal-map-and-directions-button/`, and the 5.4 amendment in the original spec is recorded.

Watch for: (1) no automated or manual coverage of the "Look for directions" action or of macOS UI behavior (possible, low impact); (2) the pushed map keeps the favorite toggle although the spec assumption said the pushed screen has none (confirmed, a spec/implementation wording mismatch, not a defect).

**Verdict**: APPROVED

## High-level view

The navigation is a push, not a new presentation. `MarketDetailView` flips a `showsMap` flag bound to `navigationDestination`, so the map lives inside the sheet's stack and the back button returns to the same market. Close on the pushed screen calls the sheet's `dismiss`, closing the whole sheet rather than popping, which the UI tests pin down.

The single-market map is built from `SingleMarketMap`, which returns zero or one pin and an optional region at a fixed 0.01 degree span. The view tolerates a missing coordinate (falls back to automatic camera, no pin), though the detail screen only shows the buttons when a coordinate exists, so that path is unreachable today.

The external-maps action is a rename only (`openInMaps` to `openInExternalMaps`) with the same map item construction, now wired to the new button. It has a new `directions` icon in the AppIcon registry; no palette or icon-convention violations appear in the diff.

Test coverage is solid for logic and in-app navigation (5 unit tests, icon test, 2 UI tests), and the coder recorded a full iOS run and a macOS build as passing. The external launch and macOS UI runs were not exercised.

<details>
<summary>Issues (3)</summary>

1. **Look for directions untested** (possible) — no test or manual check that the button reaches `MKMapItem.openInMaps`; it leaves the app so UI tests skip it. Do a manual check before merge or note it in the PR.
2. **macOS UI behavior unverified** (possible) — only a macOS build was run. The Back button and the `.cancellationAction` Close placement on a pushed macOS view have not been seen; verify manually.
3. **Spec wording on favorites** (confirmed) — requirements assumption says the pushed screen has no favorites toggle of its own, while the shared toolbar shows it. Either note in the PR that the sheet toolbar is intentionally retained, or reword the assumption.

</details>

<details>
<summary>Details</summary>

## Shared toolbar and pin extraction

`MarketDetailToolbar` (a `ToolbarContent` reading `FavoritesStore` from the environment) replaces the inline toolbar in the detail view, and `MarketPin` moved out of `MarketMapView` with an `identifier` parameter defaulting to `market-pin`, so existing Map tab UI tests keep working while the pushed map uses `selected-market-pin`. The extraction is behavior-preserving, and the coder re-ran the affected UI tests after each step.

One interaction to check on device: on iOS the pushed screen shows a leading Close item (`.cancellationAction`) alongside the system back button. The UI test finds both, so they coexist, but the leading area is crowded with a long back title ("Market details"). This is a visual concern only (possible).

## Pushed map and single-pin guarantee

`MarketLocationMapView` seeds its camera in `init` from `SingleMarketMap.region`, so the map frames the market without an onAppear step. The pin's favorite ring reads `favorites.isFavorite(market)`, so toggling favorite from the pushed toolbar updates the pin live. The "exactly one annotation" requirement is enforced by `pins(for:)` and asserted by a UI test counting `selected-market-pin` elements. The annotation label and navigation title both carry the market name, covering the VoiceOver requirement.

## Test gaps

Unit tests cover pin/region output including partial coordinates. UI tests cover push, back, Close-dismisses-sheet, and button presence. Not tested: tapping Look for directions, the absence of both buttons for a market without a coordinate (requirement 2.3, unchanged conditional but unasserted), and macOS UI runs. The coder's notes also mention one transient xctrunner launch error retried by xcodebuild, and the Task 6 run's final TEST SUCCEEDED line was cut off; Task 8's full run did report success.

</details>

<details>
<summary>File map</summary>

Full diff: `git diff origin/main...HEAD`

- `Models/SingleMarketMap.swift`: pure pin/region logic
- `Theme/AppIcon.swift`: `directions` icon and label
- `Views/MarketDetailView.swift`: push button, new directions button, toolbar extracted
- `Views/MarketLocationMapView.swift`: new in-app single-market map
- `Views/MarketMapView.swift`: private pin removed
- `Views/Shared/MarketDetailToolbar.swift`: shared Close/favorite toolbar
- `Views/Shared/MarketPin.swift`: shared pin with identifier parameter
- `NYCFarmerMarketsTests/*`: icon test, SingleMarketMap tests
- `NYCFarmerMarketsUITests/*`: push/back and Close tests
- `.kiro/specs/*`: new feature spec and 5.4 amendment

</details>
