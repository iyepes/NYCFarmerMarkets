**License warning (read first):** Dr. Caligari now covers most UI text, but its file has a placeholder copyright "(your company)" and no license text, so its author and terms are unknown. N8ghtmare (copyright "LionelPailloncy", no license text) is no longer used but is still in the repository. Grim Creeper states "Free to use for personal & commercial purposes" (sinisterfonts.com), which the metadata does not tie to embedding in an app. Confirm terms before distributing.

## Summary
Integrates the custom fonts in `NYCFarmerMarkets/fonts`:
- Fonts are registered at launch, with an `AppTypography` role layer and a root font.
- Grim Creeper is used for the splash screen, tab titles, detail title and Favorites item titles.
- Body text started as N8ghtmare. After owner review on the simulator (N8ghtmare digits were hard to read, "5" looked like "s") it was changed to Dr. Caligari. This supersedes the issue #7 note that Dr. Caligari would stay unused in the UI.
- Also: body size scale 1.15 with a 14 pt floor, tab label cap at 15 pt, Markets screen rebuilt on text-size change, comma separator in row subtitles, and tab bar, navigation bar and search field fonts on iOS.
- Font rules were added to the convention gate. A spec is included.

## Test report
Run from the repo root, scheme NYCFarmerMarkets:
1. iOS build (iPhone 17 simulator): BUILD SUCCEEDED.
2. macOS build (`platform=macOS`): BUILD SUCCEEDED.
3. Unit tests (`-only-testing:NYCFarmerMarketsTests`): 87 passed, 0 failed.
4. Full run (unit and UI, launch tests and testLaunchPerformance skipped): 101 passed, 0 failed.
5. Convention grep outside `Theme/` (color literals, hex, raw symbol names): no matches.

Re-run after the Dr. Caligari change (`5f4f649`):
- iOS unit and UI tests: 0 failed. The result summary shows two pass counts (104 and 98) that I could not reconcile. The total test count is 98.
- macOS build: succeeded.
- Convention grep (now also font names, `.custom(`, direct `.font(...)`): no matches.
- Screenshots reviewed on the iPhone 17 simulator: Markets (collapsed and expanded), empty search, detail, Favorites, Map tab, and Markets at default and accessibility-extra-large sizes, live and after relaunch.

## Anything not verified
- Known bug: on the Map tab the three tab-bar labels render in the system font, not Grim Creeper. Two fix attempts had no effect and were removed. Cause unconfirmed.
- macOS tab and navigation titles stay in the system font (owner's decision), departing from requirements 4.2, 4.3 and 4.5. macOS was compile-checked only, and macOS tests were not run.
- visionOS not checked. The live text-size change was verified on the Markets screen only.
- Font registration in the built bundle (Info.plist, resource copy) was not inspected in the test step.
- Dr. Caligari is a calligraphic face: "t" can look like "r" or a cross and "h" has a flourish, so some words need a second look. Digits are clear.
- Grep covers only the listed patterns.

Closes #7
