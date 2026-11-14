# Implementation Plan: Ay sound on favorite removal (issue #18)

Branch `feature/18-ay-sound-on-favorite-removal`. Based on `02-design.md` and `01-requirements.md`. Run git as `git -C <repo> ...`. Never stage anything under `.agents/tasks/`. Do not edit `project.pbxproj`. Build commands (run from the repo root) are in `.kiro/steering/tech.md`; below they are called "iOS build", "macOS build", "unit tests", "full tests".

- [ ] 1. Register `ay` in `AppSound` (registry only).
  - Files: `NYCFarmerMarkets/Theme/AppSound.swift`
  - Add `case ay` after `hiss`; `fileName`: `case .ay: "ay"`; `loops`: change the non-loop branch to `case .door, .doorAndHit, .hiss, .ay: false`. Both switches are exhaustive, so the compiler flags any miss. `SoundPlayer` iterates `allCases`, so no player change.
  - Requirements: R1.1, R1.2, R1.3, R4.5.
  - Verify: iOS build succeeds. Then add to `NYCFarmerMarketsTests/AppSoundTests.swift` the test `ayIsABundledOneShot` (Swift Testing): `AppSound.ay.fileName == "ay"`, `fileExtension == "m4a"`, `!AppSound.ay.loops`, `AppSound.allCases.contains(.ay)`, `Bundle.main.url(forResource: "ay", withExtension: "m4a") != nil`. Run unit tests with `-only-testing:NYCFarmerMarketsTests/AppSoundTests`: the new test plus `everySoundFileIsBundled`, `fileNamesAreUnique` and `onlyStepSoundsLoop` pass.

- [ ] 2. Add the pure cue helper and its tests.
  - Files: create `NYCFarmerMarkets/Models/FavoriteCue.swift`; create `NYCFarmerMarketsTests/FavoriteCueTests.swift`.
  - `nonisolated enum FavoriteCue` (imports Foundation only; copy the header comment style of the other `Models/` files) with `static let removal: AppSound = .ay` and `static func toggle(wasFavorite: Bool) -> AppSound { wasFavorite ? removal : .hiss }`.
  - Tests (`struct FavoriteCueTests`, `@testable import NYCFarmerMarkets`): `removal == .ay`; `removal != .hiss`; `toggle(wasFavorite: true) == .ay`; `toggle(wasFavorite: false) == .hiss`.
  - Depends on: task 1.
  - Requirements: R2.1 to R2.4, R3.1, NFR 3.
  - Verify: unit tests with `-only-testing:NYCFarmerMarketsTests/FavoriteCueTests` pass.

- [ ] 3. Add `.ay` gating tests to `SoundControllerTests`.
  - Files: `NYCFarmerMarketsTests/SoundControllerTests.swift`
  - Follow the existing pattern (`makeDefaults()`, `defer { cleanUp() }`, `FakeSoundPlayer`, `makeController`). Add one `@Test func ayFollowsTheSamePolicyAsEverySound()` (or a few small tests): enabled and VoiceOver off gives `[.play(.ay)]`; after `setEnabled(false)` a further `play(.ay)` adds no `.play`; with `setVoiceOverOn(true)` and sounds enabled `play(.ay)` adds no `.play`; with `muted: true` the calls are empty; after `setVoiceOverOn(false)` `play(.ay)` is forwarded again. Remember `setEnabled(false)` and `setVoiceOverOn(true)` append `.stopAll`, so assert on a filtered or fresh-player basis, not on `isEmpty` after those calls.
  - Depends on: task 1.
  - Requirements: R4.2, R4.3, R4.4, R4.5; AC 7, 8.
  - Verify: unit tests with `-only-testing:NYCFarmerMarketsTests/SoundControllerTests` pass.

- [ ] 4. Switch the three removal paths to the helper.
  - Files: `NYCFarmerMarkets/Views/FavoritesView.swift` (swipe action around line 56 and `.accessibilityAction(named: "Remove from favorites")` around line 67: replace `sounds.play(.hiss)` with `sounds.play(FavoriteCue.removal)`, keep `favorites.remove(market)` after it); `NYCFarmerMarkets/Views/Shared/MarketDetailToolbar.swift` (toggle around line 31: `sounds.play(FavoriteCue.toggle(wasFavorite: isFavorite))` before `favorites.toggle(market)`).
  - Leave the row-tap `.hiss` at FavoritesView line 46, the toolbar Close `.hiss` and every other `.hiss` untouched. Do not write `.ay` or `"ay"` in views.
  - Depends on: tasks 1 and 2.
  - Requirements: R2.1 to R2.5, R3.1, R3.2, R4.1.
  - Verify: iOS build and macOS build succeed. `FavoritesView.swift` and `MarketDetailToolbar.swift` have exactly one `sounds.play` call per removal action (code review of the diff; the wiring has no automated test).

