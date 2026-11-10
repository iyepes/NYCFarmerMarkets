Code review: feature/7-custom-fonts-integration

Verdict: APPROVED. No blockers.

Checked (diff read, commit-message evidence read, no suites re-run):
- Registration: runtime CTFontManagerRegisterFontsForURL (AppTypography.swift register()), called first in NYCFarmerMarketsApp.init. It handles already-registered/duplicate errors and falls back to the system font via availableFamilies. The commits record the .ttf files at the iOS .app root and in macOS Contents/Resources, with no font warnings.
- Roles: Grim Creeper covers splash, splashHint, tabTitle, tabBarLabel, navigationTitle, detailTitle and favoriteItemTitle. N8ghtmare covers every other role. MarketRow takes titleRole so only Favorites rows use the display font. The detail header, "Market details" nav title, tab labels and large titles are covered through the UIKit appearances.
- Convention: no `.font(` or `Font.custom` outside Theme/ in the Swift views (the grep for this was partly interrupted, but the diff shows every `.font(` replaced, and the coder recorded zero matches). No color or SF Symbol changes.
- Dynamic Type: Font.custom(relativeTo:) and UIFontMetrics are used. Fallback and role mapping are unit tested (AppTypographyTests, 100 cases passed per commit 8fba92b).
- Empty-state fix (8fba92b) correctly sets fonts on ContentUnavailableView title and description.
- No .agents/ files in the diff. DrCaligari is untouched, as decided in the issue.

Non-blocking notes (no action required):
- Live text-size change: tab bar fonts are set once at launch (ThemeStyling.swift), so existing tab labels may not rescale until relaunch. The coder disclosed this.
- Not verified per the commits: macOS visual check, visionOS, and screenshots of the detail sheet, Favorites with items and the empty states. The PR notes should say so.
- Font licensing: N8ghtmare and DrCaligari have no license text in their metadata. This is in the licensing report and should be flagged in the PR.
