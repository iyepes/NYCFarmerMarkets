---
inclusion: fileMatch
fileMatchPattern: 'NYCFarmerMarkets/**/*.swift'
---

# Theme conventions (colors, icons, fonts, copy)

Everything visual comes from `NYCFarmerMarkets/Theme/`. Views use semantic names only, so a theme change is a one-file change.

## Colors: `AppPalette`

- Hex literals live in `AppPalette.Base`, except for the `0x000000` blend input in `AppPalette.background`. Views use semantic tokens (`AppPalette.background`, `.card`, `.cardSelected`, `.textPrimary`, `.textSecondary`, `.accent`, `.accentFill`, `.onAccentFill`, `.accentSecondary`, `.sectionHeader`, `.separator`, `.appIconBackground`, `.onAppIconBackground`) via `.color` (SwiftUI) or `.platformColor` (UIKit/AppKit).
- Current palette is purple/orange: primary `0xAC84D6` lavender, secondary `0xC56B23` pumpkin orange, deep `0x31078C` deep purple, highlight `0xCA881E` amber, surface `0xCBC7D9` lavender gray. `appIconOlive` is a legacy name that now holds orange.
- Need a new color role? Add a token derived from `Base` (use `AppPalette.mix`), and check text contrast with `AppPalette.contrast`.
- Reusable styling: `.themedBackground()`, `.themedCard(selected:)`, `ThemedButtonStyle()`.

## Icons: `AppIcon`

- Every icon is an `AppIcon` case with a `source` (`.symbol` SF Symbol or `.asset`) and a plain `accessibilityName`. Views use `IconView(.case, size:)` or `AppIcon.case.image`; never `Image(systemName: "...")` or `systemImage: "..."` with a literal outside `Theme/`.
- Spooky assets: `icon-pumpkin` (Markets tab), `icon-ghost-filled` / `icon-ghost-outline` (favorites), `icon-bat` (map pin), `logo-carrot` (splash logo, now drawn as a pumpkin face; the asset name was kept).

## Fonts: `AppTypography`

- Two families: **display** Grim Creeper (`Grim-Creeper-Regular`) and **body** Breath of the House (`Breath-of-the-House`). Each has one weight; do not ask for bold or semibold (it would be synthetic). Hierarchy comes from role, size and family.
- Views set fonts only with `.appFont(.role)`. Roles: display `splash` (40), `splashHint` (22), `tabTitle` (34), `tabBarLabel` (12), `navigationTitle` (20), `detailTitle` (30), `sectionHeader` (30), `favoriteItemTitle` (20); body `body` (17), `bodyEmphasis` (17), `subheadline` (15), `caption` (12), `footnote` (13).
- Body sizes are multiplied by `sizeScale` 1.15 with a 14 pt floor (`effectiveSize`); every role scales with Dynamic Type via `relativeTo`. If a family fails to load, the role falls back to the system font with the same text style and `fallbackWeight`.
- A new role needs: a case in `Role`, entries in `family`, `size`, `textStyle`, `fallbackWeight` and `uiTextStyle` (`AppTypography+UIKit.swift`), and the exhaustive family test in `AppTypographyTests`.
- UIKit-drawn bars (tab bar, navigation bar, search field) get fonts in `ThemeAppearance` through `AppTypography.uiFont(_:)`, re-applied on `UIContentSizeCategory.didChangeNotification`. The tab bar label is capped at 15 pt (`maximumPointSize`).
- `MarketListView` has `.id(dynamicTypeSize)` so the search field is rebuilt after a text-size change. Keep it.
- Separators in composed text use ", " (the "·" was dropped because an earlier font did not draw it).
- `AppTypography.registerFonts()` runs first in `NYCFarmerMarketsApp.init()`, before `ThemeAppearance.apply()`.

## Copy: `AppCopy`

- Spooky user-facing text (splash caption, offline banner, search prompt and empty state, map filter summary, missing values) lives in `AppCopy`, each with a plain `...Accessibility` counterpart where VoiceOver needs one. Add new spooky strings there; keep the tone light, never alarming.
- Accessibility labels, hints and identifiers stay plain and are not themed.

## Sounds: `AppSound`

- Every sound is an `AppSound` case (`humanSteps`, `catSteps`, `door`, `doorAndHit`, `hiss`) with `fileName`, `fileExtension` and `loops`. File names live only in `Theme/AppSound.swift`; views never touch audio and send cues to `SoundController` (`play(_:)`, `handle(_:loop:)`).
- Sound toggle icons: `AppIcon.soundOn` ("Sounds on") and `soundOff` ("Sounds off"), used by `SoundToggleButton` (identifier `sound-toggle`, label "Sounds", value "On"/"Off").
- New buttons that use `ThemedButtonStyle` hiss on press automatically. Plain-style buttons call `sounds.play(.hiss)` in their action.

## Accessibility

- Every interactive control has a plain `accessibilityLabel`; decorative icons are hidden (`IconView` does this).
- New UI-test-reachable elements get a kebab-case `accessibilityIdentifier`.
- Do not claim WCAG compliance; full validation needs manual testing with assistive technologies.

## Convention check (must print zero lines)

Run from the repo root before finishing any UI change:

```sh
grep -rnE '\.custom\(|\bFont\.(system|custom)\(' NYCFarmerMarkets --include='*.swift' | grep -v '^NYCFarmerMarkets/Theme/' || true
grep -rnE 'Grim|Breath|\.ttf' NYCFarmerMarkets --include='*.swift' | grep -v '^NYCFarmerMarkets/Theme/' || true
grep -rnE '\.font\(\s*(\.|Font\.)' NYCFarmerMarkets --include='*.swift' | grep -v '^NYCFarmerMarkets/Theme/' || true
grep -rnE 'Image\(systemName:|systemImage: *"|0x[0-9A-Fa-f]{6}|"#[0-9A-Fa-f]{6}"|Color\.(red|blue|green|orange|yellow|purple|pink|gray|black|white)\b' NYCFarmerMarkets --include='*.swift' | grep -v '^NYCFarmerMarkets/Theme/' || true
grep -rnE 'human-steps|cat-steps|door-and-hit|short-hiss|\.m4a' NYCFarmerMarkets --include='*.swift' | grep -v '^NYCFarmerMarkets/Theme/' || true
```

Use judgment on matches (for example `Image(systemName:` inside `Theme/AppIcon.swift` is the registry itself).
