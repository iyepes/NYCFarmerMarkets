# Design: Ay sound on favorite removal (issue #18)

Branch `feature/18-ay-sound-on-favorite-removal`. Basis: `01-requirements.md` and the existing spec `.kiro/specs/interaction-sounds/`.

## Overview

The app already routes every sound through `SoundController.play(_:)`, which asks `SoundPolicy.shouldPlay` (toggle on, VoiceOver off, not test-muted) and forwards to a `SoundPlaying` player. This change adds one registry case, `AppSound.ay`, and swaps the cue sent on the three removal paths from `.hiss` to `.ay`. A small pure helper, `FavoriteCue`, owns the choice of cue so it can be unit tested. The policy, controller, player and audio session are not modified. Ay is muted under VoiceOver for free, because the gate is in `SoundController`.

Technology stack (locked): Swift (language mode 5), SwiftUI, Observation, `AVAudioPlayer` through the existing `SoundPlayer`, Swift Testing. No new dependencies.

## Facts from the code

- `Theme/AppSound.swift`: `nonisolated enum AppSound: String, CaseIterable, Sendable` with cases `humanSteps, catSteps, door, doorAndHit, hiss`. `fileName` and `loops` are exhaustive `switch`es (no `default`), so adding a case forces both to be updated at compile time.
- `Services/SoundPlayer.swift`: builds one `AVAudioPlayer` per `AppSound.allCases` entry from `fileName`/`fileExtension`. `play(_:)` does `currentTime = 0` then `play()`, so a second Ay restarts and never stacks (assumption 4). A missing file is logged and skipped by the existing `prepare()` (scheduled by the init); adding `ay` needs no player change because it iterates `allCases`.
- `Views/FavoritesView.swift`: swipe action (`Button(role: .destructive)`) and `.accessibilityAction(named: "Remove from favorites")` each call `sounds.play(.hiss)` then `favorites.remove(market)`. The row tap button also plays `.hiss` (opens detail) and must stay unchanged.
- `Views/Shared/MarketDetailToolbar.swift`: the favorite toggle calls `sounds.play(.hiss)` then `favorites.toggle(market)`. `isFavorite` is a computed property reading `favorites.isFavorite(market)`.
- Neither the swipe button nor the toolbar button uses `ThemedButtonStyle` (it is only on Retry, More info, Go to Map, Directions), so there is no second automatic hiss on these paths. Exactly one `play` call is made per removal.
- `NYCFarmerMarkets/Sounds/ay.m4a` is already in the repo; the synchronized group bundles it, so no `project.pbxproj` edit.

## Key decisions

### 1. Registry (`Theme/AppSound.swift`)
Add `case ay` after `hiss`. `fileName`: `case .ay: "ay"`. `loops`: add `.ay` to the non-looping list `case .door, .doorAndHit, .hiss, .ay: false`. Update the file's doc comment only if it lists sounds (it does not). `AppSound.ay.rawValue` is `"ay"`, which is fine because `rawValue` is not used for files.

### 2. Cue choice: pure helper, chosen over inline literals
Options: (a) write `.ay` inline at each of the three call sites; (b) extract a pure helper. Chosen: (b), because acceptance criteria 3 to 6 ask for a testable "which cue per path" and the toolbar needs a branch (favorite or not) that is easy to get backwards. A helper makes that branch unit testable without a UI.

New file `NYCFarmerMarkets/Models/FavoriteCue.swift`:

```swift
nonisolated enum FavoriteCue {
    /// Cue for removing a favorite (swipe action, accessibility action).
    static let removal: AppSound = .ay
    /// Cue for the detail toolbar toggle, from the state before the press.
    static func toggle(wasFavorite: Bool) -> AppSound { wasFavorite ? removal : .hiss }
}
```

It imports only `Foundation` (no SwiftUI), has no state and is `nonisolated` per the project rule. Views never write `.ay` themselves, which keeps R1.4 (no file name outside `Theme/`) trivially true; even the case name `.ay` appears only in `Theme/` and `Models/FavoriteCue.swift`, and no file name string is outside `Theme/`.

