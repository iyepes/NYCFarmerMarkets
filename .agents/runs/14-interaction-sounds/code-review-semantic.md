# Interaction sounds: footsteps loops, hiss, doors, toggle and VoiceOver mute

Adds the owner's five recordings and a sound layer. Views send cues to an `@Observable SoundController`, which asks the pure `SoundPolicy` whether to play (toggle on, VoiceOver off, not test-muted) and then drives an `AVAudioPlayer`-based `SoundPlayer` behind a `SoundPlaying` protocol. Human steps loop while the Markets list scrolls, cat steps while Favorites scrolls, the hiss plays on button presses, door-and-hit plays when the detail sheet or single-market map opens, and a door plays on first tab appearance and tab change. A speaker toggle in the Markets toolbar persists in `UserDefaults`. The diff also carries an unrelated palette-test and splash-contrast fix, recorded as an owner decision.

Watch for: (1) the player prepares 300 ms after init and ignores cues until the load finishes, and the ~545 ms of load work runs on the main actor during launch (likely); (2) a loop that is interrupted by the system (call, Siri) leaves `currentLoop` set, so scrolling may not restart it (possible); (3) a row tap plays hiss and door-and-hit at the same moment (possible, design intent unclear); (4) an unrelated `AppPalette` change is bundled (confirmed, documented).

**Verdict**: APPROVED

## High-level view

The architecture keeps audio out of views. Views only send cues (`play`, `handle(activity, loop:)`), `SoundController` gates every cue through `SoundPolicy`, and `SoundPlayer` is the only code that touches AVFoundation. File names exist only in `Theme/AppSound.swift`, colors and icons follow the registries, and `SilentSoundPlayer` plus `-uiTestingMuteSounds` keep UI tests silent without build-time switches. This matches the spec and the project conventions.

