# Implementation Plan: Custom Fonts Integration (issue #7)

## Overview

> Tasks 1-9 are the original plan, done in PR #8 (the body font there became Dr. Caligari). Tasks 10-14 cover the manual changes after PR #8: the body font is now Breath of the House. See the design "Amendment 2".

Add `AppTypography` (Grim Creeper for title roles, N8ghtmare for the rest) in `Theme/`, register the fonts at runtime with CoreText, switch every view to `.appFont(role)`, style the UIKit bars in `ThemeAppearance`, extend the convention gate, then verify with builds, tests, screenshots and a license report. New files under `NYCFarmerMarkets/` and `NYCFarmerMarketsTests/` are picked up automatically (synchronized groups); do not edit `project.pbxproj`. All paths are under `/Users/isabelyepes/Documents/XCode/NYCFarmerMarkets/`. Run git as `git -C <repo> ...`; never stage anything under `.agents/`.

Commands used below (discover the simulator name once with `xcrun simctl list devices available`; call it `$SIM`):
- iOS build: `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination "platform=iOS Simulator,name=$SIM" build`
- macOS build: `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination "platform=macOS" build`
- Unit tests: same as the iOS build with `-only-testing:NYCFarmerMarketsTests test`
- Full tests: same with `test`

## Tasks

- [x] 1. Baseline and bundle layout check (no code changes)
  - Build iOS and macOS on the branch as is; record warnings. List the built `.app` (`find <DerivedData>/.../NYCFarmerMarkets.app -name '*.ttf'`) for both platforms to learn if the fonts are at the bundle root or in `fonts/`.
  - Take base-commit (`373af50`) simulator screenshots of the Markets list (large title unscrolled and scrolled) for the later nav bar comparison.
  - Files: none
  - Requirements: 1.1, 1.2, 1.6
  - Verify: both builds succeed; layout notes recorded in the task findings.

- [x] 2. Create `AppTypography` with pure logic
  - [x] 2.1 Create `NYCFarmerMarkets/Theme/AppTypography.swift`
    - `nonisolated enum AppTypography` with nested `nonisolated` `Family` (postScriptName `Grim-Creeper-Regular` / `N8ghtmare`, fileName `Grim Creeper.ttf` / `N8ghtmare.ttf`), `Role` (13 cases per the design table: family, size, textStyle, fallbackWeight, `font`), `Resolved: Equatable, Sendable`, `Registration: Sendable { availableFamilies: Set<Family> }`.
    - `resolvedFont(for:isAvailable:)` pure function; `isAvailable(postScriptName:)` via `CTFontCreateWithName` + `CTFontCopyPostScriptName`.
    - `@discardableResult static func registerFonts() -> Registration` backed by a `static let registration`: URLs from `(Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []) + (... subdirectory: "fonts" ?? [])`, de-duplicated, only the two `Family.fileName` files, `CTFontManagerRegisterFontsForURL(url, .process, &error)`, already-registered treated as success, `Logger` category `typography` on other errors, family available only if the PostScript name resolves. No force unwraps.
    - `extension View { func appFont(_ role: AppTypography.Role) -> some View }`. Detail borough line uses `bodyEmphasis` at `.title3` size: add a dedicated role only if needed; otherwise pick the closest body role and keep its previous visual size (design note 5). Splash caption keeps a size comparable to the old `.title3.weight(.semibold)` (use `splashHint`).
    - Requirements: 1.3, 1.4, 1.5, 3.1-3.4, 4.1, 5.1, 6.1
  - [x] 2.2 Create `NYCFarmerMarketsTests/AppTypographyTests.swift` (Swift Testing, `import Testing`, `@testable import NYCFarmerMarkets`)
    - PostScript name constants; after `registerFonts()` both families resolve (`UIFont`/`NSFont` non-nil under `#if canImport(UIKit)` / `#elseif canImport(AppKit)`); exhaustive `switch` over `Role.allCases` for family mapping; `resolvedFont` with `{ _ in true }` returns `.custom` with the right name/size/style and with `{ _ in false }` returns `.system` with the role's style and `fallbackWeight` for every role; font file names exist in the test host bundle.
    - Requirements: 8.1, 8.2, 8.3, 1.1
  - Verify: unit tests command passes; iOS and macOS builds succeed.

