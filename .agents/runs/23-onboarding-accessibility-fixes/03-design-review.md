# Design review: Onboarding accessibility fixes (issue #23), revision 2

Reviewed: `02-design.md` (revision 2) against `01-requirements.md` and the source in `NYCFarmerMarkets/`. This follows the prior review (3 MEDIUM, 5 NIT).

Verdict: CHANGES_REQUESTED (0 HIGH, 2 MEDIUM, 3 NIT).

## Status of the previous findings

| # | Previous finding | Status |
|---|---|---|
| 1 | MEDIUM, 3 pt is not "half" | Closed in substance (option (c) with a clearance rule). New problems in findings 1 and 2 below. |
| 2 | MEDIUM, fixed Skip height | Closed. Skip is measured with `onGeometryChange` and the rule falls back below Skip. |
| 3 | MEDIUM, adjust UI test | Closed. Success and no-op criteria are defined and the spike is flagged as unverified. See finding 5 for one remaining risk. |
| 4 | NIT, largest size | Closed (`accessibility-extra-extra-extra-large`). |
| 5 | NIT, indicator `contentShape` | Closed (removed). |
| 6 | NIT, Next fallback | Closed (section 2). |
| 7 | NIT, `plainStrings` | Closed. |
| 8 | NIT, copy test and id/index | Closed. |

## Findings

### 1. MEDIUM: Requirements still say "half"; the design departs from them and its owner approval cannot be traced
Where: design section 3 ("Owner decision: option (c)"); `01-requirements.md` AC 4.1, AC 4.2, Out of Scope ("Changing ... images").
`01-requirements.md` is unchanged. AC 4.1 still says the space "SHALL be half of its current value". The design delivers 67 pt instead of 53.5 pt (a 37% reduction, not 50%). It also shrinks the Hero from 220 to 190 pt and moves the emoji, which is a visual change to the images block. The design says the owner chose this and that "the amendment" restates AC 4.1. The amendment is written later by the record_spec step, so the coder, the test step and the PR reviewer would work from requirements that contradict the design. The original user request in this run contains no message that records the choice of option (c).
Fix: (1) Edit AC 4.1 in `01-requirements.md` to "the Hero top is at safe-area top + 8 pt when it clears Skip horizontally (about 40 pt higher on a 393 pt screen at the default text size), otherwise below Skip", and AC 4.3 to include the 190 pt / 160 pt sizes and the emoji move. (2) Add one line to the design quoting where the owner made the choice (message or issue comment). If there is no such record, change the design to ask the owner before coding.

### 2. MEDIUM: The clearance rule fails on common 375 pt iPhones and is sensitive to the estimated Skip width
Where: design section 3, "Clearance rule" numbers.
The design checks 393 pt (rises) and 320 pt (falls back). 320 pt is not a device this app runs on (iOS 26.5 supports iPhone 11 and later; the narrowest is 375 pt: SE 2/3, 12/13 mini). Using the design's own formula with Skip width 70, side gap 4, hero 190:
- 375 pt: right edge 187.5 + 95 + 4 = 286.5; Skip left = 375 - 24 - 70 = 281. 286.5 > 281, so the Hero falls back to `safe + 8 + 34 + 3`. On those devices the reduction is about 3 pt, not 40 pt.
- 390 pt: 195 + 95 + 4 = 294; Skip left = 296. It rises, with 2 pt of slack. A Skip width of 73 pt flips it.
The bounding-box test is also conservative: the Hero is a circle (illustration, fallback), so at Skip's bottom edge (34 pt below the Hero top) the circle's half-width is only about 73 pt, not 95. The design's "report it rather than shrinking the Hero further" leaves the owner's goal undelivered on the narrowest supported phones, and the unit-test values (393 and 320) hide it.
Fix: pick one and state the numbers: (a) accept the fallback at 375 pt and say so in the AC and PR, adding a 375 pt case to `OnboardingHeroLayoutTests` (expected `safe + 45`); or (b) make the rule shape-aware: add a `heroCornerRadius` input (`heroWidth / 2` for circles, 32 for the framed style) and compute the Hero's horizontal extent at Skip's bottom edge, which gives clearance at 375 pt. In both cases add 375 pt and 390 pt cases to the tests, and make `sideGap` a tested constant rather than a screenshot-tuned value.