Loop handling is driven by `onScrollPhaseChange` mapped through `SoundPolicy.activity`. Interacting and decelerating start the loop, idle stops it with a 0.3 s fade, and tracking and animating change nothing, so a resting finger or an animated section expand does not toggle audio. Loops also stop on `onDisappear`, on scene phase leaving `.active`, on tab change and when the detail sheet opens (a sheet does not fire the tab's `onDisappear`, so `RootTabView` stops it explicitly).

Startup is the weak spot. Loading five files and activating the session took 275 ms in a Debug build, so the coder deferred it by 300 ms in a Task. That keeps `init` cheap, but the deferred work still runs on the main actor, and cues in that window are dropped silently.

VoiceOver muting lives in `AppRootView` through `accessibilityVoiceOverEnabled`, which parents both the splash and the tabs. Turning VoiceOver on, or the toggle off, stops all sounds immediately. The audio category is `.ambient`, so the silent switch is respected and other apps' audio keeps playing.

Test coverage is good for logic: `SoundPolicyTests`, `SoundControllerTests` (12 cases with a fake player), `AppSoundTests`, `LaunchOptionsTests` and a UI test for toggle persistence. Audible behavior, loop seams, VoiceOver on a device, macOS and visionOS audio are explicitly unverified and listed in `known-limits.md`.

<details>
<summary>Issues (6)</summary>

1. **Main-actor load during launch (likely)** — `SoundPlayer.prepare()` loads five files and sets up the audio session on the main actor about 300 ms after init (measured ~545 ms in Debug). It can cause a hitch during the splash animation. Measure in Release on a device; if it hitches, move file reads off the main actor.
2. **Early cues dropped (possible)** — `play` returns silently when `players[sound]` is nil, so a cue in the first ~850 ms is lost. The first-appearance door fires after the splash, so it is probably safe only if the splash minimum time exceeds that window. Confirm `SplashDecision.minimumDisplayTime` and the cached-data path.
3. **Stale loop state after system interruption (possible)** — `SoundController.currentLoop` stays set if `AVAudioPlayer` is stopped by an interruption. `loopAction(isLooping: true, .scrolling)` then returns `.none` and the loop will not restart until the list reports idle. Check by simulating an interruption; if confirmed, observe `AVAudioSession.interruptionNotification` and clear the loop.
4. **Hiss and door-and-hit overlap on row tap (possible)** — Market and favorite rows call `play(.hiss)` and then set `selectedMarket`, which plays door-and-hit via `RootTabView`. The same occurs for "Go to Map" (themed button hiss plus the map push sound). Confirm by ear that the overlap is intended; if not, drop the hiss on those actions.
5. **Inconsistent hiss timing (confirmed, minor)** — `ThemedButtonStyle` hisses on press start, while plain buttons (rows, section headers, Close, favorite toggle) hiss in the action on release. Acceptable, but note it for the manual audio pass.
6. **Unrelated palette change bundled (confirmed)** — `AppPalette.onAppIconBackground` now uses `Base.deep`, with two `ThemeTests` updated (commit 9b16611). It fixes tests that failed on the base commit. Call it out in the PR body as an owner decision, separate from sounds.

</details>

<details>
<summary>Details</summary>

### Startup deferral and dropped cues in SoundPlayer

`SoundPlayer.init` starts a Task that sleeps 300 ms and then runs `prepare()`: audio session category and activation, then one `AVAudioPlayer` per `AppSound` with `prepareToPlay()`. The measurement behind this is in the commit message (init 0.5 ms, deferred prepare 545 ms in Debug on the simulator). Two consequences. First, the work is not off the main thread, because `SoundPlayer` is MainActor by default, so the 545 ms lands on the main thread while the splash animates. Second, every cue that arrives before `players` is filled is ignored with no log line. The door on first tab appearance is the cue most at risk if the splash can be dismissed within about a second (cached data plus a short minimum time). Neither is blocking; the audible check in task 10 should include a cold launch with cache.

```
init ──► Task(300 ms) ──► prepare() ──► players[...] filled
cues before this point: players[sound] == nil -> silently ignored
```

### Loop state versus the real player

`SoundController` tracks `currentLoop` as its own state, and `SoundPlayer.stopLoop` only fades if `player.isPlaying`. If the system stops the player (phone call, Siri, route change), the controller still believes the loop is active. The next `.scrolling` activity maps to `.none`, so the footsteps stay silent until the list goes idle once. The scene-phase handler covers backgrounding but not interruptions. This is an edge case on a decorative sound, so it is not blocking, but clearing the state on `AVAudioSession.interruptionNotification` is a small fix.

### Cue overlap on detail open

Tapping a row calls `play(.hiss)` and sets `store.selectedMarket`. `RootTabView` observes the nil-to-non-nil change and plays door-and-hit and stops loops. Both sounds start in the same frame on separate players. The spec says buttons hiss and the sheet plays door-and-hit, so the overlap follows the letter of it, but the owner may find it busy. The same happens when the map is pushed from the detail view (themed "Go to Map" button hisses, `showsMap` change plays door-and-hit). Closing, Back and swipe-down stay silent by design, consistent with the owner's final instruction (opening only).

### Bundled palette and test change

Commit 9b16611 changes `AppPalette.onAppIconBackground` and updates `ThemeTests`, which failed on the base commit (verified by the coder in a temporary worktree). The change is outside the interaction-sounds scope. It is recorded in `Design/design-changes.md` and the spec amendment, so the PR body should mention it.

### Test and verification posture

The coder recorded a full iOS run passing on the final tree and a macOS build. UI tests run muted, so the real `SoundPlayer` is never exercised by automation. The seam between `SoundController` and `SoundPlayer` (fades, loop restart, double `startLoop`) is covered only by manual listening. The recorded loop lengths (cat-steps 1.37 s, human-steps 6.74 s) mean seam quality depends on the owner trimming the files.

</details>

<details>
<summary>File map</summary>

Full diff: `git diff origin/main...HEAD`

- `NYCFarmerMarkets/Models/SoundPolicy.swift`: pure rules for play gating, scroll phase mapping and loop actions.
- `NYCFarmerMarkets/Models/LaunchOptions.swift`: adds `-uiTestingMuteSounds`.
- `NYCFarmerMarkets/Services/SoundPlayer.swift`: `SoundPlaying`, AVAudioPlayer-based `SoundPlayer` with fades, and `SilentSoundPlayer`.
- `NYCFarmerMarkets/Stores/SoundController.swift`: observable gate, toggle persistence, VoiceOver flag, current loop.
- `NYCFarmerMarkets/Theme/AppSound.swift`, `AppIcon.swift`, `ThemeStyling.swift`, `AppPalette.swift`: sound registry, toggle icons, hiss in `ThemedButtonStyle`, contrast fix.
- `NYCFarmerMarkets/Sounds/*.m4a`: five recordings moved and renamed to kebab-case.
- `NYCFarmerMarkets/NYCFarmerMarketsApp.swift`, `Views/AppRootView.swift`: controller creation, reset handling, VoiceOver observation.
- `Views/RootTabView.swift`: tab selection binding, door cues, door-and-hit on sheet open.
- `Views/MarketListView.swift`, `FavoritesView.swift`: loops, hiss on actions, toolbar toggle.
- `Views/MarketDetailView.swift`, `Shared/MarketDetailToolbar.swift`, `Shared/SoundToggleButton.swift`: map push sound, hiss on Close and favorite, toggle button.
- `NYCFarmerMarketsTests/*`, `NYCFarmerMarketsUITests/*`: new and updated unit and UI tests, muted launch argument.
- `.kiro/specs/interaction-sounds/*`, `.kiro/steering/*`, `Design/design-changes.md`: spec, steering and design record updates.

</details>