- [x] 3. Register fonts at launch and set the root font
  - In `NYCFarmerMarkets/NYCFarmerMarketsApp.swift`: call `AppTypography.registerFonts()` first in `init()`, before `ThemeAppearance.apply()`; add `.environment(\.font, AppTypography.Role.body.font)` on the `WindowGroup` content.
  - If task 1 showed the fonts in a `fonts/` subfolder, change the three `UIAppFonts` strings in `NYCFarmerMarkets/Info.plist` to `fonts/<file name>`; otherwise leave it.
  - Files: `NYCFarmerMarkets/NYCFarmerMarketsApp.swift`, `NYCFarmerMarkets/Info.plist` (conditional)
  - Requirements: 1.2-1.4, 3.4, 5.3
  - Verify: iOS and macOS builds succeed with no new font/resource warnings; unit tests pass.

- [x] 4. Apply roles in the views
  - [x] 4.1 Splash: `SplashView.swift` (message `.splash`, hint `.splashHint`), `SplashLoadingIndicator.swift` (caption `.splashHint`).
    - Requirements: 4.1, 5.1
  - [x] 4.2 Shared: `Views/Shared/MarketRow.swift` (new `titleRole: AppTypography.Role = .bodyEmphasis` parameter; subtitle `.subheadline`; days `.caption`), `OfflineBanner.swift` and `MapFilterIndicator.swift` (`.footnote`); `Theme/ThemeStyling.swift` `ThemedButtonStyle` (`.bodyEmphasis`). Accessibility code and identifiers unchanged.
    - Requirements: 4.4, 5.1, 5.2, 7.3
  - [x] 4.3 Tabs: `FavoritesView.swift` passes `titleRole: .favoriteItemTitle`; `RootTabView.swift` tab-item `Text`s get `.appFont(.tabBarLabel)`; `MarketListView.swift` section header `.sectionHeader`, count `.caption`; `MarketMapView.swift` callout title `.bodyEmphasis`, subtitle `.subheadline`; `MarketDetailView.swift` name `.detailTitle`, borough per task 2.1, field label `.caption`, value `.body`; "Remove" swipe label as `Text("Remove").appFont(.bodyEmphasis)` inside its `Label`.
    - Requirements: 4.2-4.4, 5.1, 5.2, 6.2
  - Verify: iOS and macOS builds succeed; full tests (unit and UI) pass.

- [x] 5. Style system-rendered bars (iOS only)
  - [x] 5.1 Create `NYCFarmerMarkets/Theme/AppTypography+UIKit.swift` under `#if canImport(UIKit) && !os(visionOS)`: `static func uiFont(_ role: Role) -> UIFont` (`UIFontMetrics` scaled, system font fallback) and a `Role` to `UIFont.TextStyle` mapping.
    - Requirements: 3.4, 4.5, 6.1
  - [x] 5.2 In `Theme/ThemeStyling.swift` `ThemeAppearance.apply()`: add `.font: tabBarFont` (`let tabBarFont = AppTypography.uiFont(.tabBarLabel)`) to both tab item `titleTextAttributes`; create a `UINavigationBarAppearance()` with no `configureWith...`, set `largeTitleTextAttributes` (`.tabTitle`) and `titleTextAttributes` (`.navigationTitle`), assign to standard, compact and scroll-edge appearance, keep the tint; set `UISearchTextField.appearance().font` to `.body`. Split the font part into a function that can be re-run.
    - Requirements: 4.2, 4.3, 4.5, 5.2
  - [x] 5.3 Dynamic Type for the bars (owner choice a): observe `UIContentSizeCategory.didChangeNotification` (from `NYCFarmerMarketsApp.init()` or `ThemeAppearance`) and re-run the font part of `apply()`. If a bar does not rescale in a running app, record it as a limitation for the PR.
    - Requirements: 6.1
  - [x] 5.4 Nav bar fallback: if the Markets list screenshots differ from the task 1 baseline in bar background or scroll-edge look, remove the navigation bar appearance and use `.toolbar { ToolbarItem(placement: .principal) { Text(...).appFont(.navigationTitle) } }` for inline titles (keep `navigationTitle` for accessibility); report that large titles stay in the system font. Do not add `.principal` items for macOS (owner decision).
    - Requirements: 4.2, 4.5
  - Verify: iOS and macOS builds succeed (macOS must compile without the UIKit file); full tests pass; screenshots in task 8.

