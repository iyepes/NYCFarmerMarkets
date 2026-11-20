# Implementation Plan

Constraints for every task: work on branch `fix/body-font-black-chancery`, do not edit `project.pbxproj`, do not stage or commit anything (the owner approves commits), do not touch wiki files or `.agents/`. Run all commands from the repo root `/Users/isabelyepes/Documents/XCode/NYCFarmerMarkets`.

- [x] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** - Black Chancery registers and resolves
  - **CRITICAL**: This test MUST FAIL on unfixed code. Failure confirms the bug exists.
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior and validates the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that show the bug exists
  - **Scoped PBT Approach**: The bug is deterministic, so scope the property to the concrete failing setup `{ fileName: "BLKCHCRY.TTF", embeddedPostScriptName: "BlackChancery", expectedPostScriptName: "BLKCHCRY" }`
  - In `NYCFarmerMarketsTests/AppTypographyTests.swift`, update the `postScriptNames` test to expect `"Grim-Creeper-Regular"` for the display family and `"BlackChancery"` for the body family
  - Confirm `bothFamiliesResolveAfterRegistration` calls `AppTypography.registerFonts()` and asserts both families are in `availableFamilies` with the real app bundle; add that test if it is missing
  - Add a test that every body `Role` resolves to `.custom(name: "BlackChancery", ...)` through `resolvedFont` once the body family is available
  - Do not write the `fontURL(named:in:)` tests yet. The helper does not exist on unfixed code, and its absence already confirms root cause 1
  - Run on UNFIXED code: `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/dd-fonts test -only-testing:NYCFarmerMarketsTests/AppTypographyTests`
  - **EXPECTED OUTCOME**: Tests FAIL (this is correct and proves the bug exists)
  - Document counterexamples, for example `postScriptName` returns `BLKCHCRY` instead of `BlackChancery`, and the log shows "Font file missing from bundle: BLKCHCRY.TTF" and "Font not available: BLKCHCRY"
  - Mark the task complete when the tests are written, run, and the failure is documented
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3_

- [x] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Everything outside the font lookup is unchanged
  - **IMPORTANT**: Follow observation-first methodology
  - Observe on UNFIXED code, for inputs where the bug condition is false (lowercase `ttf` display font, any role, any availability set, any missing font):
    - `Grim Creeper.ttf` is found and `Grim-Creeper-Regular` is available after `registerFonts()`
    - Every `Role` keeps its family, design size, text style, fallback weight and `effectiveSize` (body `sizeScale` 1.15, `minimumSize` 14)
    - `resolvedFont` returns `.system(style, weight)` when a family is unavailable
  - Write or extend Swift Testing parameterized tests (`@Test(arguments:)` over `Role.allCases`, `Family.allCases` and both availability outcomes, no new dependency) in `NYCFarmerMarketsTests/AppTypographyTests.swift` that assert those observed values
  - Keep these tests independent of the body PostScript name, so they pass on both unfixed and fixed code
  - Run on UNFIXED code with the same command as task 1
  - **EXPECTED OUTCOME**: The preservation tests PASS (this confirms the baseline behavior to preserve). The task 1 tests still fail.
  - Mark the task complete when the tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8_

