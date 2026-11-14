# Ay sound replaces the hiss on favorite removal

Removing a market from favorites now plays the owner's `ay` recording instead of the hiss on all three removal paths: the Favorites swipe "Remove", the "Remove from favorites" accessibility action, and the detail toolbar toggle when it turns a favorite off. Adding a favorite keeps the hiss. The change registers `AppSound.ay`, adds a small pure `FavoriteCue` helper that owns the cue choice, and swaps three call sites. `SoundController` and `SoundPolicy` are untouched, so the VoiceOver mute, the Sounds toggle and the UI-test mute apply to Ay unchanged.

Watch for: the view wiring (three call sites) has no automated test and relies on the manual device check (confirmed; the coder says so too). Audio, VoiceOver silence and hiss-on-add were not verified by tests (confirmed).

**Verdict**: APPROVED

## High-level view

The cue decision lives in `FavoriteCue` (`Models/`, `nonisolated`), so views never name `.ay` and the toolbar's "was it a favorite before the press" branch is unit tested. The registry change is the minimum the exhaustive switches in `AppSound` require.

Gating is unchanged by design. Ay goes through `SoundController.play(_:)`, so it is silent under VoiceOver and when Sounds is off, and goes to `SilentSoundPlayer` under `-uiTestingMuteSounds`. A new controller test pins this for `.ay`.

I checked that no removal path was missed: the only `favorites.remove`/`toggle` callers are `FavoritesView` (two) and `MarketDetailToolbar` (one). The map pins and `MarketRow` only read favorite state. No Swift source outside `Theme/` contains the `"ay"` file name.

Spec and steering are updated through a dated amendment in the existing `interaction-sounds` folder, as the owner required.

<details>
<summary>Issues (2)</summary>

1. **View wiring untested** — nothing automated asserts that the three call sites send `FavoriteCue.removal` or `toggle(wasFavorite:)` (confirmed, low). Accepted by the spec; keep the manual device check before merge, and mention it in the PR "not verified" section.
2. **UI test cannot hear audio** — `testDetailToggleAddsThenRemovesFavorite` only proves removal and label changes still work (confirmed, informational). State this in the PR body.

</details>

<details>
<summary>Details</summary>

### Cue helper and the toolbar branch

`MarketDetailToolbar` is the only path where the same button adds or removes, so it is the one place the cue can be wrong. `FavoriteCue.toggle(wasFavorite: isFavorite)` is evaluated before `favorites.toggle(market)` in the same action closure, so `isFavorite` still reflects the pre-press state (confirmed, `MarketDetailToolbar.swift` lines 31-32). `FavoriteCueTests` covers both directions. The pushed single-market map reuses this toolbar and inherits the behavior.

### Single sound per removal

Neither the swipe button nor the toolbar button uses `ThemedButtonStyle`, so no automatic hiss fires alongside Ay (the spec's code facts cover this; the diff replaces the existing `play(.hiss)` rather than adding a second call). Row tap and Close keep the hiss, matching decision (1) scope.

### Not tested

Hearing Ay on a device (swipe, toggle off, Voice Control or Switch Control accessibility action), silence under VoiceOver, hiss on toggle-on, and the call-site wiring.

</details>

<details>
<summary>File map</summary>

Full diff: `git diff origin/main...HEAD`.

- `Theme/AppSound.swift`: `ay` case, file name, non-loop.
- `Models/FavoriteCue.swift` (new): removal and toggle cue selection.
- `Views/FavoritesView.swift`: swipe and accessibility action play `FavoriteCue.removal`.
- `Views/Shared/MarketDetailToolbar.swift`: toggle uses `FavoriteCue.toggle`.
- `AppSoundTests`, `FavoriteCueTests` (new), `SoundControllerTests`: registry, cue and gating coverage.
- `NYCFarmerMarketsUITests.swift`: detail toggle add/remove test.
- `.kiro/steering/tech.md`, `theme-conventions.md`: list `ay` and the removal rule.
- `.kiro/specs/interaction-sounds/*`: dated amendment in requirements, design, tasks.

</details>