- [x] 6. Extend the convention gate
  - Edit the "Project conventions" paragraph of the step 6 prompt (line ~157) in `.kiro/workflows/feature-to-pr.workflow.json` to add the three patterns from the design (`\.custom\(|\bFont\.(system|custom)\(`, `Grim|N8ghtmare|Caligari|\.ttf`, `\.font\(\s*(\.|Font\.)`), each as `grep -rnE '<pattern>' NYCFarmerMarkets --include='*.swift' | grep -v '^NYCFarmerMarkets/Theme/'`. Keep the JSON valid.
  - Files: `.kiro/workflows/feature-to-pr.workflow.json`
  - Requirements: 3.5, 3.6, 8.6
  - Verify: `python3 -m json.tool .kiro/workflows/feature-to-pr.workflow.json > /dev/null` succeeds; run the existing color/hex/SF Symbol checks plus the three new commands by hand from the repo root, each printing zero lines. Keep the commands and output for the PR.

- [x] 7. Licensing report
  - Read name IDs 0, 7, 8, 9, 13, 14 of the three fonts with `fc-scan` or a throwaway script in `/tmp` (install `fontTools` only in a temporary virtual environment); delete the script. Quote the metadata verbatim; do not guess terms. The owner already saw: Grim Creeper "Free to use for personal & commercial purposes" (sinisterfonts.com); N8ghtmare copyright "LionelPailloncy", no license text; DrCaligari placeholder copyright, no license text. Confirm these.
  - Save the report to `.agents/tasks/feature-to-pr/` (not staged), for the top of the push approval request and the PR.
  - Requirements: 2.1-2.3, 1.7
  - Verify: the report lists all three fonts and flags missing license text.

- [x] 8. Full verification and visual evidence
  - Run the iOS and macOS builds, the full unit and UI suites, and the three convention greps. Check the build log for font/resource warnings. Confirm `.ttf` files are present in both built `.app` bundles.
  - Simulator screenshots (`xcrun simctl io booted screenshot`): splash loading and failed (`failDownload` launch option), each tab with large title, the nav bar before/after comparison, detail sheet, Favorites with at least one favorite, a long market name at `xcrun simctl ui booted content_size extra-extra-extra-large`, and a size change in a running app for task 5.3.
  - Review readability (splash hint in the display font; small tab labels), glyph coverage for market-data characters, search prompt and "Remove" rendering. Tune sizes only in `AppTypography.swift`. If the splash hint is unreadable, raise it with the owner rather than switching to the body font.
  - Requirements: 1.1, 1.2, 1.6, 4.6, 5.3, 6.3, 6.4, 7.1, 7.2, 8.4, 8.5, 8.7
  - Verify: all commands pass; screenshots saved outside the repo or under `.agents/`.

