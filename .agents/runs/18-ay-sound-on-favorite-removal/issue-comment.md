## Plan for #18: Ay sound on favorite removal

Spec: amendment "Ay on favorite removal" in `.kiro/specs/interaction-sounds/` (requirements, design, tasks) on branch `feature/18-ay-sound-on-favorite-removal`.

**Key requirements**
- Removing a favorite plays `ay.m4a` instead of the hiss, exactly one sound per removal, on three paths: swipe "Remove", the "Remove from favorites" accessibility action, and the detail toolbar toggle when it turns a favorite off.
- Adding a favorite with the toggle keeps the hiss. All other cues are unchanged.
- The VoiceOver mute rule is unchanged: Ay is silent under VoiceOver, and can play when the action comes from Switch Control or Voice Control.

**Design**
- Add `AppSound.ay` (file `ay`, not a loop) in `Theme/`.
- Add a pure `nonisolated` helper `FavoriteCue` in `Models/` (`removal` is `.ay`; `toggle(wasFavorite:)` picks Ay or hiss) so the cue choice is unit tested.
- The three call sites send the cue through `SoundController.play(_:)`. Policy, controller and player are not modified.
- Update `theme-conventions.md` and `tech.md` to list `ay`.

**Tasks**
- [ ] 1. Register `ay` in `AppSound` and add `ayIsABundledOneShot`.
- [ ] 2. Add `FavoriteCue` and `FavoriteCueTests`.
- [ ] 3. Add `.ay` gating tests to `SoundControllerTests`.
- [ ] 4. Switch the three removal paths to `FavoriteCue`.
- [ ] 5. Add UI test `testDetailToggleAddsThenRemovesFavorite`.
- [ ] 6. Update the steering files.
- [ ] 7. Final verification (iOS and macOS builds, unit and full tests).

Not verifiable by automated tests: hearing Ay on a device, silence under VoiceOver, and the view wiring (covered by code review and a manual device check).
