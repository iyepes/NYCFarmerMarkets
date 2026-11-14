# Implementation Plan: Interaction sounds (issue #14)

Branch `feature/14-interaction-sounds`. Built from `01-requirements.md` and `02-design.md` (including its "Implementation notes", which override earlier text). Run from the repo root `<repo>`; use absolute paths. No `project.pbxproj` edit. No new dependencies. Colors only via `AppPalette`, icons only via `AppIcon`, sound file names only in `Theme/AppSound.swift`.

Commands (from `.kiro/steering/tech.md`):
- iOS build: `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/dd-fonts build`
- macOS build: `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination 'platform=macOS' -derivedDataPath /tmp/ddmac build`
- Unit tests: iOS command with `test -only-testing:NYCFarmerMarketsTests` (one suite: `-only-testing:NYCFarmerMarketsTests/<Suite>`)
- Full tests: iOS command with `test -skip-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITestsLaunchTests -skip-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITests/testLaunchPerformance` (re-run once on a transient xctrunner launch error; `-resultBundlePath` must not exist yet)

# Implementation Plan

- [ ] 1. Move and rename the sound files, add the `AppSound` registry
  - `Sounds/` files are untracked today (git status shows none tracked there; verify with `git ls-files Sounds`). Create `NYCFarmerMarkets/Sounds/`, `mv` each file (`Human steps.m4a` → `human-steps.m4a`, `Cat steps.m4a` → `cat-steps.m4a`, `Door.m4a` → `door.m4a`, `Door and hit.m4a` → `door-and-hit.m4a`, `Short hiss.m4a` → `short-hiss.m4a`; use `git mv` if tracked), then stage the new paths by name. The old empty `Sounds/` folder must be gone (`rmdir` with the literal path `<repo>/Sounds` once empty).
  - Create `NYCFarmerMarkets/Theme/AppSound.swift`: `nonisolated enum AppSound: String, CaseIterable, Sendable` with cases `humanSteps, catSteps, door, doorAndHit, hiss`, and `fileName`, `fileExtension` ("m4a"), `loops` (true for the two step sounds).
  - Create `NYCFarmerMarketsTests/AppSoundTests.swift` (Swift Testing): every case's file exists in `Bundle.main` (the test host app bundle; use `Bundle(for:)`-free lookup consistent with `AppTypographyTests`), file names unique, exactly `humanSteps` and `catSteps` loop.
  - Files: five `.m4a` under `NYCFarmerMarkets/Sounds/`, `Theme/AppSound.swift`, `NYCFarmerMarketsTests/AppSoundTests.swift`
  - Requirements: R1.1, R1.2, R1.3, AC1, AC13
  - Verify: unit tests `-only-testing:NYCFarmerMarketsTests/AppSoundTests` pass; `find /tmp/dd-fonts -name '*.m4a' -path '*NYCFarmerMarkets.app*'` lists five files; macOS build succeeds and its `.app` also contains them. Record `afinfo` durations for the PR notes.

- [ ] 2. `SoundPolicy` pure logic
  - Create `NYCFarmerMarkets/Models/SoundPolicy.swift` with `import SwiftUI` (the one `Models/` file that does; `ScrollPhase` is a plain enum). `nonisolated enum ScrollActivity { scrolling, stopped, left }`, `LoopAction: Equatable { start, stop, none }`, `SoundPolicy` with `shouldPlay(enabled:voiceOverOn:testMuted:)`, `activity(for: ScrollPhase) -> ScrollActivity?` (`.interacting`/`.decelerating` → `.scrolling`, `.idle` → `.stopped`, `.tracking`/`.animating` → `nil`, plus `@unknown default: return nil`), `loopAction(isLooping:activity:)` (start when scrolling and not looping; stop when stopped/left and looping; otherwise none).
  - Create `NYCFarmerMarketsTests/SoundPolicyTests.swift`: all 8 `shouldPlay` combinations; each `ScrollPhase` case; `loopAction` sequences start, repeat (none), stop, stop when not looping (none), left while looping (stop).
  - Files: `Models/SoundPolicy.swift`, `NYCFarmerMarketsTests/SoundPolicyTests.swift`
  - Requirements: R2.1-R2.5, R7.1, R6.3, AC13
  - Verify: `-only-testing:NYCFarmerMarketsTests/SoundPolicyTests` passes; iOS and macOS builds succeed.

