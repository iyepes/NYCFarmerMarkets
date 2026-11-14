# Design review: Interaction sounds (issue #14), revision 2

Reviewed: `02-design.md` (revised) against `01-requirements.md` and the source in the repo. This is a revision: the prior review (CHANGES_REQUESTED, 4 MEDIUM, 6 NIT) was re-checked first.

Verdict: **CHANGES_REQUESTED** (1 MEDIUM, 0 HIGH, 4 NIT).

## Previous findings

| # | Prior severity | Status | Note |
|---|---|---|---|
| 1 | MEDIUM | Closed | Rows, headers, Close, favorite toggle, swipe action and accessibility action hiss inside the action closure. `HissingPlainButtonStyle` is gone. Matches the source: rows and headers use `Button` with `.buttonStyle(.plain)`, and `swipeActions` and `accessibilityAction(named:)` exist in `FavoritesView`. |
| 2 | MEDIUM | Closed | One stop rule is stated (fade for `.stopped`, `.left`, scene change, `stopAllLoops()`; `stopAll()` only for disable and VoiceOver). Tab change calls `stopAllLoops()` itself. The early simulator check is the first code task. See new finding 1 for one gap in this rule. |
| 3 | MEDIUM | Closed | `startLoop` cancels the fade task, calls `setVolume(1, fadeDuration: 0)`, and `stopLoop` checks `Task.isCancelled` before `stop()`. |
| 4 | MEDIUM | Closed | `-uiTestingReset` clears `soundEnabled`; relaunch passes only the mute flag. |
| 5 to 10 | NIT | Closed | Tracked-files fact, `LaunchTests` flag, SwiftUI import in `SoundPolicy`, `isLooping` definition, `@ObservationIgnored`, interruptions and the 50 ms bound are all addressed in the text. |

## Findings

### 1. MEDIUM. `SoundPlaying` has no way to hard-stop one sound, but the design requires it (Step loops, Type shapes)

Step loops says: "Starting a loop while another is current hard-stops the other first (no fade), so at most one loop plays (R2.5)." The `SoundPlaying` protocol offers only `play`, `startLoop`, `stopLoop` (fade ~0.3 s) and `stopAll`. `stopAll()` would also cut a playing door or door-and-hit, and `stopLoop` fades. So the stated behavior cannot be written against the protocol. The unit test "a second loop stops the first" has no call a `FakeSoundPlayer` could record to assert a hard stop.

Fix: pick one and write it in the design.
- Option A (simpler): drop "hard-stop". Starting loop B while loop A is current calls `player.stopLoop(A)` (fade) then `player.startLoop(B)`, and `currentLoop = B`. A and B overlap for at most 0.3 s while A fades. State that this is accepted for R2.5 because `currentLoop` and the controller's start decisions allow one loop only.
- Option B: add `func stop(_ sound: AppSound)` to `SoundPlaying` (immediate: cancel the fade task, `stop()`, `currentTime = 0`, `setVolume(1, fadeDuration: 0)`), and have the controller call it for the previous loop. The test then asserts `stop(.humanSteps)` was recorded before `startLoop(.catSteps)`.

### 2. NIT. `SoundPolicy.activity(for:)` must handle future `ScrollPhase` cases

The design lists the five known cases. `ScrollPhase` can gain cases, so the `switch` needs `@unknown default: return nil` to compile cleanly. Fix: state it in the signature notes.

### 3. NIT. Where the toolbar goes in `MarketListView` is not stated

`MarketListView.body` is `NavigationStack { content ... .navigationTitle("Markets").searchable(...) }`, all inside `.id(dynamicTypeSize)`. The design says "`MarketListView` gets `.toolbar { ... }`". Attached outside the `NavigationStack` it does not show. Fix: say "attach `.toolbar` on `content` next to `.navigationTitle`, inside the `NavigationStack`".

### 4. NIT. The reset must run before `SoundController` is created

`NYCFarmerMarketsApp.init` runs the `-uiTestingReset` removal at the top, before the stores are built. The design adds the `soundEnabled` removal there but does not say it must come before `SoundController.init` reads the default. Fix: write "remove `soundEnabled` in the existing reset block, before creating `SoundController`". Also use one constant for the key `"soundEnabled"` (for example `SoundController.defaultsKey`) instead of repeating the literal.

### 5. NIT. `didSet` on an `@Observable` property is new to this codebase

No file under `Stores/` uses `didSet` today (verified by grep). Property observers on `@Observable` stored properties are supported, but the design relies on them for saving to UserDefaults and stopping sounds. Fix: either keep them and have the first controller test cover each side effect, or use explicit `setEnabled(_:)` and `setVoiceOverOn(_:)` methods. Pick one in the design.

## Verified Assumptions

- `RootTabView` has `TabView` with no selection and `.sheet(item: $store.selectedMarket)`; `AppRootView` parents the splash and `RootTabView` and uses a `hasDismissed` latch.
- `MarketDetailView` has `@State showsMap` and `.navigationDestination(isPresented: $showsMap)`; `MarketDetailToolbar` is used there and Close calls `dismiss`.
- `ThemedButtonStyle` is used by Retry, More info, Go to Map, Directions; it already reads `configuration.isPressed`.
- Rows and section headers use `.buttonStyle(.plain)`; `FavoritesView` has `.swipeActions` and the accessibility action; neither list view has a toolbar.
- `LaunchOptions` uses `arguments.contains(...)`; `NYCFarmerMarketsApp.init` handles `-uiTestingReset` before building stores.
- `AppIcon` is an enum with an asset/symbol source switch and an `image` property; the sound cases need entries in each switch.
- UI test launch lists exist in `NYCFarmerMarketsUITests.swift` (lines 18 and 204) and `SplashFailureUITests.swift` (line 13); the design lists all of them plus `LaunchTests`.
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` in both configurations, so `SoundPlayer` and `SoundController` are MainActor by default and the pure types need `nonisolated`.
- The five source files exist under `Sounds/` with the stated names; branch is `feature/14-interaction-sounds`.

## Unverified/Wrong Assumptions

- Unverified: `onScrollPhaseChange` fires on a `List` in a `NavigationStack`, and `onDisappear` fires on tab switches. The design covers this with its first-task check and stop-and-report rule, and tab-change stopping does not depend on it.
- Unverified: `didSet` on `@Observable` properties behaves as the design needs (finding 5).
- Unverified: the quoted file durations and the 50 ms init bound; the design gives a pass/fail rule for the second.
- Unverified: the synchronized group puts `.m4a` files into the bundle root (so `Bundle.main.url(forResource:withExtension:)` needs no subdirectory). `AppSoundTests` and acceptance criterion 1 check this, so the risk is caught in the first build.
