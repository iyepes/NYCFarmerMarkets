## Summary

Plays the owner's `ay` sound (`NYCFarmerMarkets/Sounds/ay.m4a`) when a market is removed from favorites.

- `ay` is registered in `AppSound` (Theme/) and played through `SoundController` like the other cues, via a new `FavoriteCue` helper.
- Ay replaces the hiss on every removal path, so exactly one sound plays per removal: the swipe Remove action and the "Remove from favorites" accessibility action in `FavoritesView`, and the favorite toggle in `MarketDetailToolbar` when it turns a favorite off.
- Adding a favorite with the toggle keeps the hiss.
- The rule that all sounds are muted while VoiceOver runs is unchanged. Ay is silent under VoiceOver and can still play when the accessibility action is triggered by Switch Control or Voice Control.
- Tests: `AppSoundTests` (bundled, not a loop), `SoundController` gating, and a UI test for the detail favorite toggle (add and remove).
- Docs: `.kiro/steering/theme-conventions.md` updated, and a dated "Amendment: Ay on favorite removal" added to requirements, design and tasks in `.kiro/specs/interaction-sounds/`.

## Tested

Run from the repo root.

| # | Command | Result |
|---|---|---|
| 1 | iOS build (`-destination 'platform=iOS Simulator,name=iPhone 17'`) | BUILD SUCCEEDED |
| 2 | macOS build (`-destination 'platform=macOS'`) | BUILD SUCCEEDED |
| 3 | Unit tests (iOS `test -only-testing:NYCFarmerMarketsTests`) | TEST SUCCEEDED, 0 failures |
| 4 | Full iOS `test`, skipping `NYCFarmerMarketsUITestsLaunchTests` and `testLaunchPerformance` | TEST SUCCEEDED. 129 total, 129 passed, 0 failed, 0 skipped (114 unit, 15 UI) |

Convention greps for colors, symbols and fonts outside `Theme/` found no matches.

## Anything not verified

- Audio output was not checked in this run. Tests use the muted or silent sound player, so Ay was not heard on a device here.
- VoiceOver mute behavior and Switch Control / Voice Control playback were not exercised.
- visionOS was not built.
- `NYCFarmerMarketsUITestsLaunchTests` and `testLaunchPerformance` were excluded by instruction.

## Agent run traces

The commit `chore(agents): archive run traces for #18` adds this run's traces under `.agents/runs/18-ay-sound-on-favorite-removal/` (14 files, commit 34e1416). Reviewers can collapse that folder: the real change is in the other commits.

Closes #18