- [ ] 3. `LaunchOptions.muteSounds` and test-mute plumbing in UI tests
  - `Models/LaunchOptions.swift`: add `var muteSounds = false`, set by `arguments.contains("-uiTestingMuteSounds")`, with a doc comment in the existing style. Update the `resetFavorites` doc comment to "Clears persisted favorites and the sound setting".
  - `NYCFarmerMarketsTests/LaunchOptionsTests.swift`: add tests that the argument sets `muteSounds`, absence leaves it false, and a similarly named argument does not match.
  - Add `"-uiTestingMuteSounds"` to every UI launch list: `NYCFarmerMarketsUITests.swift` line 18 (`setUp`) and line 204 (`testSplashAppearsAtLaunch`), `SplashFailureUITests.swift` line 13, and in `NYCFarmerMarketsUITestsLaunchTests.testLaunch` set `app.launchArguments = ["-uiTestingMuteSounds"]` (read the file first; it has no list today).
  - Files: `Models/LaunchOptions.swift`, `NYCFarmerMarketsTests/LaunchOptionsTests.swift`, `NYCFarmerMarketsUITests/{NYCFarmerMarketsUITests,SplashFailureUITests,NYCFarmerMarketsUITestsLaunchTests}.swift`
  - Requirements: NFR3, NFR4, AC14
  - Verify: `-only-testing:NYCFarmerMarketsTests/LaunchOptionsTests` passes; iOS build succeeds.

- [ ] 4. Player service, `SoundController` store, and app wiring
  - Create `Services/SoundPlayer.swift`: `protocol SoundPlaying: AnyObject { play(_:), startLoop(_:), stopLoop(_:), stop(_:), stopAll() }`; `SoundPlayer` (MainActor) with one preloaded `AVAudioPlayer` per `AppSound` (`prepareToPlay()`, `numberOfLoops = -1` for loops), `play` restarts (`currentTime = 0`, `setVolume(1, fadeDuration: 0)`, `play()`), `startLoop` cancels the fade task, `setVolume(1, fadeDuration: 0)`, plays if not playing, `stopLoop` fades with `setVolume(0, fadeDuration: 0.3)` and a per-sound `Task` (0.35 s, checks `Task.isCancelled`, then `stop()`, `currentTime = 0`, volume reset), `stop(_:)` hard-stops one sound (cancel fade, `stop()`, `currentTime = 0`, volume 1), `stopAll()` hard-stops all. Audio session `.ambient` + `setActive(true)` under `#if os(iOS) || os(visionOS)`. `Logger` (subsystem from bundle id, category `sound`): one `.error` per file that fails to load (file name `privacy: .public`, error `.private`) and one for the session error; no `print`, no force unwraps. Also `SilentSoundPlayer: SoundPlaying` with no-op methods.
  - Create `Stores/SoundController.swift`: `@Observable final class` with `static let defaultsKey = "soundEnabled"`, `@ObservationIgnored private let` `defaults`, `key`, `testMuted`, `player`; `private(set) var isEnabled` (loaded via `object(forKey:) as? Bool`, default true); `private(set) var voiceOverOn`; `private(set) var currentLoop: AppSound?`; `init(defaults: UserDefaults = .standard, key: String = SoundController.defaultsKey, testMuted: Bool = false, player: any SoundPlaying)` (no default player). Methods (no `didSet`): `setEnabled(_:)` (saves; `player.stopAll()` and `currentLoop = nil` when turned off), `setVoiceOverOn(_:)` (same stop when it becomes true), `play(_:)` (only if `SoundPolicy.shouldPlay`), `handle(_ activity:, loop:)` (uses `SoundPolicy.loopAction(isLooping: currentLoop == sound, ...)`; on start with a different current loop calls `player.stop(previous)` then `player.startLoop(new)` and sets `currentLoop`; `.stop` calls `player.stopLoop(sound)` and clears `currentLoop`; ignores stop for a non-current loop; blocked when policy false), `stopAllLoops()` (fade-stops `currentLoop` only, never `stopAll()`).
  - `NYCFarmerMarketsApp.swift`: in the `-uiTestingReset` block also `UserDefaults.standard.removeObject(forKey: SoundController.defaultsKey)` before creating the controller; add `@State private var soundController: SoundController`, built with `SilentSoundPlayer()` when `options.muteSounds` else `SoundPlayer()`, `testMuted: options.muteSounds`; inject `.environment(soundController)`.
  - Create `NYCFarmerMarketsTests/SoundControllerTests.swift` with a `FakeSoundPlayer` (records calls in order) and a temporary `UserDefaults(suiteName:)` removed afterwards (`removePersistentDomain`): default on; `setEnabled` saved and reloaded by a new controller; non-boolean stored value gives on; `play` forwarded only when allowed; `setEnabled(false)` and `setVoiceOverOn(true)` call `stopAll`; second loop asserts `stop(.humanSteps)` recorded before `startLoop(.catSteps)` and `currentLoop == .catSteps`; `.left`/`.stopped` stop the current loop with `stopLoop`; stop for a non-current loop ignored; `stopAllLoops()` calls `stopLoop` and never `stopAll`; test mute blocks `play` and loops; repeated `.scrolling` starts once.
  - Early check inside this task, before building views: add a temporary `Logger` line in `MarketListView`/`FavoritesView` `List` via `.onScrollPhaseChange` and `onDisappear`, run in the simulator, confirm `.interacting`, `.decelerating`, `.idle` arrive on both lists and `onDisappear` fires on tab switch, then remove the line. If `onScrollPhaseChange` does not fire on `List`, stop and report (send_message warning); do not pick the `onScrollGeometryChange` fallback silently.
  - Time `SoundPlayer.init` with `ContinuousClock` in a temporary log line, record the value (bound: under 50 ms), remove the line.
  - Files: `Services/SoundPlayer.swift`, `Stores/SoundController.swift`, `NYCFarmerMarketsApp.swift`, `NYCFarmerMarketsTests/SoundControllerTests.swift`
  - Requirements: R2.5, R6.2, R6.3, R7.1, R7.2, R8.1-R8.4, NFR2, AC11-AC14
  - Verify: `-only-testing:NYCFarmerMarketsTests/SoundControllerTests` passes; iOS and macOS builds succeed; no temporary log lines remain (`git diff` shows none).

