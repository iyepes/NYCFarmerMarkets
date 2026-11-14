# Implementation Plan: Interaction sounds

## Overview

Bundle the owner's five recordings under kebab-case names, add the `AppSound` registry, pure `SoundPolicy`, an AVFoundation `SoundPlayer` and a `SoundController` store, then wire the cues into the views: step loops while scrolling, hiss on presses, door and hit when the detail or single map opens, door on tab change, a saved sound toggle, and silence under VoiceOver. New files under `NYCFarmerMarkets/` and `NYCFarmerMarketsTests/` are picked up automatically; do not edit `project.pbxproj`. Follow `.kiro/steering/`.

Commands (from `.kiro/steering/tech.md`, run from the repo root):
- iOS build: `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/dd-fonts build`
- macOS build: `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination 'platform=macOS' -derivedDataPath /tmp/ddmac build`
- Unit tests: the iOS command with `test -only-testing:NYCFarmerMarketsTests`
- Full tests: the iOS command with `test -skip-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITestsLaunchTests -skip-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITests/testLaunchPerformance` (re-run once on a transient xctrunner launch error)

## Tasks

- [ ] 1. Bundle the sounds and add the `AppSound` registry
  - Move and rename with `git mv`: `Sounds/Human steps.m4a` → `NYCFarmerMarkets/Sounds/human-steps.m4a`, `Sounds/Cat steps.m4a` → `cat-steps.m4a`, `Sounds/Door.m4a` → `door.m4a`, `Sounds/Door and hit.m4a` → `door-and-hit.m4a`, `Sounds/Short hiss.m4a` → `short-hiss.m4a`. The files are untracked today, so `git add` them first or move them with `mv` and then `git add` the new paths; the empty `Sounds/` folder disappears.
  - Create `NYCFarmerMarkets/Theme/AppSound.swift` per the design (`fileName`, `fileExtension`, `loops`).
  - Record the durations (`afinfo`) in the PR: 6.74 s, 1.37 s, 2.90 s, 2.90 s, 1.02 s.
  - Create `NYCFarmerMarketsTests/AppSoundTests.swift`.
  - Files: the five `.m4a`, `Theme/AppSound.swift`, `AppSoundTests.swift`
  - Requirements: 1.1-1.4, 9.1
  - Verify: unit tests pass; `find /tmp/dd-fonts -name '*.m4a' -path '*NYCFarmerMarkets.app*'` lists five files.

- [ ] 2. `SoundPolicy` pure logic
  - Create `NYCFarmerMarkets/Models/SoundPolicy.swift` (`nonisolated`): `shouldPlay(enabled:voiceOverOn:testMuted:)`, `activity(for: ScrollPhase) -> ScrollActivity?`, `loopAction(isLooping:activity:)`. Decide whether the `ScrollPhase` mapping stays here (imports SwiftUI) or moves to the view layer; record the choice.
  - Create `NYCFarmerMarketsTests/SoundPolicyTests.swift`: all 8 `shouldPlay` combinations; each `ScrollPhase`; sequences start → start → stop, stop when idle, left while looping.
  - Requirements: 2.1-2.6, 7.1, 9.2, 9.3
  - Verify: unit tests pass.

- [ ] 3. Player, controller and test mute
  - Create `NYCFarmerMarkets/Services/SoundPlayer.swift`: `SoundPlaying` protocol and `SoundPlayer` (one preloaded `AVAudioPlayer` per `AppSound`; restart on repeat; `numberOfLoops = -1` for loops; ~0.3 s fade on `stopLoop`; ambient session under `#if os(iOS) || os(visionOS)`; `Logger` category `sound`; no force unwraps).
  - Create `NYCFarmerMarkets/Stores/SoundController.swift` per the design (UserDefaults key `soundEnabled`, default on; `voiceOverOn`; `testMuted`; one current loop; `stopAll` when the policy turns false).
  - `LaunchOptions`: `muteSounds` from `-uiTestingMuteSounds`. `NYCFarmerMarketsApp`: create `SoundController(testMuted: options.muteSounds)` and inject it with `.environment`.
  - Add `-uiTestingMuteSounds` to every UI test launch argument list (`NYCFarmerMarketsUITests.setUp`, `testSplashAppearsAtLaunch`, `SplashFailureUITests.setUp`).
  - Create `NYCFarmerMarketsTests/SoundControllerTests.swift` (fake player, temporary UserDefaults suite); add a `LaunchOptionsTests` case.
  - Requirements: 6.2-6.4, 7.1-7.3, 8.1-8.4, 9.4, 9.5, NFR 1, NFR 3, NFR 4
  - Verify: unit tests pass; iOS and macOS builds succeed; nothing plays yet.