- [x] 3. Fix for body font Black Chancery not loading and Breath of the House removal

  - [x] 3.1 Fix font lookup and PostScript name in `AppTypography`
    - In `NYCFarmerMarkets/Theme/AppTypography.swift`, change `Family.body.postScriptName` to `"BlackChancery"`. `fileName` stays `"BLKCHCRY.TTF"`.
    - Add `nonisolated static func fontURL(named fileName: String, in urls: [URL]) -> URL?`. It is `internal`, takes no bundle, and returns the first URL whose `lastPathComponent` equals `fileName` under `caseInsensitiveCompare(_:) == .orderedSame`, or `nil`.
    - In `register()`, collect candidate URLs from `Bundle.main.urls(forResourcesWithExtension:subdirectory:)` for each extension in `["ttf", "TTF"]` and each subdirectory in `[nil, "fonts"]`. Drop duplicate paths by `standardizedFileURL.path`. Replace the `urls.first(where: { $0.lastPathComponent == family.fileName })` lookup with `fontURL(named: family.fileName, in: urls)`.
    - Keep `seen`, the registration call, the "already registered" and "duplicated name" handling, and the log messages unchanged. Use `Logger` with explicit privacy and no `print`.
    - Update the doc comments: `Family.body` says "Black Chancery (public domain): all other text". The `sizeScale` comment says the 1.15 scale and 14 pt floor are carried over from the previous body font and are an open on-screen check for Black Chancery. The values stay 1.15 and 14.
    - Do not change `resolvedFont`, `Role`, `AppTypography+UIKit.swift` or any view.
    - Add unit tests for `fontURL` in `NYCFarmerMarketsTests/AppTypographyTests.swift` using synthetic URLs:
      - finds `/x/BLKCHCRY.TTF` for `"BLKCHCRY.TTF"`
      - finds `/x/blkchcry.ttf` for the same logical name, and finds `Grim Creeper.ttf`
      - returns `nil` for an empty list and for a list holding only `Other.ttf`
      - picks the right file from a mixed list containing both families
      - parameterized over `Family.allCases` and both upper-case and lower-case file names
    - _Bug_Condition: isBugCondition(input) where fileExtension(input.fileName) != "ttf" OR input.embeddedPostScriptName != input.expectedPostScriptName_
    - _Expected_Behavior: body family registered from `BLKCHCRY.TTF` in any extension case, `isAvailable(postScriptName: "BlackChancery")` true, body roles resolve to `.custom(name: "BlackChancery", ...)` with no "Font file missing" or "Font not available" log entry_
    - _Preservation: display family, role size/style/weight/scaling, system fallback, logging rules, UIKit font access, `sizeScale` 1.15 and `minimumSize` 14 unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

  - [x] 3.2 Remove Breath of the House from the bundle and `UIAppFonts`
    - Check `NYCFarmerMarkets/Info.plist` and set `UIAppFonts` to exactly `Grim Creeper.ttf` and `BLKCHCRY.TTF`, in that order. Remove any Breath of the House entry.
    - State the exact path, then delete the file with this literal command: `rm "/Users/isabelyepes/Documents/XCode/NYCFarmerMarkets/NYCFarmerMarkets/fonts/Breath of the House.ttf"`
    - Do not edit `project.pbxproj` (file-system-synchronized groups pick up the deletion). Do not stage the deletion. The owner stages it when approving a commit.
    - Run `grep -rn "Breath" NYCFarmerMarkets NYCFarmerMarketsTests NYCFarmerMarketsUITests` and confirm no remaining reference outside intentionally dated amendment notes
    - _Requirements: 1.4, 2.4_

  - [x] 3.3 Update the documents that name the body font
    - `.kiro/steering/theme-conventions.md`: the body family line names Black Chancery (`BlackChancery`, file `BLKCHCRY.TTF`, public domain). Replace the font convention grep with `grep -rniE 'Grim|Chancery|BLKCHCRY|\.ttf' NYCFarmerMarkets --include='*.swift' | grep -v '^NYCFarmerMarkets/Theme/' || true`. It must print zero lines.
    - `.kiro/steering/tech.md`: the `fonts/` line lists `Grim Creeper.ttf` and `BLKCHCRY.TTF`. Keep the `AppTypography.registerFonts()` mention.
    - `.kiro/steering/known-limits.md`: remove the Breath license entry. Replace the Breath screen-review entries with Black Chancery ones (size scale and 14 pt floor, x-height and legibility at small sizes, glyph coverage for digits and punctuation used in addresses, Dynamic Type at the largest sizes). Note that the embedded copyright states public domain. Update the entry about the workflow font pattern once it is fixed.
    - `.kiro/workflows/feature-to-pr.workflow.json`: run `grep -n 'N8ghtmare' .kiro/workflows/feature-to-pr.workflow.json`, change the pattern to `Grim|Chancery|BLKCHCRY|\.ttf` (add the case-insensitive flag if the surrounding command is a `grep`), keep the existing backslash escaping, and confirm the file is still valid JSON.
    - `.kiro/specs/custom-fonts-integration/design.md`: add a dated "Amendment 3 (2026-11-20)" section covering the body font change, the PostScript name, the case-insensitive lookup and the Breath removal. Add a short dated note to its `requirements.md` and `tasks.md` where they name Breath, without rewriting history.
    - `Design/design-changes.md`: add an entry for the body font change that names `fonts-licensing/`.
    - `fonts-licensing/`: do not edit the two owner-provided notices (`BLACKCHA.txt`, `Grim Creeper Font Info and Read Me - Sinister Fonts.txt`). Point to the folder as the license source in `known-limits.md` (font license entries), `tech.md` (one line in the layout notes: root `fonts-licensing/` holds one notice per bundled font and is not bundled), `Design/design-changes.md` and the custom-fonts-integration Amendment 3, which also records that its paid-or-limited-font requirement is met.
    - Do not touch wiki files or `.agents/`.
    - _Requirements: 1.5, 2.5, 2.6_

  - [x] 3.4 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - Black Chancery registers and resolves
    - **IMPORTANT**: Re-run the SAME tests from task 1. Do NOT write new tests for this step.
    - The task 1 tests encode the expected behavior. When they pass, the expected behavior is satisfied.
    - Run: `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/dd-fonts test -only-testing:NYCFarmerMarketsTests/AppTypographyTests`
    - **EXPECTED OUTCOME**: Tests PASS (confirms the bug is fixed), including the new `fontURL` tests from 3.1
    - _Requirements: 2.1, 2.2, 2.3_

  - [x] 3.5 Verify preservation tests still pass
    - **Property 2: Preservation** - Everything outside the font lookup is unchanged
    - **IMPORTANT**: Re-run the SAME tests from task 2. Do NOT write new tests.
    - Run the same command as 3.4
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8_

