# Custom fonts: Grim Creeper for titles, N8ghtmare for everything else

Adds `AppTypography` in `Theme/` as the single source of fonts, with 13 semantic roles over two families. Fonts are registered at runtime with CoreText (`CTFontManagerRegisterFontsForURL`, process scope) instead of `UIAppFonts` or `ATSApplicationFontsPath`, so one mechanism covers iOS and macOS. Every `.font(...)` outside `Theme/` becomes `.appFont(role)`, and system-rendered bars (tab bar, navigation bar, search field) get UIKit appearance fonts on iOS. If a family fails to load, roles fall back to the system font. The workflow's convention gate also gets three font greps.

Watch for: (1) N8ghtmare and DrCaligari have no license text in their metadata, and all three .ttf files are tracked in a public repo (confirmed, per the coder's licensing report); (2) bar fonts on iOS do not rescale on a live text size change for already-created bars (likely, recorded by the coder as unverified); (3) macOS gets no navigation-bar font handling and was only build-checked (confirmed from the diff); (4) detail sheet, Favorites with items and Map tab were never screenshotted (confirmed, per the commit messages).

**Verdict**: APPROVED

## High-level view

Fonts are registered once, lazily, in `AppTypography.registerFonts()`, called first in the app's `init`. Availability is checked by exact PostScript name after registration, so a missing file or a failed registration degrades one family to the system font rather than breaking text. Because the files land at the bundle root (synchronized groups flatten the folder), no Info.plist change is needed; the lookup also tries a `fonts` subdirectory.

Role-to-family mapping is the design core. Display (Grim Creeper) covers splash, splash hint, tab titles, navigation titles, detail title and Favorites item titles. Everything else is N8ghtmare. `MarketRow` takes a `titleRole` parameter so Favorites can use the display role while the Markets list keeps the body-emphasis role. The root `.environment(\.font, ...)` sets N8ghtmare as the default for unstyled text.

System-rendered chrome is handled through `ThemeAppearance`. The navigation bar appearance sets only font attributes and does not call `configureWith...`, which keeps the system bar look. A content-size notification re-applies the nav bar and search field fonts, but not the tab bar fonts.

Verification is solid for iOS (100 test cases, one flaky live-API UI test that passed on rerun) and macOS builds. Gaps are visual: no macOS check, no visionOS, no screenshots of the detail sheet, Favorites with items, Map tab or long names.

<details>
<summary>Issues (6)</summary>

1. **Unlicensed fonts in a public repo** (confirmed) — N8ghtmare and DrCaligari have no license text, and DrCaligari has placeholder copyright. Confirm terms with the font sources before release, or replace them. Surface the licensing report in the PR description, because it is not committed.
2. **Tab bar fonts do not rescale live** (likely) — `applyFonts()` re-runs on a size change, but the tab bar appearance is built once in `apply()`. Re-apply the tab appearance in the same observer, or note it as a known limitation in the PR.
3. **macOS navigation titles keep the system font** (confirmed) — the UIKit extension is iOS-only, and the spec's requirement 5 mentions an equivalent on macOS "where applicable". State in the PR that macOS titles use the system font, or add handling.
4. **Unverified screens** (confirmed) — detail sheet, Favorites with items, Map tab and long-name wrapping were not screenshotted. Check these manually before merging, particularly that the sheet inherits the root font environment.
5. **Dead role in SwiftUI tab items** (likely) — `.appFont(.tabBarLabel)` inside `.tabItem` labels is generally ignored by the system tab bar; the real styling comes from `UITabBarAppearance`. It is harmless but misleading, and it does nothing on macOS or visionOS.
6. **Weights dropped in role mapping** (confirmed) — the section count (was semibold) and footnote text (was medium) now use the single N8ghtmare weight. This is expected with a single-weight font; confirm readability on the Markets list.

</details>

<details>
<summary>Details</summary>

## Registration without Info.plist

Runtime registration trades OS-level declaration for one code path. The ordering risk is covered because every role resolves through the same lazily initialized registration. `isAvailable` compares the exact PostScript name returned by CoreText, so silent substitution to a default font is not mistaken for success.

visionOS shares the SwiftUI path. The UIKit extension excludes it with `!os(visionOS)`, so the only visionOS gap is the unverified build and rendering.

## System bars and Dynamic Type

The nav bar large title uses the `tabTitle` role and the inline title uses `navigationTitle`, so the detail sheet's "Market details" inline title and the pushed map title render in the display family. The coder compared a Markets list screenshot with the base build and found the same background and layout, but only in the unscrolled state. The scrolled-edge appearance shares the same empty-based appearance object, so the likely behavior is unchanged, but it was not compared.

`UIFontMetrics.scaledFont` is used for UIKit fonts, so sizes track Dynamic Type at creation time. Appearance proxies only affect bars created after they are set, which is why the live change is limited. The tab bar is not in the observer at all.

## Readability of display fonts

Grim Creeper is applied to short, title-level text only: the splash message and hint, three tab titles, the detail name and Favorites item names. The coder's screenshots at default and accessibility-large sizes show the splash legible and wrapping. Long market names in the detail header and Favorites rows were not exercised, and these are the strings most likely to wrap heavily in a decorative face at larger text sizes.

## Tests

`AppTypographyTests` has 7 cases covering PostScript names, font lookup after registration, role-to-family mapping, system fallback, and font files present in the bundle. Not tested: the appearance configuration in `ThemeAppearance` and `MarketRow(titleRole:)` selection for Favorites. The macOS `NSFont` lookup is in the test source, but the macOS test target was not run (only a macOS build).

## Workflow gate change

`feature-to-pr.workflow.json` gets three font greps added to the test_gate conventions paragraph. It is a one-line change to automation config bundled with the feature. It is related to the spec's convention-grep requirement, but it changes the shared workflow for future runs.

</details>

<details>
<summary>File map</summary>

- `Theme/AppTypography.swift`: roles, families, registration, fallback, `appFont`
- `Theme/AppTypography+UIKit.swift`: scaled UIFont per role for iOS bars
- `Theme/ThemeStyling.swift`: tab bar fonts, nav bar and search field fonts, content-size observer, button style font
- `NYCFarmerMarketsApp.swift`: register fonts first, root body font
- `Views/*`, `Views/Shared/*`: `.font` replaced by `.appFont(role)`; empty-state fonts; `MarketRow` `titleRole`
- `NYCFarmerMarketsTests/AppTypographyTests.swift`: new unit tests
- `.kiro/specs/custom-fonts-integration/*`: requirements, design, tasks
- `.kiro/workflows/feature-to-pr.workflow.json`: font greps in the gate

Full diff: `git diff origin/main...HEAD`

</details>