- [ ] 5. VoiceOver wiring
  - `Views/AppRootView.swift`: read `@Environment(\.accessibilityVoiceOverEnabled)` and `@Environment(SoundController.self)`; `.onChange(of: voiceOverEnabled, initial: true) { _, on in sounds.setVoiceOverOn(on) }` on the root (parent of splash and tabs). Read the file first to place it on the outermost view.
  - Files: `Views/AppRootView.swift`
  - Requirements: R7.1-R7.3
  - Verify: iOS and macOS builds succeed; unit tests still pass. On the simulator, enable VoiceOver via Settings and confirm silence (manual pass, report result).

- [ ] 6. Sound toggle in the Markets toolbar
  - `Theme/AppIcon.swift`: add `soundOn` (`speaker.wave.2.fill`, accessibility name "Sounds on") and `soundOff` (`speaker.slash.fill`, "Sounds off") in both the `source` and `accessibilityName` switches.
  - `Views/MarketListView.swift`: attach `.toolbar { ToolbarItem(placement: .primaryAction) { SoundToggleButton() } }` next to `.navigationTitle("Markets")` inside the `NavigationStack` (and inside `.id(dynamicTypeSize)`). `SoundToggleButton` (private view in the same file, or `Views/Shared/SoundToggleButton.swift`): image `AppIcon.soundOn.image`/`soundOff.image`, `accessibilityIdentifier("sound-toggle")`, `accessibilityLabel("Sounds")`, `accessibilityValue(isEnabled ? "On" : "Off")`; action `sounds.setEnabled(!sounds.isEnabled)` then `sounds.play(.hiss)` (the policy blocks it when off).
  - `NYCFarmerMarketsUITests.swift`: add `testSoundToggleIsSaved`: tap `sound-toggle`, assert value "Off", terminate, relaunch with only `["-uiTestingMuteSounds"]`, assert value still "Off". No restore (next `setUp` resets via `-uiTestingReset`). Also assert in `setUp` or the test that the initial value is "On".
  - Files: `Theme/AppIcon.swift`, `Views/MarketListView.swift` (and optional `Views/Shared/SoundToggleButton.swift`), `NYCFarmerMarketsUITests/NYCFarmerMarketsUITests.swift`
  - Requirements: R6.1-R6.3, R3.2, R7.3, AC8, AC9, AC14
  - Verify: full tests pass including `testSoundToggleIsSaved`; the theme-conventions checks stay at zero lines; macOS build succeeds (`.primaryAction` toolbar compiles there).

