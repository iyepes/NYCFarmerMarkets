# Manual design changes (after PR #8)

Design changes made by hand on `main` after the custom-fonts PR (#8, `cd3812d`).
They supersede what `.kiro/specs/custom-fonts-integration/` and the PR #8 notes say.

## Fonts

Commits: `d74e03e` "Replace fonts for readability, correct section header size",
`40dd19c` "Correct Section headers size", `a3ad360` "update test to match change in Family Font role".

- **Body font replaced.** Dr. Caligari is gone; the body family is now **Breath of the House**
  (file `NYCFarmerMarkets/fonts/Breath of the House.ttf`, PostScript `Breath-of-the-House`).
  Reason: readability.
- **Font files removed:** `DrCaligari.ttf` and the unused `N8ghtmare.ttf`.
  Bundled fonts now: `Grim Creeper.ttf` (display) and `Breath of the House.ttf` (body).
- **`Info.plist` `UIAppFonts`:** `Grim Creeper.ttf`, `Breath of the House.ttf`.
- **Display font unchanged:** Grim Creeper (`Grim-Creeper-Regular`) for titles.
- **Body scale kept:** `sizeScale` 1.15 and 14 pt floor still apply to the body family.

## Font roles and sizes (`Theme/AppTypography.swift`)

- **`sectionHeader` moved from the body family to the display family** (Grim Creeper),
  for readability of the borough headers.
- **`sectionHeader` size 15 → 30 pt.** The display family has scale 1 and no floor, so it draws at 30 pt.
- **`splash` size 26 → 40 pt.**
- **Borough header row (`Views/MarketListView.swift`):** the market count now uses
  `.appFont(.sectionHeader)` (was `.caption`), and the chevron icon is 30 pt (was 12).
- Tests updated to match: body PostScript name, and `sectionHeader` expected in `.display`.

Current role map:

| Family | Roles |
|---|---|
| display (Grim Creeper) | splash, splashHint, tabTitle, sectionHeader, tabBarLabel, navigationTitle, detailTitle, favoriteItemTitle |
| body (Breath of the House) | body, bodyEmphasis, subheadline, caption, footnote |

## Palette (`Theme/AppPalette.swift`)

Commit: `e11636c` "Spooky Colors". Green/olive palette replaced by a purple/orange one.
Only `AppPalette.Base` changed; the semantic tokens and their mixes are the same.

| Base | Old | New |
|---|---|---|
| `primary` | `0xC7D93D` lime | `0xAC84D6` lavender |
| `secondary` | `0x98A62E` olive green | `0xC56B23` pumpkin orange |
| `deep` | `0x525919` dark olive | `0x31078C` deep purple |
| `highlight` | `0xE6F28D` pale lime | `0xCA881E` amber |
| `surface` | `0xF2F2F2` light gray | `0xCBC7D9` lavender gray |
| `appIconOlive` | `0x78872B` olive | `0xC56B23` pumpkin orange |

The old values are kept as trailing comments in the code.

### 2026-11-14: splash contrast fix

Commit `9b16611`, issue #14 (owner-approved, separate from the sound feature).
`onAppIconBackground` changed from `Base.surface` (`0xCBC7D9`, 2.31:1 on orange) to
`Base.deep` (`0x31078C`, 3.57:1), so the splash logo, dots and text pass the 3.0 contrast test.
`basePaletteMatchesDesign()` was updated to the current palette.

## App icon, logo and name

Commits: `243862a` "Icon and name changes", `e247b5d` "Gradient icon".

- **Display name:** `NY Farmer Mkt` → **`Spooky Markets`** (`INFOPLIST_KEY_CFBundleDisplayName`,
  Debug and Release in `project.pbxproj`). The bundle id and Xcode target/scheme names are unchanged.
- **Splash/logo asset `logo-carrot`:** redrawn as a pumpkin face (mouth and eyes) in
  `#AC84D6` fill with `#C56B23` stroke. The asset name is still `logo-carrot`.
- **App icon PNGs:** all sizes in `AppIcon.appiconset` replaced, last with a gradient version.

## Loose ends found while reading the code (not changed)

- `Design/AppIcon.svg` was not updated by these commits, so it no longer matches the icon PNGs.
- The `sizeScale` comment says Breath of the House "has a small x-height and thin strokes";
  that text was written for Dr. Caligari. The 1.15 scale and 14 pt floor were not re-checked for the new font.
- `appIconOlive` and its comment "Olive used as the app icon background" now hold orange.
- `sectionHeader` still scales with the `.subheadline` text style while drawing at 30 pt,
  so it grows with Dynamic Type like a subheadline does.
- The row subtitle separator is ", " because Dr. Caligari had no "·". Not checked whether
  Breath of the House has that glyph.
- **Breath of the House is a paid font.** Embedded metadata (checked 2026-11-14): copyright
  BlackFridayFont, "All rights reserved"; license text asks for a €2 payment and then allows use
  "for one project". OS/2 `fsType` 0x0004 (preview & print embedding). The dafont page has the same
  €2 terms; some mirrors list it as donationware or personal use only. No license file is in the repo.
  The `.ttf` is also published in this public GitHub repo, which the license text does not mention.
  **Update 2026-11-14:** the owner paid the €2 license. Redistribution in the public repo is still to be confirmed with the author.
- Embedded PostScript name is `Breath of the House` (spaces); the code asks for `Breath-of-the-House`.
  CoreText still resolves it (`bothFamiliesResolveAfterRegistration` passes), so no change needed.
- `.kiro/specs/custom-fonts-integration/` still describes Dr. Caligari and the old role map.
