Integrate custom fonts Grim Creeper and N8ghtmare

## Description
The fonts `Grim Creeper.ttf`, `N8ghtmare.ttf` and `DrCaligari.ttf` were added under `NYCFarmerMarkets/fonts`. Make sure they are properly registered and bundled for distribution (iOS, macOS, visionOS) and apply them across the app through a single typography entry point.

Usage:
- Grim Creeper: splash screen text, tab titles (tab bar labels and large navigation titles of the three tabs), market detail title (name header and its navigation title), and item titles in the Favorites list.
- N8ghtmare: all other visible text (body, hints, captions, buttons, banners, search field, section headers, detail field labels and values).

Question for the maintainer: `DrCaligari.ttf` is not requested for the UI. Keep it in the repo or remove it?

## Scope
- Verify font files are tracked in git and included in the app target's resources (the project uses file-system-synchronized groups).
- Choose one registration mechanism that works on all targets (supplemental Info.plist with UIAppFonts / ATSApplicationFontsPath, or runtime CTFontManagerRegisterFontsForURL).
- Add `Theme/AppTypography.swift` next to AppPalette and AppIcon, with semantic roles, `Font.custom(_:size:relativeTo:)` for Dynamic Type, and a system font fallback.
- Style system-rendered tab bar labels and navigation titles (e.g. via ThemeAppearance).
- Out of scope: changing colors, icons or text wording.

## Acceptance criteria
- [ ] Fonts are tracked in git and present in the built .app bundle on iOS and macOS, with no new build warnings
- [ ] One registration mechanism is chosen and works on iOS and macOS (visionOS reviewed)
- [ ] Real PostScript names are verified with a tool and used in code
- [ ] Font license and copyright metadata from each font's name table is inspected and reported; missing, personal-use-only or unknown licenses are flagged clearly
- [ ] `AppTypography` defines both families once, with semantic roles (splash, tab title, detail title, favorite item title, body, etc.)
- [ ] Views use only typography roles; no `.custom(` or font-name literals outside `Theme/` (convention grep extended)
- [ ] Grim Creeper is used for splash, tab titles, detail title and Favorites item titles; N8ghtmare for everything else
- [ ] Tab bar labels and navigation titles pick up the fonts
- [ ] Dynamic Type keeps working; fallback to the system font if a font fails to load
- [ ] Readability of the decorative fonts reviewed and any hard-to-read text flagged with what was done; VoiceOver text unchanged
- [ ] Long strings and large Dynamic Type checked for truncation on splash, tab labels, navigation titles, detail title and Favorites rows
- [ ] Unit tests cover font loading (expected PostScript names), role-to-family mapping and fallback
- [ ] Existing unit and UI tests still pass
- [ ] iOS and macOS builds pass; iOS simulator screenshots of splash, each tab, detail and Favorites; unverified items (macOS visual check, visionOS) reported
- [ ] Decision on `DrCaligari.ttf` recorded