- [x] 4. Checkpoint - Final verification
  - Run each check below from the repo root and record the result. Ask the user if any question arises.
  - iOS build: `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/dd-fonts build`
  - macOS build: `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination 'platform=macOS' -derivedDataPath /tmp/ddmac build`
  - iOS unit tests: `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/dd-fonts test -only-testing:NYCFarmerMarketsTests` (if it fails with a transient xctrunner launch error, re-run once)
  - macOS unit tests: `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination 'platform=macOS' -derivedDataPath /tmp/ddmac test -only-testing:NYCFarmerMarketsTests`
  - Theme convention check prints zero lines: `grep -rniE 'Grim|Chancery|BLKCHCRY|\.ttf' NYCFarmerMarkets --include='*.swift' | grep -v '^NYCFarmerMarkets/Theme/' || true`
  - Info.plist is valid: `plutil -lint NYCFarmerMarkets/Info.plist`
  - The built iOS `.app` under `/tmp/dd-fonts` contains `BLKCHCRY.TTF` and does not contain `Breath of the House.ttf` (use `find` with quoted names). Check the macOS `.app` under `/tmp/ddmac` the same way.
  - `fonts-licensing/` contains `BLACKCHA.txt` and `Grim Creeper Font Info and Read Me - Sinister Fonts.txt`, neither built `.app` contains them, and `grep -n 'fonts-licensing' .kiro/steering/known-limits.md .kiro/steering/tech.md Design/design-changes.md .kiro/specs/custom-fonts-integration/design.md` finds each file
  - The workflow JSON is valid: `python3 -m json.tool .kiro/workflows/feature-to-pr.workflow.json > /dev/null`
  - Confirm `git status` shows no change to `project.pbxproj`, wiki files or `.agents/`, and that nothing is staged
  - Remove any temporary files created, stating each literal path before deleting
  - Ensure all tests pass
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8_

- [ ] 5. Owner-only: review Black Chancery on screen (not for the agent)
  - The owner reviews Black Chancery in the running app, including the body `sizeScale` of 1.15 and the 14 pt floor, small-size legibility, glyph coverage in addresses, and Dynamic Type at the largest sizes
  - The owner decides whether the scale or floor change. Any change is a separate follow-up, not part of this fix.
  - The agent must not mark this task complete or change the values
  - _Requirements: 3.6_