### 3. Call sites
- `FavoritesView` swipe action: replace `sounds.play(.hiss)` with `sounds.play(FavoriteCue.removal)`; keep `favorites.remove(market)` after it.
- `FavoritesView` `.accessibilityAction(named: "Remove from favorites")`: same replacement.
- `MarketDetailToolbar` toggle action:
  ```swift
  sounds.play(FavoriteCue.toggle(wasFavorite: isFavorite))
  favorites.toggle(market)
  ```
  `isFavorite` is read before `toggle`, so it is the state at the moment of the press (assumption 3). The order (sound then mutation) matches the existing code.
- The row tap in `FavoritesView` and `Close` keep `.hiss`.

### 4. Policy, VoiceOver, test mute
No change. `SoundController.play` guards with `canPlay`. Under VoiceOver (`voiceOverOn == true`), Ay is dropped and `setVoiceOverOn(true)` already calls `stopAll()`. When Switch Control or Voice Control triggers the accessibility action and VoiceOver is off, `canPlay` is true and Ay plays. Under `-uiTestingMuteSounds` the app builds the controller with `SilentSoundPlayer` and `testMuted`, so Ay is silent in UI tests like every sound.

### 5. Rapid removals
Each removal calls `play(.ay)`; the player restarts the clip (`currentTime = 0`). One removal triggers one call. A full-swipe removal that animates the row out does not call the action twice (the existing behavior, unchanged).

### 6. Documentation
- `.kiro/steering/theme-conventions.md` line 40: add `ay` to the case list and add one bullet: removing a favorite (swipe, "Remove from favorites" accessibility action, detail toggle off) plays `.ay` through `FavoriteCue`, not the hiss; adding keeps the hiss.
- `.kiro/steering/tech.md` line 21: add `ay` to the list of recordings (`Sounds/`). R5 names only `theme-conventions.md`; this one-word edit avoids a stale list. This edit is kept.
- `.kiro/specs/interaction-sounds/{requirements,design,tasks}.md`: the record_spec step appends a section titled `## Amendment: Ay on favorite removal (<date of the record_spec step>, issue #18)` to each file, without editing earlier text. In `design.md` it also records that the table row "Swipe-to-remove and its accessibility action | Hiss" and the toolbar row "Close, favorite toggle | Hiss" are superseded for removal only.

## Error handling

- Missing or unreadable `ay.m4a` at runtime: the existing `SoundPlayer.prepare()` logs through `Logger` and skips that sound; `play(.ay)` then returns on `players[sound] == nil`. Recoverable, silent, never shown to users. Removal still happens. No new code.
- Audio session or `AVAudioPlayer.play()` failure: handled by the existing player; unchanged.
- `favorites.remove` and `toggle` cannot fail (they mutate a set and persist to `UserDefaults`).
- No new error paths are added by this change.

## Validation of external inputs

No external inputs are added. The only data is the bundled file name, a compile-time constant owned by `Theme/AppSound.swift`.

## Invariant ownership

- One sound per removal: owned by the call sites (one `play` call per action) and the helper (one cue per path). A unit test on the helper plus the UI tests (removal still works) cover it; audio is not asserted by UI tests.
- Muted under VoiceOver, sounds off, test mute: owned by `SoundController`/`SoundPolicy` only. Views must not check these.
- Sound file names only in `Theme/`: owned by `AppSound` and enforced by the convention grep in `theme-conventions.md`.

## Testing

Unit (Swift Testing, `@testable import NYCFarmerMarkets`):
- `AppSoundTests` (extend): `ay` file is bundled (the existing `everySoundFileIsBundled` already iterates `allCases`, so it covers `ay.m4a`); `onlyStepSoundsLoop` needs no edit; it now also proves `ay` does not loop; add `@Test func ayIsABundledOneShot()` asserting `AppSound.ay.fileName == "ay"`, `fileExtension == "m4a"`, `!AppSound.ay.loops`, `AppSound.allCases.contains(.ay)`, and a bundle URL exists. `fileNamesAreUnique` covers duplicates.
- New `FavoriteCueTests.swift`: `removal == .ay`; `toggle(wasFavorite: true) == .ay`; `toggle(wasFavorite: false) == .hiss`; removal is never `.hiss`.
- `SoundControllerTests` (extend, using the existing `FakeSoundPlayer`): `play(.ay)` forwards `[.play(.ay)]` when enabled and VoiceOver off; plays nothing when `setEnabled(false)`; plays nothing when `setVoiceOverOn(true)` even with sounds enabled; plays nothing with `muted: true`; after `setVoiceOverOn(false)` it plays again.
- `SoundPolicyTests`: no change needed (the policy is cue-agnostic); the controller tests above cover AC 7 and 8 with `.ay`.

