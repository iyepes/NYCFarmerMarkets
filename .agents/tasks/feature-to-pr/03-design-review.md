# Design review: Ay sound on favorite removal (issue #18)

Reviewed: `02-design.md` against `01-requirements.md` and the source. The design carries a "Responses to design review" section, so this is treated as a revised design. No prior review file was named, so each item is checked against the code.

Verdict: **APPROVED** (0 HIGH, 0 MEDIUM, 3 NIT).

## Findings

1. NIT. "Responses to design review" is embedded in `02-design.md` and says "The files table below adds `NYCFarmerMarketsUITests.swift`", but the table is above that section.
   Fix: change "below" to "above", or drop the section when the spec is recorded.

2. NIT. `FavoriteCueTests` lists "removal is never `.hiss`". It repeats `removal == .ay` and adds no coverage.
   Fix: drop that assertion.

3. NIT. `theme-conventions.md` line 42 says plain-style buttons call `sounds.play(.hiss)`. The design updates line 40 but not this line.
   Fix: add "except favorite removal, which sends `FavoriteCue.removal`" to the line 42 text, or make sure the new bullet states the exception.

## Verified Assumptions

- `AppSound` is `nonisolated enum ... CaseIterable, Sendable`. `fileName` and `loops` are exhaustive switches with no `default`, so adding `ay` forces both to be updated at compile time.
- `SoundPlayer` builds its players by iterating `AppSound.allCases` (lines 53, 104). `play` does `currentTime = 0` and then `play()` (lines 74 and 115). A missing sound is skipped, because `players[sound]` is nil and `play` returns. `prepare()` is scheduled from init (line 38).
- `FavoritesView` has `sounds.play(.hiss)` then `favorites.remove(market)` in the swipe button and in `.accessibilityAction(named: "Remove from favorites")`. The row tap plays `.hiss` and stays unchanged.
- `MarketDetailToolbar` plays `.hiss` then `favorites.toggle(market)`. `isFavorite` is a computed property, so it is read at press time. Close plays `.hiss`.
- `ThemedButtonStyle` is used only in `MarketDetailView` (Go to Map, Directions), `MarketMapView` and `SplashView`. Neither removal path uses it, so there is no second hiss.
- `SoundController.play` is guarded by `canPlay` (`SoundPolicy.shouldPlay` with enabled, voiceOverOn and testMuted). `setEnabled(false)` and `setVoiceOverOn(true)` call `silenceEverything`, which calls `player.stopAll()`.
- `Sounds/ay.m4a` exists next to the other recordings.
- The existing UI test (lines 90-117) adds a favorite with the toggle and removes it by swipe only. The design is right that no test covers toggling off in the detail.
- `AppSoundTests` and `SoundControllerTests` have the structure the design extends. `FakeSoundPlayer` and `makeController(muted:)` exist.
- The convention grep in `theme-conventions.md` (line 59) matches `\.m4a`, so it also catches `ay.m4a` outside `Theme/`.
- `.kiro/steering/tech.md` line 21 lists the recordings. `theme-conventions.md` line 40 lists the cases.

## Unverified/Wrong Assumptions

- Audio playback of Ay, the Switch Control or Voice Control path, and silence under VoiceOver are not checkable from source. The design correctly marks them manual and not covered by tests.
- The view wiring (AC 3 to 5) has no automated test. The design states this and routes it to code review and the manual check.
- The claim that the swipe action does not trigger a scroll-phase cat-steps loop was not verified. The design lists it as an accepted edge case and the impact is negligible.
- No wrong assumptions were found.
