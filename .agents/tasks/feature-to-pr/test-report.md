# Test report: custom fonts integration (issue #7)

Branch: feature/7-custom-fonts-integration. No code was changed in this step.

## Commands run (from /Users/isabelyepes/Documents/XCode/NYCFarmerMarkets)

1. iOS build: `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/dd build`
   Result: BUILD SUCCEEDED.
2. macOS build: same with `-destination 'platform=macOS' -derivedDataPath /tmp/ddmac`
   Result: BUILD SUCCEEDED.
3. Unit tests: iOS `test -only-testing:NYCFarmerMarketsTests`
   Result: TEST SUCCEEDED. 87 test cases passed, 0 failed.
4. Full run: iOS `test -skip-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITestsLaunchTests -skip-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITests/testLaunchPerformance`
   Result: TEST SUCCEEDED. 101 test cases passed, 0 failed (unit plus UI tests, live NYC Open Data API reachable).
   The log contained one transient "Simulator device failed to launch ...xctrunner" message; the run still finished with TEST SUCCEEDED and no failed cases, so no manual re-run was needed.
5. Convention grep (outside NYCFarmerMarkets/Theme/):
   `grep -rnE 'Color\((red|white|hue|"|\.sRGB|\.display)|UIColor\(|NSColor\(|Color\.(red|blue|green|yellow|orange|purple|pink|black|white|gray|brown|cyan|mint|teal|indigo)\b|0x[0-9A-Fa-f]{6}|"#[0-9A-Fa-f]{6}|systemName:|systemImage:|Image\(systemName' NYCFarmerMarkets --include='*.swift' | grep -v '^NYCFarmerMarkets/Theme/'`
   Matches: none. No violations.

## Not verified

- Font rendering on screen (Grim Creeper vs N8ghtmare per element) was not visually checked; only build, tests and the grep were run.
- Font registration in the built bundle (Info.plist UIAppFonts / ATSApplicationFontsPath, resource copy) was not inspected in this step.
- macOS tests were not run (only the macOS build).
- Grep only covers the patterns above; other literal-style colors (for example `.red` shorthand without `Color.`) were not searched.


## Update after owner review (HEAD dad4cad; supersedes the font and count statements above)

The owner reviewed the app on the iOS simulator and decided to change the body font from N8ghtmare to Dr. Caligari (N8ghtmare digits were hard to read: "5" looked like "s"). Two commits were added: `5f4f649` (font swap, body size scale 1.15 with a 14 pt floor, tab label cap at 15 pt, Markets screen rebuilt on text-size change, comma separator in row subtitles) and `dad4cad` (spec amendment).

Re-run on `5f4f649`:
- iOS simulator (iPhone 17), unit and UI tests, launch tests and testLaunchPerformance skipped: 0 failed. The result summary shows two different pass counts (104 and 98) that I could not reconcile; the total test count is 98.
- macOS build: succeeded.
- Convention grep outside `Theme/` (color literals, hex, raw symbol names, font names, `.custom(`, direct `.font(...)`): no matches.
- Screenshots reviewed on the iPhone 17 simulator: Markets (collapsed and expanded), empty search, detail, Favorites, Map tab, and the Markets screen at default and accessibility-extra-large sizes, live and after relaunch.

Fixed and verified on screen: the invisible "·" separator (now a comma); tab labels overlapping their icons at accessibility-extra-large; the search field going blank after a live text-size change.

Not fixed: on the Map tab the three tab-bar labels render in the system font, not Grim Creeper. Two attempts (a second font source on UITabBarItem, and a visible tab bar background on the Map screen) had no effect and were removed. Cause unconfirmed.

Deviations and limits to state in the PR:
- macOS tab and navigation titles stay in the system font (owner's decision), departing from requirements 4.2, 4.3 and 4.5. macOS was compile-checked only.
- visionOS not checked. The live text-size change was verified on the Markets screen only.
- Dr. Caligari is a calligraphic face: "t" can look like "r" or a cross and "h" has a flourish, so some words need a second look. Digits are clear.

LICENSE (show first in the PR): Dr. Caligari now covers most UI text and its file has a placeholder copyright "(your company)" and no license text, so its author and terms are unknown. N8ghtmare (copyright "LionelPailloncy", no license text) is no longer used but is still in the repository. Grim Creeper states "Free to use for personal & commercial purposes" (sinisterfonts.com), which the metadata does not tie to embedding in an app. Confirm terms before distributing.