- [x] 9. Specs and PR notes
  - Copy requirements, design and this plan (as `tasks.md`) to `.kiro/specs/custom-fonts-integration/`; tick completed tasks.
  - Prepare the PR text: license findings at the top, observed bundle layout per platform, a "Deviations" section (macOS tab and navigation titles stay in the system font, deviating from 4.2, 4.3 and 4.5 by the owner's decision, confirmed), Map tab has no navigation title, assumptions to confirm (Markets rows and Retry use the body font), system-owned elements that stay in SF, not verified (macOS visual check, visionOS), convention command output, no full accessibility compliance claim.
  - Files: `.kiro/specs/custom-fonts-integration/{requirements,design,tasks}.md`
  - Requirements: NFR 3, 2.3, 4.6, 8.8
  - Verify: three files exist and the headings match the other specs in `.kiro/specs/`.

## Digest

Verified by reading: nothing has been built or tested in this planning step. Today's baseline pass state of the unit and UI tests is unknown and is task 1's job.

- `NYCFarmerMarkets/Theme/AppTypography.swift` (new). Covered by `NYCFarmerMarketsTests/AppTypographyTests.swift` (new).
- `NYCFarmerMarkets/Theme/AppTypography+UIKit.swift` (new, iOS guard). Covered by screenshots only.
- `NYCFarmerMarkets/NYCFarmerMarketsApp.swift`: `init()` and the `WindowGroup` content. Existing tests plus build.
- `NYCFarmerMarkets/Theme/ThemeStyling.swift`: `ThemedButtonStyle.makeBody` line 38 `.font(.headline)`; `ThemeAppearance.apply()` (tab bar loop, nav tint). Screenshots.
- `NYCFarmerMarkets/Views/SplashView.swift` lines 38, 44: `.title2.weight(.bold)`, `.title3.weight(.semibold)`.
- `NYCFarmerMarkets/Views/SplashLoadingIndicator.swift` line 27: `.title3.weight(.semibold)`.
- `NYCFarmerMarkets/Views/Shared/MarketRow.swift` lines 30, 34, 39: `.headline`, `.subheadline`, `.caption`; shared by `MarketListView` and `FavoritesView`.
- `NYCFarmerMarkets/Views/Shared/OfflineBanner.swift` line 13 and `MapFilterIndicator.swift` line 17: `.footnote.weight(.medium)`.
- `NYCFarmerMarkets/Views/MarketListView.swift` lines 90, 93: section header and count; `navigationTitle("Markets")` line 26.
- `NYCFarmerMarkets/Views/MarketMapView.swift` lines 91, 94: callout `.headline`, `.subheadline`.
- `NYCFarmerMarkets/Views/MarketDetailView.swift` lines 81, 85, 97, 100: `.title.bold()`, `.title3`, `.caption`, `.body`; `navigationTitle("Market details")` line 65.
- `NYCFarmerMarkets/Views/FavoritesView.swift`: `navigationTitle("Favorites")` line 18; passes `titleRole` to `MarketRow`.
- `NYCFarmerMarkets/Views/RootTabView.swift`, `MarketLocationMapView.swift` (`navigationTitle(market.name)` line 42): `RootTabView` was not read in this step; open it before editing.
- `NYCFarmerMarkets/Info.plist`: only if the bundle layout needs `fonts/` prefixes.
- `.kiro/workflows/feature-to-pr.workflow.json`: step 6 prompt conventions paragraph.
- Not touched: `project.pbxproj`, font files, `Theme/AppIcon.swift` (its `.font(.system(size:))` is inside `Theme/` and allowed).
- Existing tests in `NYCFarmerMarketsTests/` and UI tests in `NYCFarmerMarketsUITests/` must keep passing; they are not run yet.

## Tasks after PR #8 (design "Amendment 2")

- [x] 10. Replace the body font and adjust headers (owner, manual commits)
  - [x] 10.1 Body family to Breath of the House: `Family.body` PostScript name `Breath-of-the-House`, file `Breath of the House.ttf`; `Info.plist` `UIAppFonts` lists only `Grim Creeper.ttf` and `Breath of the House.ttf`; `DrCaligari.ttf` and `N8ghtmare.ttf` deleted (`d74e03e`, `40dd19c`).
    - Requirements: 1.3-1.5, 1.7, 5.1
  - [x] 10.2 `sectionHeader` moved to the display family at 30 pt; `splash` 26 → 40 pt; borough header count uses `.sectionHeader` and the chevron is 30 pt in `MarketListView` (`40dd19c`).
    - Requirements: 4.1, 4.7
  - [x] 10.3 `AppTypographyTests` updated for the new PostScript name and role map (`40dd19c`, `a3ad360`).
    - Requirements: 8.1, 8.2
  - Verify: done 2026-11-14, `-only-testing:NYCFarmerMarketsTests/AppTypographyTests` passes (10 tests) on the iOS simulator.

- [x] 11. License report for Breath of the House
  - Read the embedded name table (copyright, license, `fsType`) and the publisher's dafont page. Result in the design "Amendment 2", Licensing.
  - Requirements: 2.1, 2.2, 2.4

- [ ] 12. Confirm the Breath of the House license before distributing (owner)
  - Confirm the €2 payment and keep the receipt; ask BlackFridayFont whether the `.ttf` may stay in the public GitHub repository, or remove it from the public repo.
  - Requirements: 2.4

- [ ] 13. Review Breath of the House on screen
  - Re-check the body `sizeScale` (1.15) and `minimumSize` (14 pt) for the new font and fix the `sizeScale` comment, which still describes Dr. Caligari. Tune only in `AppTypography.swift`.
  - Check whether the font draws "·"; if it does, the owner may restore it as the row separator in `MarketRow`.
  - Check the borough headers (30 pt text and chevron) at `.xxxLarge`; `sectionHeader` scales with `.subheadline`.
  - Requirements: 6.1, 6.3, 7.1, 7.2
  - Verify: simulator screenshots at the default size and at `.xxxLarge`; unit and UI tests pass.

- [ ] 14. Extend the convention gate to the new font name
  - Add `Breath` to the font-name pattern (`Grim|Breath|\.ttf`; the removed names may be dropped) in the conventions paragraph of the test-gate step of `.kiro/workflows/feature-to-pr.workflow.json`. Keep the JSON valid.
  - Requirements: 3.5, 3.6, 8.6
  - Verify: `python3 -m json.tool .kiro/workflows/feature-to-pr.workflow.json > /dev/null` succeeds; the grep prints zero lines outside `Theme/`.