UI (XCTest, `-uiTestingMuteSounds`): existing tests must still pass. The existing suite has no test that toggles a favorite off in the detail (`testFavoriteAppearsInFavoritesTabAndSwipeRemoves` only adds with the toggle and removes by swipe), so the coder MUST add `testDetailToggleAddsThenRemovesFavorite` to `NYCFarmerMarketsUITests`: open the first market, read `app.buttons["favorite-toggle"].label` (expect `Add to favorites`), tap, expect `Remove from favorites`, tap again, expect `Add to favorites`. Existing identifiers only. It proves the removal still works; it cannot hear the cue.

Wiring coverage: `FavoriteCueTests` prove the cue per state, but views cannot be unit tested here. That the three views call `FavoriteCue` (AC 3 to 5) is verified by code review and the manual device check only. The final report must not claim automated coverage of it.

Manual (not automated, to be reported as not verified by tests): hear Ay on a device for the swipe, the toggle off, and the accessibility action via Voice Control or Switch Control; confirm silence with VoiceOver on and the hiss on toggle-on.

Builds: iOS and macOS build commands from `tech.md`, unit tests, then the full test command.

## Files

| File | Change |
|---|---|
| `NYCFarmerMarkets/Theme/AppSound.swift` | add `ay` case, file name, non-loop |
| `NYCFarmerMarkets/Models/FavoriteCue.swift` | new pure helper |
| `NYCFarmerMarkets/Views/FavoritesView.swift` | swipe and accessibility action use `FavoriteCue.removal` |
| `NYCFarmerMarkets/Views/Shared/MarketDetailToolbar.swift` | toggle uses `FavoriteCue.toggle(wasFavorite:)` |
| `NYCFarmerMarketsTests/AppSoundTests.swift` | add `ayIsABundledOneShot` |
| `NYCFarmerMarketsTests/FavoriteCueTests.swift` | new |
| `NYCFarmerMarketsTests/SoundControllerTests.swift` | add Ay gating tests |
| `NYCFarmerMarketsUITests/NYCFarmerMarketsUITests.swift` | add `testDetailToggleAddsThenRemovesFavorite` |
| `.kiro/steering/theme-conventions.md`, `.kiro/steering/tech.md` | list `ay`, state the rule |
| `.kiro/specs/interaction-sounds/{requirements,design,tasks}.md` | dated amendment (record_spec step) |

## Edge cases

- Toggle pressed on a market that is a favorite but whose stored id state changes between render and press: `isFavorite` is read at press time inside the action closure, so the cue matches the state that `toggle` then flips.
- A removal followed within 1 s by another: Ay restarts, one audible Ay at a time.
- Ay playing when VoiceOver is switched on: `setVoiceOverOn(true)` calls `stopAll()`, which stops it.
- Ay playing when the user turns Sounds off: `setEnabled(false)` calls `stopAll()`.
- Ay at the end of a favorites scroll (cat-steps loop): the loop is a separate player; both may overlap briefly, as the hiss did before. The step loop is not stopped by Ay. Accepted because the swipe action does not scroll the list.
- Last favorite removed: the list becomes the empty state; the sound still plays once.
- Detail toggle in the pushed single map (shares `MarketDetailToolbar`): same helper, same behavior.

## Assumptions to confirm

1. The date in the spec amendments is the day of the record_spec step.

## Responses to design review

1. MEDIUM, conditional UI test: addressed. The Testing section now requires `testDetailToggleAddsThenRemovesFavorite` with concrete steps. The files table below adds `NYCFarmerMarketsUITests.swift`.
2. NIT, wiring not unit tested: addressed. Testing states that AC 3 to 5 wiring is covered by review and the manual check.
3. NIT, tech.md scope: addressed. The edit is kept and the open assumption is removed.
4. NIT, placeholder date: addressed. The title uses the date of the record_spec step.
5. NIT, `prepare()`: addressed in "Facts from the code" and "Error handling".
6. NIT, garbled sentence: addressed.
