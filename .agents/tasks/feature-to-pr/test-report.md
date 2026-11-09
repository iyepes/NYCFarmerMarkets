# Test report: feature/1-internal-map-and-directions-button

All commands were run from /Users/isabelyepes/Documents/XCode/NYCFarmerMarkets (project NYCFarmerMarkets.xcodeproj, scheme NYCFarmerMarkets). No code was changed in this step.

| # | Command | Result |
|---|---------|--------|
| 1 | `xcodebuild ... -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/dd build` | BUILD SUCCEEDED (exit 0) |
| 2 | `xcodebuild ... -destination 'platform=macOS' -derivedDataPath /tmp/ddmac build` | BUILD SUCCEEDED (exit 0) |
| 3 | iOS `test -only-testing:NYCFarmerMarketsTests` | TEST SUCCEEDED (exit 0): 68 passed, 0 failed |
| 4 | iOS `test -skip-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITestsLaunchTests -skip-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITests/testLaunchPerformance` | TEST SUCCEEDED (exit 0): 79 test cases passed, 0 failed (68 unit + 11 UI). No xctrunner launch error occurred, so no re-run was needed. |

UI tests that passed (live NYC Open Data API): testRetryAndErrorShownWhenDownloadFailsWithoutCache, testCloseFromPushedMapDismissesSheet, testFavoriteAppearsInFavoritesTabAndSwipeRemoves, testMapPinMoreInfoAndClose, testOpenDetailFromListAndClose, testOpenInMapsPushesSingleMarketMap (covers the new feature), testSearchAutoExpandsMatchingBoroughs, testSearchFiltersList, testSectionsStartCollapsed, testSplashAppearsAtLaunch, testTappingHeaderExpandsAndCollapses.

## Convention grep (outside NYCFarmerMarkets/Theme/)

Pattern: `grep -rnE '<pattern>' NYCFarmerMarkets --include='*.swift' | grep -v '^NYCFarmerMarkets/Theme/'`

Patterns, each with 0 matches:
- `Color\((red|white|hue|"|[a-z]+:)`
- `(UIColor|NSColor)\(`
- `Color\.(red|blue|green|orange|yellow|purple|pink|gray|black|white|brown|cyan|mint|teal|indigo)\b`
- `0x[0-9A-Fa-f]{6}`
- `"#[0-9A-Fa-f]{6}"`
- `systemName:|systemImage:`
- `Image\(systemName`

Violations: none.

## Not verified

- testLaunchPerformance and NYCFarmerMarketsUITestsLaunchTests were skipped as instructed, so launch performance and launch screenshots are unchecked.
- Opening Apple Maps from the "Directions" button was not verified. The simulator cannot confirm an external app handoff; only the in-app pushed map is covered by UI test.
- The macOS build was compiled only; no tests were run on macOS.
- The convention grep is regex-based. Colors or icons built through indirect helper code would not be detected.
