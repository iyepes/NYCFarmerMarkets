# Body Font Black Chancery Fix Bugfix Design

## Overview

The owner replaced the body font Breath of the House with Black Chancery (`BLKCHCRY.TTF`, public domain per its embedded copyright). Two defects keep the font from loading, so all body text silently falls back to the system font:

1. `AppTypography.register()` looks up bundled fonts with the case-sensitive extension `ttf`, so `BLKCHCRY.TTF` is never found.
2. `Family.body.postScriptName` is `BLKCHCRY`, but the file embeds `BlackChancery`, so CoreText would not resolve the font even if it were registered.

The fix is small and local. A pure helper picks the URL for a family from a list of URLs, matching the file name case-insensitively. `register()` collects candidate URLs for both `ttf` and `TTF` in the bundle root and the `fonts` subdirectory and uses the helper. The body PostScript name becomes `BlackChancery`. Breath of the House is removed from the bundle, `UIAppFonts` and the repository, and the documents that name the body font are updated. No view, role, size or fallback logic changes.

## Glossary

- **Bug_Condition (C)**: The bundled body font file is `BLKCHCRY.TTF` (uppercase extension) and its embedded PostScript name differs from the one the app expects, so the body family is never registered or reported available.
- **Property (P)**: After `registerFonts()`, the body family is registered from `BLKCHCRY.TTF` regardless of extension case, `isAvailable(postScriptName: "BlackChancery")` is true, and body roles resolve to `.custom(name: "BlackChancery", ...)`.
- **Preservation**: Display family, role sizes, text styles, fallback behavior, logging rules, UIKit font access, identifiers and the body `sizeScale`/`minimumSize` values stay as they are.
- **`AppTypography.register()`**: Private function in `NYCFarmerMarkets/Theme/AppTypography.swift` that finds font files in the bundle, registers them with CoreText and records which families are available.
- **`Family.fileName` / `Family.postScriptName`**: Expected file name and expected embedded PostScript name for a family.
- **`seen`**: Set of file names already registered in this pass; prevents registering one file twice and drives the "missing" log.
- **`fontURL(named:in:)`**: New pure helper (name chosen in this design) that picks the URL whose last path component equals a file name, ignoring case.

## Bug Details

### Bug Condition

The bug manifests at launch, when `register()` runs. `Bundle.main.urls(forResourcesWithExtension: "ttf", ...)` does not return `BLKCHCRY.TTF`, and `urls.first(where: { $0.lastPathComponent == family.fileName })` compares names case-sensitively. The body family is therefore logged as "Font file missing from bundle". Independently, `isAvailable(postScriptName: "BLKCHCRY")` fails because CoreText knows the font as `BlackChancery`.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type BundleFontSetup { fileName: String, embeddedPostScriptName: String,
                                         expectedPostScriptName: String }
  OUTPUT: boolean

  RETURN fileExtension(input.fileName) != "ttf"            // e.g. "TTF": case-sensitive lookup misses it
         OR input.embeddedPostScriptName != input.expectedPostScriptName
