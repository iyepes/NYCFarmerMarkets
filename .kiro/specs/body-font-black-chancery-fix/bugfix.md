# Bugfix Requirements Document

## Introduction

The owner replaced the body font Breath of the House with Black Chancery (`BLKCHCRY.TTF`) for licensing reasons. The build does not find the new font file, and all body text silently falls back to the system font. Two defects cause this. The runtime looks for bundled fonts by a case-sensitive `ttf` extension, so the uppercase `.TTF` file is never found. Separately, the app expects the PostScript name `BLKCHCRY`, but the font file embeds the PostScript name `BlackChancery`, so the font would still not resolve if it were registered.

The owner also decided to remove Breath of the House completely, so it is no longer bundled or published in the public repository, and to update the documents that name the body font. The font's embedded copyright states it is public domain ("From Doug Miles' Black Chancery bitmap font. Outlines by Earl Allen & Doug Miles. Public domain."). The owner added the font notices to a new root folder `fonts-licensing/`: `BLACKCHA.txt` (Black Chancery, public domain) and `Grim Creeper Font Info and Read Me - Sinister Fonts.txt` (Grim Creeper, free for personal and commercial use; the author asks that the read me be included wherever the font is offered for download). The folder is outside `NYCFarmerMarkets/`, so it is not bundled into the app.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN the app registers fonts at launch and the bundled body font file has an uppercase extension (`BLKCHCRY.TTF`) THEN the system does not find the file, logs "Font file missing from bundle: BLKCHCRY.TTF", and does not register the font.

1.2 WHEN the body family is checked for availability and the app expects the PostScript name `BLKCHCRY` but the font file's embedded PostScript name is `BlackChancery` THEN the system reports the body family as unavailable, even if the file had been registered.

1.3 WHEN any body-role text is drawn (body, bodyEmphasis, subheadline, caption, footnote) THEN the system silently shows it in the system font instead of Black Chancery.

1.4 WHEN the app is built and run THEN the system still bundles `Breath of the House.ttf` and lists it in `UIAppFonts`, so the font that was replaced for licensing reasons stays in the app and in the public repository.

1.5 WHEN a developer reads the theme conventions, tech notes, known limits, the custom-fonts-integration spec or the design changes log THEN the system shows Breath of the House as the body font, and the doc comments in `AppTypography` do the same.

### Expected Behavior (Correct)

2.1 WHEN the app registers fonts at launch and the bundled body font file is `BLKCHCRY.TTF` THEN the system SHALL find the file regardless of the case of its extension (`.ttf` or `.TTF`), in the bundle root or the `fonts` subdirectory, and register it.

2.2 WHEN the body family is checked for availability THEN the system SHALL use the font's real embedded PostScript name (`BlackChancery`) so that CoreText resolves it and the body family is reported as available after registration.

2.3 WHEN any body-role text is drawn and the body font is registered THEN the system SHALL show it in Black Chancery, with no "Font file missing" or "Font not available" log entry for it.

2.4 WHEN the app is built THEN the system SHALL NOT bundle or reference Breath of the House: `NYCFarmerMarkets/fonts/Breath of the House.ttf` is deleted and `UIAppFonts` lists exactly `Grim Creeper.ttf` and `BLKCHCRY.TTF`.

2.5 WHEN a developer reads the documents that name the body font THEN the system SHALL name Black Chancery (PostScript name `BlackChancery`, file `BLKCHCRY.TTF`, public-domain note) in `.kiro/steering/theme-conventions.md` (body family line and the convention grep pattern, which no longer matches `Breath`), `.kiro/steering/tech.md` (fonts line), `.kiro/steering/known-limits.md` (Breath license and screen-review entries replaced by Black Chancery equivalents), `Design/design-changes.md`, and a dated "Amendment" section in the custom-fonts-integration spec, and the `AppTypography` doc comments SHALL say Black Chancery. Wiki files are out of scope.

2.6 WHEN a developer looks for the license of a bundled font THEN the system SHALL point to `fonts-licensing/` from `.kiro/steering/known-limits.md`, `.kiro/steering/tech.md`, `Design/design-changes.md` and the custom-fonts-integration amendment, and `fonts-licensing/` SHALL hold one notice per bundled font (`BLACKCHA.txt`, `Grim Creeper Font Info and Read Me - Sinister Fonts.txt`) and SHALL NOT be bundled into the app.

### Unchanged Behavior (Regression Prevention)

3.1 WHEN the display family (Grim Creeper, `Grim-Creeper-Regular`, `Grim Creeper.ttf`) is registered and used THEN the system SHALL CONTINUE TO register it and draw all display roles with it.

3.2 WHEN any role is resolved THEN the system SHALL CONTINUE TO use the same family, design size, text style and fallback weight for that role, and SHALL CONTINUE TO scale with Dynamic Type.

3.3 WHEN a family's font is missing or unavailable THEN the system SHALL CONTINUE TO fall back to the system font with the role's text style and fallback weight.

3.4 WHEN a font fails to register or is missing THEN the system SHALL CONTINUE TO log the problem with `Logger` using explicit privacy, never `print`, and SHALL CONTINUE TO treat "already registered" errors as not an error.

3.5 WHEN UIKit bars (tab bar, navigation bar, search field) need fonts THEN the system SHALL CONTINUE TO get them through `AppTypography.uiFont` with the same sizes and caps.

3.6 WHEN body text is drawn THEN the system SHALL CONTINUE TO apply the body `sizeScale` (1.15) and 14 pt floor unless on-screen review of Black Chancery shows they need changing; this is an open on-screen check, not a decided change.

3.7 WHEN rows compose text THEN the system SHALL CONTINUE TO separate parts with ", " (Black Chancery has no "·" glyph, so no change is needed).

3.8 WHEN UI tests and unit tests run THEN the system SHALL CONTINUE TO find elements by the existing accessibility identifiers, and all other tests SHALL CONTINUE TO pass; the `AppTypographyTests` post-script-name test expects `BlackChancery` for the body family.