- [ ] 5. Add the UI test for toggling a favorite off in the detail.
  - Files: `NYCFarmerMarketsUITests/NYCFarmerMarketsUITests.swift`
  - Add `@MainActor func testDetailToggleAddsThenRemovesFavorite() throws` after `testFavoriteAppearsInFavoritesTabAndSwipeRemoves`, reusing its helpers (`waitForMarkets()`, `firstMarketRow`, `closeButton`; the app is already launched with `-uiTestingReset` and `-uiTestingMuteSounds` by the file's setup, so check how `testFavoriteAppearsInFavoritesTabAndSwipeRemoves` starts and copy it). Open the first market, read `app.buttons["favorite-toggle"].label` (expect `Add to favorites`), tap, expect `Remove from favorites`, tap, expect `Add to favorites`. Existing identifiers only.
  - Depends on: task 4.
  - Requirements: R2.3, R2.5, R3.1 (removal and add still work; audio is not asserted).
  - Verify: full tests pass, or at least `-only-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITests/testDetailToggleAddsThenRemovesFavorite` and `.../testFavoriteAppearsInFavoritesTabAndSwipeRemoves` pass. If a transient xctrunner launch error appears, re-run once.

- [ ] 6. Update the steering files.
  - Files: `.kiro/steering/theme-conventions.md` (around line 40: add `ay` to the `AppSound` case list and one bullet: removing a favorite by swipe, the "Remove from favorites" accessibility action, or the detail toggle turning it off plays `.ay` through `FavoriteCue` instead of the hiss; adding keeps the hiss); `.kiro/steering/tech.md` (around line 21: add `ay` to the list of recordings in `Sounds/`).
  - Read each file first and match its wording and list style. Documentation only.
  - Requirements: R5.1.
  - Verify: re-read both edited lines; run the steering grep check from `theme-conventions.md` (no sound file names outside `Theme/`) and confirm it still finds nothing new.

- [ ] 7. Final verification across the change.
  - Files: none.
  - Run iOS build, macOS build, unit tests, then full tests. Confirm `git -C <repo> status --short` shows only the files listed in tasks 1 to 6 (plus `ay.m4a` if it is not yet tracked) and nothing under `.agents/tasks/`.
  - Requirements: AC 1 to 11.
  - Verify: all four commands succeed with 0 failures. Report as NOT verified by tests: hearing Ay on a device (swipe, toggle off, accessibility action through Voice Control or Switch Control), silence under VoiceOver, and the hiss on toggle-on.

- [ ] 8. Spec amendment (done by the later record_spec step, not by the coder).
  - Files: `.kiro/specs/interaction-sounds/requirements.md`, `design.md`, `tasks.md`.
  - Append `## Amendment: Ay on favorite removal (<date of that step>, issue #18)` to each; do not edit earlier text. In `design.md` state that the table rows "Swipe-to-remove and its accessibility action | Hiss" and "Close, favorite toggle | Hiss" are superseded for removal only. `tasks.md` lists tasks 1 to 7 above as done.
  - Requirements: R5.2.
  - Verify: each file ends with the amendment section and `git diff` shows only added lines in those files.

## Digest

| File | Block to change | Covered by | Verified now |
|---|---|---|---|
| `NYCFarmerMarkets/Theme/AppSound.swift` | `nonisolated enum AppSound: String, CaseIterable, Sendable` cases (humanSteps, catSteps, door, doorAndHit, hiss); `fileName` and `loops` exhaustive switches | `AppSoundTests` (`everySoundFileIsBundled`, `fileNamesAreUnique`, `onlyStepSoundsLoop`, new `ayIsABundledOneShot`) | Read via the design; test names read in `AppSoundTests.swift` |
| `NYCFarmerMarkets/Models/FavoriteCue.swift` (new) | `nonisolated enum FavoriteCue { removal; toggle(wasFavorite:) }` | new `FavoriteCueTests` | New file |
| `NYCFarmerMarkets/Views/FavoritesView.swift` | swipe `Button(role: .destructive)` (line 56) and `.accessibilityAction(named: "Remove from favorites")` (line 67): `sounds.play(.hiss)` becomes `sounds.play(FavoriteCue.removal)`; row tap at line 46 stays | `FavoriteCueTests` (cue only), UI test `testFavoriteAppearsInFavoritesTabAndSwipeRemoves` (removal still works) | Lines read by grep |
| `NYCFarmerMarkets/Views/Shared/MarketDetailToolbar.swift` | favorite toggle (line 31): `sounds.play(.hiss)` becomes `sounds.play(FavoriteCue.toggle(wasFavorite: isFavorite))`; Close at line 21 stays | `FavoriteCueTests`, new UI test `testDetailToggleAddsThenRemovesFavorite` | Lines read by grep |
| `NYCFarmerMarketsTests/AppSoundTests.swift` | add `ayIsABundledOneShot` in `struct AppSoundTests` | itself | Existing tests read |
| `NYCFarmerMarketsTests/SoundControllerTests.swift` | add Ay gating test(s) using `FakeSoundPlayer` (records `Call` values), `makeController(defaults:muted:player:)` | itself | Helpers read; `setEnabled(false)` and `setVoiceOverOn(true)` call `stopAll` per existing tests |
| `NYCFarmerMarketsUITests/NYCFarmerMarketsUITests.swift` | add `testDetailToggleAddsThenRemovesFavorite` after line ~118; uses `favorite-toggle`, `waitForMarkets()`, `firstMarketRow`, `closeButton` | itself | Existing test names and identifiers read |
| `.kiro/steering/theme-conventions.md`, `.kiro/steering/tech.md` | list `ay`, state the removal rule | grep check in theme-conventions | Not yet read by this step; the coder reads them before editing |
| `.kiro/specs/interaction-sounds/*.md` | dated amendment (task 8) | n/a | Not read |

Commands (from `tech.md`): iOS build `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/dd-fonts build`; macOS build with `-destination 'platform=macOS' -derivedDataPath /tmp/ddmac`; unit tests: the iOS command with `test -only-testing:NYCFarmerMarketsTests`; full tests: the iOS command with `test -skip-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITestsLaunchTests -skip-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITests/testLaunchPerformance`. Not run by the planner: no build or test has been executed in this step.
