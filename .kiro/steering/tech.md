---
inclusion: always
---

# Tech stack, structure and commands

## Stack

- Swift (language mode 5), SwiftUI, Observation (`@Observable`), MapKit, CoreText, OSLog. No third-party dependencies; do not add any without asking.
- Concurrency: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and approachable concurrency. Types are MainActor by default, so pure data and logic types (models, services, theme tables, helpers) are marked `nonisolated` and usually `Sendable`.
- Xcode 26.5. The project uses file-system-synchronized groups: new files under `NYCFarmerMarkets/`, `NYCFarmerMarketsTests/` and `NYCFarmerMarketsUITests/` are picked up automatically. Do not edit `project.pbxproj` to add files.

## Layout (`NYCFarmerMarkets/`)

- `Models/`: pure value types and logic (`Market`, `MarketGrouping`, `MarketSearch`, `SectionExpansion`, `SplashDecision`, `LoadFailureMessage`, `LaunchOptions`, `SingleMarketMap`, `SectionHeaderAccessibility`). Keep logic here so it can be unit tested.
- `Services/`: `MarketService` (network + parsing), `MarketCache` (JSON file), `SoundPlayer` (`AVAudioPlayer` per sound; `SilentSoundPlayer` for muted UI tests; both behind `SoundPlaying`).
- `Stores/`: `@Observable final class` stores injected with `.environment(...)` from `NYCFarmerMarketsApp`: `MarketStore` (markets, load state, offline flag, failure, selected market, search query), `FavoritesStore` and `SoundController` (sound on/off in `UserDefaults` key `soundEnabled`, VoiceOver mute, current loop; views send cues, `SoundPolicy` decides). Dependencies are injected through initializers (`MarketStore(cache:fetch:)`, `FavoritesStore(defaults:key:)`) so tests can replace them.
- `Theme/`: the only place for colors, icons, fonts and spooky copy (see `theme-conventions.md`).
- `Views/`: screens; `Views/Shared/`: reusable views (`MarketRow`, `MarketPin`, `OfflineBanner`, `MapFilterIndicator`, `MarketDetailToolbar`).
- `fonts/`: `Grim Creeper.ttf`, `Breath of the House.ttf`, listed in `Info.plist` `UIAppFonts` and registered at runtime by `AppTypography.registerFonts()`.
- `Sounds/`: the owner's recordings (`human-steps`, `cat-steps`, `door`, `door-and-hit`, `short-hiss`, all `.m4a`), bundled automatically and named only in `Theme/AppSound.swift`.

## Error handling and logging

- Technical errors are logged with `Logger` and never shown to users; users see `LoadFailureMessage` text. Cancellation (`CancellationError`, `URLError.cancelled`) restores the previous state and is not an error.
- Log with explicit privacy (`privacy: .public` only for non-personal values). No `print`.

## Launch arguments (UI tests only)

Parsed by `LaunchOptions`; inert unless passed: `-uiTestingReset` (clear favorites and the `soundEnabled` setting), `-uiTestingFailDownload` (empty cache + failing fetch), `-uiTestingMuteSounds` (silent player, no audio session; every UI test passes it), `-uiTestingSplashMinimumSeconds <n>`. Add new test hooks here the same way, never as build-time switches.

## Tests

- Unit tests: Swift Testing (`import Testing`, `@Test`, `#expect`) in `NYCFarmerMarketsTests/`, one file per type (`<Type>Tests.swift`), `@testable import NYCFarmerMarkets`.
- UI tests: XCTest in `NYCFarmerMarketsUITests/`; they find elements by `accessibilityIdentifier` (kebab-case, e.g. `market-row`, `favorite-toggle`, `splash-retry`). Do not rename existing identifiers.
- Write tests for new pure logic in `Models/`; UI behavior gets a UI test when it is reachable by identifiers.

## Commands (run from the repo root)

- iOS build: `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/dd-fonts build`
- macOS build: `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination 'platform=macOS' -derivedDataPath /tmp/ddmac build`
- Unit tests only: the iOS command with `test -only-testing:NYCFarmerMarketsTests` (one suite: `-only-testing:NYCFarmerMarketsTests/AppTypographyTests`).
- Full tests: the iOS command with `test -skip-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITestsLaunchTests -skip-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITests/testLaunchPerformance`. If the run fails with a transient xctrunner launch error, re-run once.
- `-resultBundlePath` must point to a path that does not exist yet.
- Screenshots from UI tests: attach with `XCTAttachment`, then `xcrun xcresulttool export attachments --path <bundle> --output-path <dir>` and read `manifest.json`. Writing files to `/tmp` from UI tests does not work. `simctl` cannot tap.
- Text size on the simulator: `xcrun simctl ui booted content_size extra-extra-extra-large`.
- After any code change, build iOS (and macOS for shared code) and run the relevant tests before calling it done.
