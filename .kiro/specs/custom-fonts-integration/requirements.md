# Requirements Document

## Introduction

This feature integrates two custom fonts, Grim Creeper (titles) and Breath of the House (everything else), into the NYC Farmer Markets app (iOS, macOS and visionOS). It first verifies that the font files ship inside the app and are registered on every platform. It then applies Grim Creeper to title-level text and Breath of the House to all other text, through one typography type in `Theme/`, in the same way `AppPalette` holds colors and `AppIcon` holds icons. Dynamic Type and VoiceOver keep working. Colors, icons and the wording of texts do not change. The fonts are in `NYCFarmerMarkets/fonts/`. Tracks GitHub issue #7.

### Revision history

- **Original (issue #7):** body font N8ghtmare; Dr. Caligari bundled and unused.
- **PR #8 (`cd3812d`):** body font changed to Dr. Caligari after visual review (N8ghtmare digits unreadable); body size scale 1.15 with a 14 pt floor; tab bar label capped at 15 pt. See the design "Amendment after visual review".
- **Manual commits after PR #8 (`d74e03e`, `40dd19c`, `a3ad360`, 2026-11-10/11):** body font changed to Breath of the House for readability; `DrCaligari.ttf` and `N8ghtmare.ttf` removed from the repo; section headers moved to the display font at 30 pt; splash text 40 pt. See the design "Amendment 2". This document describes the current state.

## Glossary

- **App**: The NYC Farmer Markets application.
- **App_Typography**: The single type in `NYCFarmerMarkets/Theme/` that defines both font families and the semantic text roles. The only place font names and `Font.custom` may appear.
- **Display_Font**: Grim Creeper (`Grim Creeper.ttf`). The user wrote "Grim Crepper"; this is the file that exists.
- **Body_Font**: Breath of the House (`Breath of the House.ttf`, by BlackFridayFont). Was N8ghtmare, then Dr. Caligari.
- **Removed_Fonts**: `N8ghtmare.ttf` and `DrCaligari.ttf`, no longer in the repository or the bundle.
- **Title_Role**: Splash text, tab titles, detail title, Favorites item titles, and borough section headers.
- **Splash_Screen**, **Markets_Tab**, **Map_Tab**, **Favorites_Tab**, **Detail_Sheet**: As in `.kiro/specs/nyc-farmer-markets/requirements.md`.
- **Tab_Title**: The tab bar label of each tab and the large navigation title of each tab.
- **Detail_Title**: The market name header in the Detail_Sheet and its navigation title.
- **Favorite_Item_Title**: The market name in each Favorites_Tab row.
- **Other_Text**: All visible text that is not a Title_Role (body text, hints, captions, buttons, banners, search field and prompt, detail field labels and values, empty and error states).

## Assumptions

1. "Titles" means title-level text. Borough section headers were added to the Title_Roles by the owner for readability (`40dd19c`); detail field labels remain Other_Text.
2. Tab_Title covers both the tab bar labels and the navigation titles of the three tabs.
3. Market names in Markets_Tab list rows are Other_Text, because the user listed only Favorites item titles. The design may flag this for confirmation.
4. Only the two used font files are bundled. The issue originally decided to keep `DrCaligari.ttf`; the owner later removed both unused files (`d74e03e`).
5. The repository already has `NYCFarmerMarkets/Info.plist` with a `UIAppFonts` array and `INFOPLIST_FILE` set alongside `GENERATE_INFOPLIST_FILE = YES`. Verification must confirm whether this works on every platform. It is not assumed to.
6. The user's phrasing "Review that fonts are properly registered" means verify and fix, not only report.

## Requirements

### Requirement 1: Fonts are bundled and registered on every platform
**User Story:** As the owner of the App, I want the fonts to ship with the App and load on iOS, macOS and visionOS, so that the typography appears on a real install and not only in my dev environment.

#### Acceptance Criteria
1. THE font files SHALL be tracked in git and present in the built app bundle of the iOS build and the macOS build.
2. THE App SHALL use one registration mechanism that covers all three platforms, or a documented per-platform pair, and SHALL verify it works on the iOS simulator and on macOS.
3. WHEN the iOS App starts, THE Display_Font and Body_Font SHALL be resolvable by their real PostScript names (`UIFont(name:size:)` returns non-nil).
4. WHEN the macOS App starts, THE Display_Font and Body_Font SHALL be resolvable by their real PostScript names (`NSFont(name:size:)` returns non-nil).
5. THE code SHALL use the PostScript names read from the font files with a tool, not the file names.
6. THE iOS and macOS builds SHALL complete with no new warnings related to fonts or resources.
7. THE repository and bundle SHALL contain only the font files the App uses (Display_Font and Body_Font); `Info.plist` `UIAppFonts` SHALL list exactly those two files.

### Requirement 2: Font licensing is reported
**User Story:** As the owner of a public repository and a possibly distributed App, I want to know the fonts' licenses, so that I do not ship something I may not embed.

#### Acceptance Criteria
1. THE feature SHALL report the license and copyright metadata found in the name tables of every bundled font file, quoting what the metadata says.
2. IF the metadata is missing, personal-use-only or unclear, THEN THE report SHALL flag it clearly and SHALL NOT guess the license terms.
3. THE report SHALL be included in the pull request description.
4. IF a bundled font requires payment or limits redistribution, THEN THE report SHALL say so, and the font SHALL NOT be distributed (App Store or public repository) until the owner confirms the license is met. Current state: Breath of the House asks for a €2 payment per project; see the design "Amendment 2".

### Requirement 3: Central typography type
**User Story:** As the owner of the App, I want fonts defined in one place, so that changing a font is a one-file change.

#### Acceptance Criteria
1. THE App SHALL define App_Typography in `NYCFarmerMarkets/Theme/`, `nonisolated` where the type holds only pure data.
2. THE App_Typography SHALL define semantic roles, at least: splash, tab title, detail title, favorite item title, and body-level roles for the rest of the text.
3. THE roles SHALL use `Font.custom(_:size:relativeTo:)` so that text scales with Dynamic Type.
4. IF a font cannot be loaded, THEN THE role SHALL fall back to the system font with the same text style, so that text is never empty or broken.
5. THE views SHALL use only App_Typography roles. No view outside `Theme/` SHALL contain a font-name string literal or `.custom(` call.
6. THE existing convention check SHALL be extended to fail on font-name literals and `.custom(` outside `Theme/`.

### Requirement 4: Display font on Title_Roles
**User Story:** As a user, I want the headline text to use the spooky display font, so that the App has a distinct look.

#### Acceptance Criteria
1. THE Splash_Screen text SHALL use the Display_Font.
2. THE Tab_Title of Markets_Tab, Map_Tab and Favorites_Tab, both the tab bar label and the navigation title, SHALL use the Display_Font.
3. THE Detail_Title SHALL use the Display_Font.
4. THE Favorite_Item_Title in each Favorites_Tab row SHALL use the Display_Font.
5. WHERE a system-rendered element (tab bar, navigation bar) does not pick up SwiftUI font modifiers, THE App SHALL set the font through appearance configuration in `ThemeAppearance` (UIKit appearance on iOS, and the equivalent on macOS where applicable).
6. THE appearance fix SHALL be verified with simulator screenshots, because unit tests cannot observe it.
7. THE borough section headers in Markets_Tab, including the market count and the chevron next to them, SHALL use the Display_Font at a size that reads as a header (30 pt design size).

### Requirement 5: Body font on everything else
**User Story:** As a user, I want all other text to use the body font, so that the look is consistent.

#### Acceptance Criteria
1. THE Other_Text SHALL use the Body_Font through App_Typography roles.
2. THE search field text and prompt, offline banner, empty and error states, buttons, swipe actions, and detail field labels and values SHALL use the Body_Font.
3. THE App SHALL NOT leave any visible text in the default system font, unless it is a documented fallback or a system-owned element that cannot be styled (to be listed in the PR).

### Requirement 6: Accessibility and readability
**User Story:** As a user with accessibility needs, I want the new fonts to stay usable, so that the theme does not block me.

#### Acceptance Criteria
1. THE text SHALL scale with the user's Dynamic Type setting.
2. VoiceOver labels, values and hints SHALL be unchanged by this feature.
3. THE feature SHALL review the readability of both decorative fonts at small sizes and flag any text that is hard to read, and SHALL state what was done (for example size adjustment or use of the other font).
4. THE feature SHALL NOT claim full accessibility compliance. Manual VoiceOver and expert review remain outside this feature.

### Requirement 7: Layout stays intact
**User Story:** As a user, I want long names and large text sizes to remain readable, so that the new fonts do not break screens.

#### Acceptance Criteria
1. THE Splash_Screen, tab bar labels, navigation titles, Detail_Title and Favorites rows SHALL be checked with long market names and the largest standard Dynamic Type sizes.
2. IF text is truncated or clipped, THEN THE App SHALL show it with wrapping, line limits or scaling that keeps the content reachable, and SHALL NOT hide information that was visible before.
3. THE accessibility identifiers used by existing UI tests SHALL be unchanged.

### Requirement 8: Tests and verification
**User Story:** As the owner of the App, I want automated checks and recorded evidence, so that regressions are caught.

#### Acceptance Criteria
1. THE unit tests (Swift Testing) SHALL verify that both families resolve to the expected PostScript names.
2. THE unit tests SHALL verify that each Title_Role maps to the Display_Font family and each body role maps to the Body_Font family.
3. THE unit tests SHALL verify the fallback to the system font when a font name does not resolve.
4. THE existing unit tests and UI tests (XCTest) SHALL pass.
5. THE iOS and macOS builds SHALL succeed.
6. THE convention grep (no color literals, hex literals, raw SF Symbol names, font-name literals or `.custom(` outside `Theme/`) SHALL pass.
7. THE feature SHALL include iOS simulator screenshots of the Splash_Screen, each tab, the Detail_Sheet and Favorites_Tab with at least one favorite.
8. THE pull request SHALL state what was not verified, expected to include the macOS visual check and visionOS.

## Non-Functional Requirements

1. THE change SHALL follow project conventions: no project file edits for new source files (synchronized groups), colors only from `AppPalette`, icons only from `AppIcon`.
2. Adding the fonts SHALL NOT noticeably slow down app start.
3. Specs for this feature live in `.kiro/specs/custom-fonts-integration/` as `requirements.md`, `design.md` and `tasks.md`.

## Out of Scope

- Changing colors, icons or the wording of texts.
- Re-adding any of the Removed_Fonts.
- Adding a user setting to switch fonts.
- Localization and non-Latin glyph coverage, beyond noting missing glyphs found in the market data.
- Full accessibility audit with assistive technologies.