- [ ] 7. Hiss on button presses
  - `Theme/ThemeStyling.swift`: `ThemedButtonStyle.makeBody` returns a private `HissOnPress` view that reads `@Environment(SoundController.self) private var sounds: SoundController?` (optional, silent in previews) and runs `.onChange(of: configuration.isPressed) { _, pressed in if pressed { sounds?.play(.hiss) } }`. Visual output unchanged.
  - Rows, section headers (`Views/MarketListView.swift` lines ~70 and ~113) and Favorites rows (`Views/FavoritesView.swift` line ~48): keep `.buttonStyle(.plain)`; call `sounds.play(.hiss)` first in each button action.
  - `Views/Shared/MarketDetailToolbar.swift`: hiss in the Close and favorite toggle actions. `Views/FavoritesView.swift`: hiss in the swipe-to-remove action and in the "Remove from favorites" accessibility action.
  - Files: `Theme/ThemeStyling.swift`, `Views/MarketListView.swift`, `Views/FavoritesView.swift`, `Views/Shared/MarketDetailToolbar.swift`
  - Requirements: R3.1, R3.3, AC5
  - Verify: iOS and macOS builds succeed; full tests pass (muted). Manual: each listed control hisses once per press on the simulator.

- [ ] 8. Door sounds for tabs and detail views
  - `Views/RootTabView.swift`: add `private enum Tab: Hashable { case markets, map, favorites }`, `@State private var selection: Tab = .markets`, `TabView(selection: $selection)`, `.tag(Tab.…)` on each tab (labels and identifiers unchanged). `.onChange(of: selection)` → `sounds.stopAllLoops()` then `sounds.play(.door)`. `.onAppear` with a `@State private var hasAppeared` latch → `sounds.play(.door)` once. `.onChange(of: store.selectedMarket?.id)` nil → non-nil → `sounds.stopAllLoops()` then `sounds.play(.doorAndHit)`.
  - `Views/MarketDetailView.swift`: `.onChange(of: showsMap)` false → true → `sounds.play(.doorAndHit)`. Back, Close and swipe-down play nothing extra.
  - Files: `Views/RootTabView.swift`, `Views/MarketDetailView.swift`
  - Requirements: R4.1-R4.3, R5.1-R5.4, R2.4, AC6, AC7
  - Verify: iOS and macOS builds succeed; full tests pass (existing `app.tabBars.buttons[...]` lookups still work). Manual: tabs appear → door; switch → door; reselect → nothing; row → hiss then door-and-hit; Go to Map → hiss then door-and-hit; Back and Close → no door.