### 3. NIT: Stale and inconsistent names
Where: design sections 1, 3, "Error handling".
The hero size constant is called `heroSize`, `Layout.heroSize`, `Layout.heroFallbackSize` and `Layout.heroWidth` in different places. `OnboardingPageView` has no `Layout` enum today, and `OnboardingView.Layout` is `private`. "Error handling" still refers to `skipHeight` and a "default 34", but the state is `skipSize` with `Layout.defaultSkipSize`.
Fix: name one constant, for example `OnboardingPageView.heroSize` (190) and `OnboardingPageView.heroFallbackSize` (160), read by `OnboardingView` as `OnboardingPageView.heroSize`. Replace `skipHeight` with `skipSize` in "Error handling".

### 4. NIT: Fallback for the adjust test needs a decision path inside the code step
Where: design "Testing", spike paragraph.
"The coder reports the spike result to the orchestrator" and the AC 6.2 amendment "needs approval", but the code step has no stated pause.
Fix: state that on spike failure the coder sends a `warning` message and waits, and does not edit AC 6.2 itself.

### 5. NIT: XCUITest `adjust(toNormalizedSliderPosition:)` probably rejects this element
Where: design `testPageIndicatorAdjustActions`.
XCTest parses the element value as a slider percentage before adjusting. The value "Page 1 of 3" is likely not parseable, so the call can fail even with a correct view. The design already marks the approach unverified, so this only sharpens the expected spike outcome.
Fix: say in the design that failure with a message about the slider value is the expected result of the spike and goes straight to the AC 6.2 fallback, not to view changes.

## Verified Assumptions
- `OnboardingView.bottomControls` has 8 pt dots, 8 pt spacing, 14/10 pt padding, `.accessibilityElement(children: .ignore)`, the text "Page N of M" as a label, and identifier `onboarding-page-indicator`. No value or adjustable action exists (source read).
- The Next label has `.glassEffect` inside the label under `.buttonStyle(.plain)` and no `contentShape`.
- `Layout` is a private enum in `OnboardingView` with `skipAreaHeight = 48` and `controlsAreaHeight = 150`. `topInset` feeds `.contentMargins(.top, ...)` for all pages.
- `OnboardingPageView` hero sizes are 220 (illustration, framed) and 180 (fallback); the ZStack alignment is `.topTrailing`; the emoji uses `.appFont(.splash)`.
- Skip stays laid out on the last page (`opacity(0)`, `disabled`, `accessibilityHidden`), so its measured size remains available.
- `AppCopy.onboardingPageIndicator(page:count:)` returns "Page N of M"; `AppCopyTests` has `allVisibleStrings` and `plainStrings` used by `noTechnicalErrorText` and `plainStringsHaveNoSpookyWords`; "Page indicator" contains no listed spooky word.
- Page 0 contains "travel an ocean"; page 2 contains "Or existent farmers".
- `onGeometryChange(for:of:action:)` argument order in the design's snippet is correct; it needs iOS 18 / macOS 15, below the deployment targets.
- The hit-area and the Hero centering reasoning match the source (symmetric 24 pt horizontal padding, VStack full width through the bullets card).
- New files go into synchronized folders; no `project.pbxproj` edit. No colors, icons or raw symbol names are added.

## Unverified / Wrong Assumptions
- Unverified: the owner chose option (c). No message in the run records it (finding 1).
- Unverified: Skip is about 70 pt wide and 34 pt tall. The rule's outcome on 375 and 390 pt screens depends on it (finding 2).
- Wrong (incomplete): the design's fallback example is a 320 pt screen, which no supported iPhone has. The real narrowest case, 375 pt, falls back (finding 2).
- Unverified: `adjust(toNormalizedSliderPosition:)` works on this element (finding 5).
- Unverified: `.contentShape(.capsule)` on the label widens the plain-button hit area. A fallback is defined.
- Unverified: Next and the dots fit at `accessibility-extra-extra-extra-large`. A screenshot check is defined.
