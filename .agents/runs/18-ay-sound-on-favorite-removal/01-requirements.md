# Requirements: Ay sound on favorite removal (issue #18)

Branch: `feature/18-ay-sound-on-favorite-removal`. Issue: https://github.com/iyepes/NYCFarmerMarkets/issues/18. Basis: the existing spec `.kiro/specs/interaction-sounds/`, which the record_spec step amends with a dated "Amendment: Ay on favorite removal" in requirements.md, design.md and tasks.md (no new spec folder).

## Summary

When a market is removed from favorites, Spooky Markets plays the owner's "Ay" recording (`NYCFarmerMarkets/Sounds/ay.m4a`, 1.0 s, stereo AAC, owner-recorded, OK to publish) instead of the button hiss. Exactly one sound plays per removal, on all three removal paths. Adding a favorite keeps the hiss. The rule that every sound is muted while VoiceOver runs is unchanged. No other behavior changes.

## Assumptions

1. Current code: each of the three removal paths plays `.hiss` before calling `favorites.remove(market)` or `favorites.toggle(market)`. The change replaces that cue on removal and leaves everything else.
2. "Removal" means a market that is a favorite becomes a non-favorite through a user action. Programmatic or stored-id cleanup does not exist and is not in scope.
3. In the detail toolbar the toggle plays Ay when the market is a favorite at the moment of the press, and hiss when it is not.
4. Ay is a one-shot sound, like the hiss. A new Ay while one is playing restarts it and does not stack (same rule as R3.3 of the base spec).
5. Ay obeys the existing `SoundPolicy` gates: sounds toggle off, VoiceOver running. It is silent under VoiceOver. It can play when the "Remove from favorites" accessibility action is triggered through Switch Control or Voice Control, because VoiceOver is not running then.
6. Removing several favorites quickly plays Ay once per removal (restarting), which is the existing one-shot behavior.

## Functional Requirements

### R1. Ay registered as a bundled sound
1. `AppSound` has an `ay` case whose `fileName` is `ay` and `fileExtension` is `m4a`.
2. `ay` does not loop (`loops` is false).
3. `ay.m4a` is in the built iOS and macOS bundles with no `project.pbxproj` edit.
4. No code outside `Theme/` contains the file name `ay`.

### R2. Ay replaces the hiss on removal
1. Swiping "Remove" on a Favorites row plays Ay once and does not play the hiss.
2. Running the "Remove from favorites" accessibility action on a Favorites row plays Ay once and does not play the hiss.
3. Pressing the favorite toggle in the detail toolbar when the market is a favorite plays Ay once and does not play the hiss.
4. Exactly one sound plays per removal on each path.
5. The market is still removed from favorites on each path, as before.

### R3. Hiss stays elsewhere
1. Pressing the favorite toggle when the market is not a favorite (adding) plays the hiss, not Ay.
2. All other hiss cues (rows, Close, section headers, sound toggle, themed buttons) are unchanged.

### R4. Sound architecture and muting
1. Views send the cue through `SoundController.play(_:)`; views do not touch audio.
2. With the Sounds toggle off, Ay does not play.
3. While VoiceOver runs, Ay does not play, whatever the toggle says. The VoiceOver mute rule (R7 of the base spec) is unchanged.
4. When VoiceOver is off and the toggle is on, Ay plays, including when the accessibility action is triggered by Switch Control or Voice Control.
5. Under `-uiTestingMuteSounds`, Ay goes through `SilentSoundPlayer` like every other sound.

### R5. Documentation
1. `.kiro/steering/theme-conventions.md` lists `ay` among the `AppSound` cases and states that removing a favorite plays Ay instead of the hiss.
2. `.kiro/specs/interaction-sounds/requirements.md`, `design.md` and `tasks.md` each get a dated "Amendment: Ay on favorite removal" section; earlier text is not rewritten.

## Non-Functional Requirements

1. Only Apple frameworks; no new dependencies.
2. No new colors or icons are needed. No new accessibility identifiers; existing ones (`favorite-row`, `favorite-toggle`, `favorites-list`) are not renamed.
3. Pure logic added to `Models/` (if any) is `nonisolated` and unit tested with Swift Testing.

## Acceptance Criteria

1. `AppSound.ay.fileName == "ay"`, `fileExtension == "m4a"`, `loops == false`.
2. `AppSound.allCases` includes `ay`, and `AppSoundTests` verifies that `ay.m4a` is in the app bundle and that `ay` is not a loop.
3. Swipe "Remove" on a favorite plays only Ay (one play call, `.ay`, no `.hiss`) and removes the market.
4. The "Remove from favorites" accessibility action plays only Ay and removes the market.
5. The detail favorite toggle on a favorite plays only Ay and removes the market.
6. The detail favorite toggle on a non-favorite plays only the hiss and adds the market.
7. With sounds off, or with VoiceOver running, a removal plays no sound (policy test with `.ay`).
8. With VoiceOver off and sounds on, `.ay` is allowed to play.
9. Grep for `ay.m4a` or `"ay"` outside `NYCFarmerMarkets/Theme/` finds nothing in Swift sources (the steering grep check still passes).
10. `theme-conventions.md` and the three `interaction-sounds` spec files carry the amendment text described in R5.
11. iOS and macOS builds succeed and the unit tests pass. Existing UI tests still pass (they run with `-uiTestingMuteSounds`).

## Verification notes

- Unit-testable: `AppSound` registry, `SoundController`/`SoundPolicy` behavior with a recording fake `SoundPlaying`, which cue each removal path sends if the cue choice is extracted to a pure helper (design decision).
- UI tests can confirm removal still works via `favorite-row` swipe and `favorite-toggle`; they cannot hear audio. Actual audio and the Switch Control or Voice Control case are manual checks on a device and are not verified by automated tests.

## Out of Scope

1. Changing the VoiceOver muting rule or adding a VoiceOver-specific sound.
2. Changing the hiss on adding a favorite or any other cue.
3. Re-recording, trimming or editing `ay.m4a`.
4. New settings, per-sound toggles or volume controls.
5. Haptic changes (`.sensoryFeedback(.selection)` stays).
6. Sound on removal paths that do not exist today (undo, bulk removal).