- [ ] 9. Step loops while scrolling
  - `Views/MarketListView.swift`: on the `List`, `.onScrollPhaseChange { _, new in if let a = SoundPolicy.activity(for: new) { sounds.handle(a, loop: .humanSteps) } }`; `.onDisappear { sounds.handle(.left, loop: .humanSteps) }`; `.onChange(of: scenePhase) { _, p in if p != .active { sounds.handle(.left, loop: .humanSteps) } }`.
  - `Views/FavoritesView.swift`: the same with `.catSteps`.
  - Files: `Views/MarketListView.swift`, `Views/FavoritesView.swift`
  - Requirements: R2.1-R2.5, AC3, AC4
  - Verify: iOS and macOS builds succeed; unit and full tests pass. Manual on the simulator: steps loop while dragging and coasting, fade out after the list settles, stop on tab switch, sheet open and backgrounding, never two loops; section expand does not start a loop. Note the loop seams of `cat-steps.m4a` (1.37 s) and `human-steps.m4a` (6.74 s) for the PR (trimming is the owner's task).

- [ ] 10. Steering, spec amendment inputs, full verification
  - Update `.kiro/steering/theme-conventions.md` (an `AppSound` section, the two new icons, and a convention check that no `.m4a` or sound file name appears outside `Theme/`), `.kiro/steering/tech.md` (`SoundController` in Stores, `SoundPlayer` in Services, `Sounds/` folder, `-uiTestingMuteSounds`, `-uiTestingReset` also clears `soundEnabled`), `.kiro/steering/known-limits.md` (not verified: visionOS and macOS audio, device silent switch, VoiceOver on a device, real audio fade and loop gaps).
  - Run: iOS build, macOS build, unit tests, full UI suite, the four convention greps in `theme-conventions.md` (zero lines each) and `grep -rnE 'human-steps|cat-steps|door-and-hit|short-hiss|\.m4a' NYCFarmerMarkets --include='*.swift' | grep -v '^NYCFarmerMarkets/Theme/'` (zero lines).
  - Manual listening pass (report in the PR, mark unverified items): VoiceOver on → silent, then off → sounds resume; toggle off → silent and playing sounds stop; music in another app mixes and is not paused; `git status` shows no stray temporary files.
  - Files: `.kiro/steering/{theme-conventions,tech,known-limits}.md`
  - Requirements: AC2, AC15, AC16, NFR1
  - Verify: all commands above pass; PR notes list what was not verified (hand listening, visionOS, macOS audio, device silent switch).

## Requirement coverage

| Requirement | Tasks |
|---|---|
| R1 Bundled files | 1 |
| R2 Step loops | 2, 4, 8 (R2.4), 9 |
| R3 Hiss | 6 (R3.2), 7 |
| R4 Door and hit | 8 |
| R5 Door on tabs | 8 |
| R6 Sound toggle | 4, 6 |
| R7 VoiceOver | 2, 4, 5, 6 |
| R8 Audio behavior | 4 |
| NFR 1-4 | 3, 4, 10 |
| AC13-AC16 | 1-4, 6, 10 |

## Digest

Verified by reading (no code changed in this step):

| File | Block to change | Covering test | Notes |
|---|---|---|---|
| `NYCFarmerMarkets/Models/LaunchOptions.swift` | `struct LaunchOptions`, `init(arguments:)` (adds `muteSounds`; doc of `resetFavorites`) | `LaunchOptionsTests` (existing file, `Self.reset`/`Self.fail` constants, `@Test` style) | Existing tests pass today per the repo's last merge; confirm by running the suite first |
| `NYCFarmerMarkets/NYCFarmerMarketsApp.swift` | `init()` reset block (`UserDefaults.standard.removeObject(forKey: "favoriteMarketIDs")`), `body` `.environment(...)` chain | UI tests (muted) | Stores are `@State` built in `init`; add the controller the same way |
| `NYCFarmerMarkets/Theme/AppIcon.swift`, `ThemeStyling.swift` | exhaustive `source` and `accessibilityName` switches; `ThemedButtonStyle` | build, full UI tests | Not read in full in this step; the coder opens them to edit |
| `Views/RootTabView.swift`, `AppRootView.swift`, `MarketListView.swift`, `FavoritesView.swift`, `MarketDetailView.swift`, `Shared/MarketDetailToolbar.swift` | per tasks 5-9 | UI tests + manual pass | Line numbers (70, 113, 48) come from the design; confirm when editing |
| `NYCFarmerMarketsUITests/*.swift` | `launchArguments` at `NYCFarmerMarketsUITests.swift:18` and `:204`, `SplashFailureUITests.swift:13`; `LaunchTests.testLaunch` has none | full UI run | |
| New files | `Theme/AppSound.swift`, `Models/SoundPolicy.swift`, `Services/SoundPlayer.swift`, `Stores/SoundController.swift`, three new test files | `AppSoundTests`, `SoundPolicyTests`, `SoundControllerTests` | Synchronized groups pick them up |

Verified today: the five recordings exist at `Sounds/` with spaces and capitals in their names (`Cat steps.m4a`, `Door and hit.m4a`, `Door.m4a`, `Human steps.m4a`, `Short hiss.m4a`); `NYCFarmerMarkets/` has no `Sounds/` folder yet; `.kiro/steering/` has `git-and-workflow.md`, `known-limits.md`, `product.md`, `tech.md`, `theme-conventions.md`; the convention greps are at `theme-conventions.md` lines 49-52. Not run in this step: builds and tests (planning only).

Rules for the coder: commit locally on the branch when the owner or workflow asks, stage files by name, never stage anything under `.agents/tasks/`; `rm` only with full literal paths; remove temporary log lines and temp files.
