# Code review: #18 ay-sound-on-favorite-removal

Verdict: APPROVED. No blockers.

Evidence:
- Removal paths: FavoritesView swipe Remove (line 57), accessibility action (line 68) and MarketDetailToolbar toggle (line 32, `FavoriteCue.toggle(wasFavorite: isFavorite)`) each call `sounds.play` once. `isFavorite` is read before `favorites.toggle`, so the cue matches the old state. Toggle-on still plays the hiss.
- No double sound: those buttons use no `ThemedButtonStyle` (grep of `ThemedButtonStyle(` found it only on Retry, More info and the detail buttons), so no automatic hiss is added.
- `.ay` goes through `SoundController.play`, so VoiceOver muting, the enabled flag and the UI-test mute are unchanged. `SoundControllerTests.ayFollowsTheSamePolicyAsEverySound` covers this.
- AppSound: `ay` case, file name "ay", non-looping. AppSoundTests covers it, including that the file is bundled. The existing `onlyStepSoundsLoop` test still holds.
- Conventions: no color or icon literals added. `FavoriteCue` is `nonisolated` and lives in Models/. The new tests are Swift Testing and XCTest as required. The steering files (theme-conventions.md and tech.md) list `ay`.
- Spec: the dated amendment is in the existing interaction-sounds folder (requirements, design, tasks).
- Recorded verification: iOS and macOS builds succeeded, the full test run passed, and the targeted suites passed. The commit messages state that on-device audio is unverified. The owner already confirmed device sound in an earlier round.

Non-blocking: none worth filing.