END FUNCTION
```

For the current setup, `{ "BLKCHCRY.TTF", "BlackChancery", "BLKCHCRY" }` satisfies both disjuncts.

### Examples

- Launch with `BLKCHCRY.TTF` in the bundle: expected, the file is found and registered; actual, log "Font file missing from bundle: BLKCHCRY.TTF".
- Same launch, even if the file were registered: expected, `isAvailable("BlackChancery")` is true; actual, `isAvailable("BLKCHCRY")` is false and the log says "Font not available: BLKCHCRY".
- `Text("Farmers Market").appFont(.body)`: expected, Black Chancery; actual, system font with `.body` style and `.regular` weight.
- A file named `Grim Creeper.ttf` (lowercase extension): found today and must still be found (not a bug case; preserved).
- Bundle without any body font file: expected, family unavailable, system fallback, error logged (preserved).
- Build output: expected, no `Breath of the House.ttf`; actual, it is still bundled and listed in `UIAppFonts`.

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Grim Creeper (`Grim-Creeper-Regular`, `Grim Creeper.ttf`) registers and draws all display roles (3.1).
- Every role keeps its family, design size, text style, fallback weight and Dynamic Type scaling (3.2).
- A missing or unavailable family still falls back to the system font with the role's text style and fallback weight (3.3).
- Failures are still logged with `Logger` and explicit privacy; "already registered" and "duplicated name" errors are still not errors; no `print` (3.4).
- UIKit bars still get fonts from `AppTypography.uiFont` with the same sizes and caps (3.5).
- Body `sizeScale` 1.15 and the 14 pt floor keep their values; an on-screen review of Black Chancery may change them later, but not in this fix (3.6).
- Composed text still uses ", " as separator (3.7).
- Accessibility identifiers stay the same and all other tests keep passing (3.8).

**Scope:**
All inputs where the font file has a lowercase `ttf` extension and the embedded PostScript name matches the expected one behave exactly as before. This includes:
- Display family registration and resolution.
- Role-to-`Resolved` mapping for any availability set.
- System fallback when a family is unavailable.

## Hypothesized Root Cause

1. **Case-sensitive resource lookup (confirmed by the owner's file name)**: `urls(forResourcesWithExtension: "ttf", ...)` and `lastPathComponent == family.fileName` are both case-sensitive in intent. The owner's file keeps its original name `BLKCHCRY.TTF`, so it is skipped. Whether the first call matches `.TTF` on a case-insensitive volume is not guaranteed, and the exact comparison on `lastPathComponent` is case-sensitive in any case.
2. **Wrong expected PostScript name (confirmed from the font's name table)**: The code assumed the file name (`BLKCHCRY`) is also the PostScript name. The font embeds `BlackChancery`. `isAvailable` requires an exact match, so any other string reports unavailable.
3. **Leftover Breath of the House references**: The old font file, its `UIAppFonts` entry and its mentions in docs were never removed. This is a cleanup defect, not a code-path defect.
4. **Not a cause, to be ruled out**: `UIAppFonts` already lists `BLKCHCRY.TTF` (per the requirements, it must list exactly two files after the fix). The `fonts` subdirectory search and the `seen` de-duplication are correct and stay.

## Correctness Properties

Property 1: Bug Condition - Black Chancery registers and resolves

_For any_ bundle font setup where the bug condition holds (the body file has an extension in any letter case, such as `.TTF`, or the embedded PostScript name was previously mismatched), the fixed `register()` SHALL find the file in the bundle root or the `fonts` subdirectory, register it, report the body family as available under the PostScript name `BlackChancery`, and resolve every body role to `.custom(name: "BlackChancery", ...)` without logging "Font file missing" or "Font not available" for it; and the built app SHALL NOT contain or reference Breath of the House.

**Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5**

Property 2: Preservation - Everything outside the font lookup is unchanged

_For any_ input where the bug condition does NOT hold (lowercase `ttf` display font, any role, any availability set, any missing font), the fixed code SHALL produce the same result as the original code, preserving display font registration, role size/style/weight/scaling, system fallback, logging rules, UIKit font access, the body `sizeScale` and `minimumSize` values, ", " separators and accessibility identifiers.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8**

## Fix Implementation

### Changes Required

**File**: `NYCFarmerMarkets/Theme/AppTypography.swift`

**Specific Changes**:
1. **PostScript name**: `Family.body.postScriptName` returns `"BlackChancery"`. `fileName` stays `"BLKCHCRY.TTF"` (the owner's file name).
2. **Pure lookup helper**: add a `nonisolated static func fontURL(named fileName: String, in urls: [URL]) -> URL?` that returns the first URL whose `lastPathComponent` equals `fileName` under `caseInsensitiveCompare(_:) == .orderedSame`, or `nil`. It takes no bundle, so tests can call it with synthetic URLs. It is `internal` (not `private`) so `@testable import` reaches it.
3. **Candidate URLs in `register()`**: build the list from `Bundle.main.urls(forResourcesWithExtension:subdirectory:)` for each extension in `["ttf", "TTF"]` and each subdirectory in `[nil, "fonts"]`, then drop duplicate paths (`standardizedFileURL.path`) so a case-insensitive volume does not yield the same file twice. Replace `urls.first(where: { $0.lastPathComponent == family.fileName })` with `fontURL(named: family.fileName, in: urls)`. Keep `seen`, the registration call, the error-code handling and the log messages unchanged.
4. **Doc comments**: `Family.body` says "Black Chancery (public domain): all other text". The `sizeScale` comment no longer claims Breath's small x-height. It says the 1.15 scale and 14 pt floor are carried over from the previous body font and are an open on-screen check for Black Chancery. Values stay 1.15 and 14.
5. **No other source change**: `resolvedFont`, `Role`, `AppTypography+UIKit.swift` and all views are untouched.

**File**: `NYCFarmerMarkets/Info.plist`
- `UIAppFonts` is exactly `Grim Creeper.ttf`, `BLKCHCRY.TTF`, in that order. Check with `plutil -lint`.

**File**: `NYCFarmerMarkets/fonts/Breath of the House.ttf`
- Delete (owner approved). Any `rm` shows the full literal path: `/Users/isabelyepes/Documents/XCode/NYCFarmerMarkets/NYCFarmerMarkets/fonts/Breath of the House.ttf`. Stage the deletion by name when the owner asks for a commit.

**Documents** (Breath removed or replaced; wiki files out of scope):
- `.kiro/steering/theme-conventions.md`: body family line names Black Chancery (`BlackChancery`, file `BLKCHCRY.TTF`, public domain). The font convention grep pattern becomes `Grim|Chancery|BLKCHCRY|\.ttf` with `-i` (so `.TTF` also matches): `grep -rniE 'Grim|Chancery|BLKCHCRY|\.ttf' NYCFarmerMarkets --include='*.swift' | grep -v '^NYCFarmerMarkets/Theme/' || true`. It must still print zero lines.
- `.kiro/steering/tech.md`: the `fonts/` line lists `Grim Creeper.ttf` and `BLKCHCRY.TTF`; the `AppTypography.registerFonts()` mention stays.
- `.kiro/steering/known-limits.md`: remove the Breath license entry; replace the Breath screen-review entries with Black Chancery ones (size scale and floor, x-height and legibility at small sizes, glyph coverage such as digits and punctuation used in addresses, Dynamic Type at the largest sizes); note that the embedded copyright states public domain. Update the entry that says the workflow font pattern is still `Grim|N8ghtmare|Caligari|\.ttf` once that is fixed.
- `.kiro/workflows/feature-to-pr.workflow.json`: find the font-name pattern with `grep -n 'N8ghtmare' .kiro/workflows/feature-to-pr.workflow.json`, change it to `Grim|Chancery|BLKCHCRY|\.ttf` (case-insensitive flag if the surrounding command is a `grep`), and keep the JSON valid (escape backslashes as the file already does; check with `plutil -lint` or `python3 -m json.tool`).
- `.kiro/specs/custom-fonts-integration/design.md`: dated "Amendment 3 (2026-11-20)" section covering the body font change, the PostScript name, the case-insensitive lookup and the Breath removal. Add a short dated note in its `requirements.md` and `tasks.md` where they name Breath, without rewriting history.
- `Design/design-changes.md`: new entry for the body font change, naming `fonts-licensing/`.
- `fonts-licensing/` (owner-provided, already in the working tree): keeps `BLACKCHA.txt` and `Grim Creeper Font Info and Read Me - Sinister Fonts.txt` unchanged. `known-limits.md`, `tech.md` (repo layout note), `Design/design-changes.md` and the custom-fonts-integration Amendment 3 point to it as the source of each font's license. The custom-fonts-integration requirement on paid or redistribution-limited fonts is met: Black Chancery is public domain and Grim Creeper is free with its read me included. The folder sits outside `NYCFarmerMarkets/`, so the file-system-synchronized group does not bundle it.

## Testing Strategy

### Validation Approach

First surface counterexamples on unfixed code, then verify the fix and preservation. All unit tests use Swift Testing in `NYCFarmerMarketsTests/AppTypographyTests.swift` (one file per type). The real bundle check is `bothFamiliesResolveAfterRegistration`.

### Exploratory Bug Condition Checking

**Goal**: Confirm both root causes before changing code.

**Test Plan**: Before the fix, run `bothFamiliesResolveAfterRegistration` and the post-script-name test (updated to expect `BlackChancery`) against the unfixed code, and read the `typography` log for the test run.

**Test Cases**:
1. **Bundle registration test**: `bothFamiliesResolveAfterRegistration` after `registerFonts()` (will fail on unfixed code: body family missing).
2. **PostScript name test**: `postScriptNames` expects `"Grim-Creeper-Regular"` and `"BlackChancery"` (will fail on unfixed code: returns `BLKCHCRY`).
3. **Lookup helper test with `BLKCHCRY.TTF`**: cannot compile before the helper exists; its absence confirms cause 1 at the code level.
4. **CoreText name check**: confirm `CTFontCreateWithName("BlackChancery", 12, nil)` returns that PostScript name once the file is registered (confirms cause 2; may fail on unfixed code because nothing registers the file).

**Expected Counterexamples**:
- "Font file missing from bundle: BLKCHCRY.TTF" and "Font not available: BLKCHCRY" in the log.
- Possible causes: case-sensitive extension lookup, wrong expected PostScript name.

### Fix Checking

**Goal**: For all inputs where the bug condition holds, the fixed code gives the expected behavior.

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  result := register_fixed(input)
  ASSERT Family.body IN result.availableFamilies
     AND resolvedFont(.body, available) == .custom("BlackChancery", size, style)
     AND NOT logged("Font file missing from bundle: BLKCHCRY.TTF")
END FOR
```

