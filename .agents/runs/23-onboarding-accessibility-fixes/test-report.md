# Test report: onboarding accessibility fixes (issue #23)

Branch: `feature/23-onboarding-accessibility-fixes`. No code changed in this step.

## Commands run

All from `<repo>`.

| # | Command | Result |
|---|---------|--------|
| 1 | iOS build: `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/dd build` | `** BUILD SUCCEEDED **` |
| 2 | macOS build: same with `-destination 'platform=macOS' -derivedDataPath /tmp/ddmac` | `** BUILD SUCCEEDED **` |
| 3 | Unit tests: iOS command with `test -only-testing:NYCFarmerMarketsTests` | `** TEST SUCCEEDED **`, no failures |
| 4 | Full tests: iOS command with `test -skip-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITestsLaunchTests -skip-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITests/testLaunchPerformance` | `** TEST SUCCEEDED **` |

Full run details (command 4):
- 0 failed test cases in the log. Swift Testing parameterized cases are counted once per argument, so the raw passed-line count (346) is not the number of tests.
- 23 XCTest UI test cases passed: 14 in `NYCFarmerMarketsUITests`, 8 in `OnboardingUITests`, 1 in `SplashFailureUITests`.
- `OnboardingUITests` passed: `testNextTapsOutsideTextAdvance`, `testNextTwiceThenEnterTheMarket`, `testOnboardingScreenshotsAtDefaultAndLargestText`, `testOnboardingShowsAfterSplashWithoutTabs`, `testOnboardingShowsOnlyOnce`, `testPageIndicatorFrameIsAtLeast44Points`, `testSkipLeavesOnboarding`, `testSwipeMovesToSecondPage`.
- The log shows two transient `Simulator device failed to launch ...xctrunner` errors. xcodebuild retried internally and the run ended with `** TEST SUCCEEDED **`, so no manual re-run was needed.

## Convention grep (outside `NYCFarmerMarkets/Theme/`)

Each pattern was run as `grep -rnE '<pattern>' NYCFarmerMarkets --include='*.swift' | grep -v '^NYCFarmerMarkets/Theme/'`. All returned zero lines:

- `Color\((red|white|hue|"|[a-z]+:)`
- `(UIColor|NSColor)\(`
- `Color\.(red|blue|green|black|white|gray|orange|yellow|pink|purple|cyan|mint|teal|indigo|brown)\b`
- `0x[0-9A-Fa-f]{6}|"#[0-9A-Fa-f]{6}"`
- `systemName:|systemImage:\s*"`
- `Image\(systemName`
- `\.custom\(|\bFont\.(system|custom)\(`
- `Grim|N8ghtmare|Caligari|\.ttf`
- `\.font\(\s*(\.|Font\.)`

Violations: none.

## Not verified

- VoiceOver behavior on a device (swipe up/down on the page indicator, spoken value "Page N of M") is checked by the owner.
- No UI test in the run drives the indicator's adjust actions (increment/decrement). The log shows only `testPageIndicatorFrameIsAtLeast44Points` for the indicator, so adjust behavior is unverified by automation.
- The 44 pt target is checked by the UI test frame assertion only, not visually on device.
- The macOS and visionOS targets were not run for UI tests (macOS: build only; visionOS: not built).
- UI tests ran against the live NYC Open Data API; passing depends on network availability at run time.