- [ ] 4. Sound toggle in the Markets toolbar
  - `AppIcon`: add `soundOn` (`speaker.wave.2.fill`, "Sounds on") and `soundOff` (`speaker.slash.fill`, "Sounds off").
  - `MarketListView`: `ToolbarItem(placement: .primaryAction)` button flipping `SoundController.isEnabled`; label "Sounds", value "On"/"Off", identifier `sound-toggle`; hiss after turning on (requirement 3.2).
  - UI test `testSoundToggleIsSaved` (toggle, relaunch, value kept, restore).
  - Requirements: 6.1-6.5, 3.2, 7.4, 9.6
  - Verify: full tests pass; on the simulator the icon switches and survives a relaunch.

- [ ] 5. Hiss on button presses
  - `ThemeStyling.swift`: `ThemedButtonStyle` hisses when `isPressed` turns true, through a private `HissOnPress` view that reads the controller from the environment (optional, silent in previews). Add `HissingPlainButtonStyle` with the `.plain` look.
  - Use `HissingPlainButtonStyle` for Markets rows, Favorites rows and section headers.
  - Hiss in the actions of Close and the favorite toggle (`MarketDetailToolbar`) and swipe-to-remove plus its accessibility action (`FavoritesView`).
  - Listening check: if pressing a row at the start of a scroll hisses too often, switch rows to hiss in their action instead and note it.
  - `AppRootView` and `RootTabView`: set `voiceOverOn` from `@Environment(\.accessibilityVoiceOverEnabled)` with `onChange(initial: true)`.
  - Requirements: 3.1, 3.3, 4.3, 7.1-7.3
  - Verify: unit and full tests pass (muted); each listed button hisses once per press on the simulator.

- [ ] 6. Door sounds for tabs and opening views
  - `RootTabView`: private `Tab` enum and `@State selection`, `.tag` per tab; Door on `onChange(of: selection)`; Door once on first `onAppear` (state latch); Door_And_Hit on `onChange(of: store.selectedMarket?.id)` nil → id, and `stopAllLoops()` there.
  - `MarketDetailView`: Door_And_Hit on `onChange(of: showsMap)` false → true.
  - Closing and Back play no door sound. Tab labels and identifiers unchanged.
  - Requirements: 4.1-4.5, 5.1-5.4, 2.5
  - Verify: full tests pass; on the simulator: tabs appear → Door; switch tab → Door; reselect tab → nothing; row → Hiss then Door_And_Hit; Go to Map → Hiss then Door_And_Hit; Back → Hiss only; Close → Hiss only.

- [ ] 7. Step loops while scrolling
  - `MarketListView`: `.onScrollPhaseChange` on the `List` → `controller.handle(activity, loop: .humanSteps)`; `.left` on `onDisappear` and when `scenePhase` leaves `.active`.
  - `FavoritesView`: the same with `.catSteps`.
  - Listening check: loop seam of `cat-steps.m4a` (1.37 s) and `human-steps.m4a`; fade-out on short flicks. Report audible gaps (trimming is the owner's task).
  - Requirements: 2.1-2.6
  - Verify: unit and full tests pass; steps loop while dragging and coasting and stop after the list settles; switching tabs or opening a detail mid-scroll stops them.

- [ ] 8. Full verification, steering and PR notes
  - Run the iOS and macOS builds, the unit tests, the full UI suite, and the four convention checks from `.kiro/steering/theme-conventions.md` (zero lines each). Confirm no sound file name appears outside `Theme/`: `grep -rnE 'human-steps|cat-steps|door-and-hit|short-hiss|\.m4a' NYCFarmerMarkets --include='*.swift' | grep -v '^NYCFarmerMarkets/Theme/'`.
  - Manual listening pass (design "Testing"): VoiceOver on → silent; toggle off → silent; music playing in another app → mixes, not paused; device silent switch if a device is available.
  - Update steering: `theme-conventions.md` (an `AppSound` section and the two icons), `tech.md` (`SoundController` in Stores, `SoundPlayer` in Services, `-uiTestingMuteSounds`), `known-limits.md` (anything not verified: visionOS, macOS audio, device silent switch).
  - Tick the tasks in this file; PR text with tests run, durations, listening results and what was not verified.
  - Requirements: 9.7-9.9, NFR 2, NFR 5
  - Verify: all commands pass; PR lists what was not verified.

## Requirement coverage

| Requirement | Tasks |
|---|---|
| 1 Sound files bundled | 1 |
| 2 Step loops | 2, 6 (2.5), 7 |
| 3 Hiss | 4 (3.2), 5 |
| 4 Door and hit | 5 (4.3), 6 |
| 5 Door on tabs | 6 |
| 6 Sound toggle | 3, 4 |
| 7 VoiceOver | 2, 3, 4 (7.4), 5 |
| 8 Audio behavior | 3 |
| 9 Tests and verification | 1, 2, 3, 4, 8 |
| NFR 1-5 | 3, 8 |