### Preservation Checking

**Goal**: For all inputs where the bug condition does NOT hold, the fixed code gives the same result as the original.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT register_original(input) = register_fixed(input)
END FOR
```

**Testing Approach**: Property-style checks over the finite input domain are enough here (all `Role` and `Family` cases via `CaseIterable`, both availability outcomes). The existing exhaustive role tests already cover this and must pass unchanged.

**Test Plan**: Run the existing `AppTypographyTests` on unfixed code to record the baseline (display family and role mapping pass), then confirm the same tests pass after the fix.

**Test Cases**:
1. **Display family preservation**: `Grim Creeper.ttf` still found and `Grim-Creeper-Regular` available.
2. **Role mapping preservation**: size, text style, fallback weight and `effectiveSize` for every `Role` (body values still 1.15 scale, 14 pt floor).
3. **Fallback preservation**: `resolvedFont` returns `.system(style, weight)` when a family is unavailable.

### Unit Tests

- `postScriptNames`: display `Grim-Creeper-Regular`, body `BlackChancery`.
- `fontURL` finds an uppercase `.TTF` file: `fontURL(named: "BLKCHCRY.TTF", in: [URL(fileURLWithPath: "/x/BLKCHCRY.TTF")])` is non-nil.
- `fontURL` finds a lowercase `.ttf` file for the same logical name (`/x/blkchcry.ttf`) and for `Grim Creeper.ttf`.
- `fontURL` returns `nil` when the name is absent (empty list, or only `Other.ttf`).
- `fontURL` picks the right file from a mixed list that includes both families.

### Property-Based Tests

- For every `Family`, upper-casing or lower-casing the file name in the URL still yields a match from `fontURL` (loop over `Family.allCases` and both case transforms).
- For every `Role` and both availability outcomes, `resolvedFont` returns `.custom` with the family's PostScript name and `effectiveSize`, or `.system` with the role's style and fallback weight.
- No project property-testing library is used; Swift Testing parameterized tests (`@Test(arguments:)`) cover these without a new dependency.

### Integration Tests

- `bothFamiliesResolveAfterRegistration`: after `registerFonts()`, both families are in `availableFamilies` using the real app bundle in the test host.
- Build checks: iOS and macOS builds succeed; `plutil -lint NYCFarmerMarkets/Info.plist` passes and `UIAppFonts` has exactly the two entries; the built `.app` contains `BLKCHCRY.TTF` and does not contain `Breath of the House.ttf` (`find` in the derived data product for the iOS build and for the macOS build).
- Unit test run: `-only-testing:NYCFarmerMarketsTests` on the iOS command passes; UI tests are not required because no identifier or layout changes.
- Theme convention check from `theme-conventions.md` prints zero lines with the new pattern.
- JSON check of `.kiro/workflows/feature-to-pr.workflow.json` after the pattern edit.
- `fonts-licensing/` holds both notices, and neither the iOS nor the macOS `.app` contains `BLACKCHA.txt` or the Grim Creeper read me.
- Not verified by this fix: how Black Chancery looks on screen at the scaled sizes and at large Dynamic Type; that stays as the open on-screen check recorded in `known-limits.md`.
