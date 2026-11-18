# Implementation Plan: Onboarding accessibility fixes (issue #23)

Branch: `feature/23-onboarding-accessibility-fixes`. Design: `02-design.md` (including its "Implementation notes", which override earlier text). Requirements: `01-requirements.md`. All paths are under `<repo>/`. Never stage `.agents/tasks/`. Commit only when the owner approves; run `git branch --show-current` first.

Commands (repo root):
- iOS build: `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/dd-fonts build`
- macOS build: same with `-destination 'platform=macOS' -derivedDataPath /tmp/ddmac`
- Unit tests: iOS command with `test -only-testing:NYCFarmerMarketsTests`
- UI tests: iOS command with `test -only-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITests` (class holding the onboarding tests in `OnboardingUITests.swift`; confirm the class name when opening the file). Re-run once on a transient xctrunner error. `-resultBundlePath` must not exist yet.

- [ ] 1. Copy fix and indicator label string
  - Change page 0 "travel an ocean" to "travels an ocean" in `NYCFarmerMarkets/Onboarding/OnboardingPage.swift`.
  - Add `static let onboardingPageIndicatorLabel = "Page indicator"` to `NYCFarmerMarkets/Theme/AppCopy.swift` (next to `onboardingPageIndicator(page:count:)`, line 51).
  - Tests: in `NYCFarmerMarketsTests/OnboardingPageTests.swift` assert `OnboardingPage.all[0].message` contains "travels an ocean" and not "travel an ocean", and that `all[2].message` still contains "Or existent farmers". In `NYCFarmerMarketsTests/AppCopyTests.swift` assert the label equals "Page indicator" and add it to `plainStrings` (line 51) and `allVisibleStrings` (line 40).
  - Requirements: 5.1, 5.2, 1.7, 6.5.
  - Verify: unit tests (`-only-testing:NYCFarmerMarketsTests`) pass.

- [ ] 2. Pure paging logic
  - Create `NYCFarmerMarkets/Models/OnboardingPaging.swift`: `nonisolated enum OnboardingPaging { static func target(from current: Int, delta: Int, count: Int) -> Int? }`. Return nil for `count <= 0`, `current` outside `0..<count`, or a result outside `0..<count`; no clamping.
  - Create `NYCFarmerMarketsTests/OnboardingPagingTests.swift` (Swift Testing): +1 and -1 in the middle, nil at both ends, count 0 and 1, current out of range, delta 0, delta +-2.
  - Requirements: 1.3, 1.4, 1.5, 6.5.
  - Verify: `-only-testing:NYCFarmerMarketsTests/OnboardingPagingTests` passes.

- [ ] 3. Hero clearance logic
  - Create `NYCFarmerMarkets/Models/OnboardingHeroLayout.swift`: `nonisolated enum OnboardingHeroLayout` with constants `topMargin = 8`, `gapBelowSkip = 3`, `sideGap = 4`, and `topInset(safeAreaTop:containerWidth:heroWidth:heroCornerRadius:skipSize:skipTopPadding:skipTrailingPadding:) -> CGFloat`.
  - Rule (design notes 1): Hero top relative to itself is `safeAreaTop + topMargin`. Skip's bottom edge relative to the Hero top is `skipTopPadding + skipSize.height - topMargin`. Compute the Hero's horizontal half-extent at that height for a rounded rectangle of width `heroWidth` and corner radius `heroCornerRadius` (full half-width below the corner zone; inside the corner zone `r - sqrt(r² - (r - y)²)` is subtracted from the half-width; if the height is above the Hero top, the Hero does not reach it and clears). If `containerWidth/2 + halfExtent + sideGap <= containerWidth - skipTrailingPadding - skipSize.width`, return `safeAreaTop + topMargin`; otherwise `safeAreaTop + skipTopPadding + skipSize.height + gapBelowSkip`. Sanitize negative and non-finite inputs to 0; never return less than `safeAreaTop + topMargin`. Document the formula in a comment.
  - Create `NYCFarmerMarketsTests/OnboardingHeroLayoutTests.swift` (Swift Testing): widths 375, 390, 393 at Skip 70 x 34, safe top 59, circle (radius = 95) expects `safeAreaTop + 8` on all three; framed (radius 32) result stated explicitly after computing it by hand; a large Skip (Dynamic Type) that falls back to `safe + 8 + height + 3`; equality boundary rises; negative and non-finite inputs; result never below `safe + 8`. No 320 pt case.
  - Requirements: 4.1, 4.2, 6.5.
  - Verify: `-only-testing:NYCFarmerMarketsTests/OnboardingHeroLayoutTests` passes.

- [ ] 4. Hero size and emoji position
  - In `NYCFarmerMarkets/Onboarding/OnboardingPageView.swift`: add `static let heroSize: CGFloat = 190` and `static let heroFallbackSize: CGFloat = 160`; use them at lines 68, 79 (220) and 94 (180); change the `ZStack` alignment (line 61) from `.topTrailing` to `.topLeading`; keep the ZStack `.accessibilityHidden(true)`, tokens and `.appFont(.splash)`. Also add a static for the framed corner radius (32; read the real value from the file) so `OnboardingView` can pass it.
  - Requirements: 4.3.
  - Verify: iOS build succeeds.

- [ ] 5. OnboardingView: adjustable larger indicator, whole-capsule Next, measured Skip, hero inset
  - File: `NYCFarmerMarkets/Onboarding/OnboardingView.swift`. Depends on tasks 1 to 4.
  - Replace `skipAreaHeight` with `Layout` constants `skipTopPadding = 8`, `skipTrailingPadding = 24`, `defaultSkipSize = CGSize(width: 70, height: 34)`, `dotDiameter = 12`, `dotSpacing = 12`, `indicatorMinimumSize = 44`, `controlsAreaHeight = 166`. Add `@State private var skipSize = Layout.defaultSkipSize`; measure Skip with `.onGeometryChange(for: CGSize.self) { $0.size } action: { skipSize = $0 }` placed before its top and horizontal padding; keep the opacity/disabled/hidden behavior on the last page.
  - Compute `topInset` with `OnboardingHeroLayout.topInset(...)` from `proxy.safeAreaInsets.top`, `proxy.size.width`, `OnboardingPageView.heroSize`, the corner radius (use the circle radius `heroSize / 2` for the clearance since all page styles share one inset: pass the larger-extent case, i.e. the framed radius if any page uses `framed`; follow design note 1 and state the choice in a comment), `skipSize` and the paddings; pass it to `pager`.
  - Indicator: dots 12 pt with 12 pt spacing, padding 16 horizontal and vertical, `.frame(minWidth:minHeight:)` of 44 before `.glassEffect(.regular, in: .capsule)`; `.accessibilityElement(children: .ignore)`, `.accessibilityLabel(AppCopy.onboardingPageIndicatorLabel)`, `.accessibilityValue(AppCopy.onboardingPageIndicator(page: selection + 1, count: pages.count))`, `.accessibilityAdjustableAction { .increment -> step(1); .decrement -> step(-1); @unknown default: break }`, identifier `onboarding-page-indicator` unchanged.
  - Add `private func move(to index: Int)` with the Reduce Motion branch and `private func step(_ delta: Int)` using `OnboardingPaging.target`; make `advance()` use `move(to: selection + 1)` for non-last pages. Comment that `selection` equals the page id equals the index. Adjust plays no sound and never touches `hasSeenOnboarding`.
  - Next: add `.contentShape(.capsule)` to the label after `.glassEffect(...)`. Fallback only if task 6 shows taps outside the text still fail: also `.contentShape(.capsule)` on the `Button` after `.buttonStyle(.plain)`. Do not switch to `.glass`/`.glassProminent`.
  - Requirements: 1.1 to 1.7, 2.1 to 2.4, 3.1 to 3.3, 4.1 to 4.4.
  - Verify: iOS build and macOS build succeed; run the convention check from theme-conventions (zero lines).

- [ ] 6. UI tests
  - File: `NYCFarmerMarketsUITests/OnboardingUITests.swift`; all tests keep `launchWithOnboarding()` and `-uiTestingMuteSounds`; no identifier renames.
  - Update `testSwipeMovesToSecondPage` (lines 115 to 126) to read `value as? String` (add an `indicatorValue` helper) and use a `value == %@` predicate.
  - Add `testNextTapsOutsideTextAdvance`: tap `nextButton.coordinate(withNormalizedOffset: CGVector(dx: 0.04, dy: 0.5))`, wait for "Page 2 of 3".
  - Add `testPageIndicatorFrameIsAtLeast44Points`: frame height and width >= 44.
  - Add `testPageIndicatorAdjustActions` as a spike first: `adjust(toNormalizedSliderPosition: 1.0)` gives "Page 2 of 3", `0.0` gives "Page 1 of 3", no-op at first page (wait 1 s), no-op at last page (navigate with Next, wait 1 s, `onboarding-screen` still exists). If the spike fails (expected: XCTest parses slider values, design note 5), do not edit AC 6.2 and do not change the view: call `send_message` to parent with severity "warning" describing the failure and the proposed AC 6.2 amendment (adjust behavior covered by `OnboardingPagingTests` plus the owner's VoiceOver check), and wait. Remove or disable the failing test only after the answer.
  - Add a screenshot test (or extend one) attaching `XCTAttachment` of page 0 and the last page at default and `accessibility-extra-extra-extra-large` text; export with `xcrun xcresulttool export attachments`; confirm the Hero clears Skip, the dots and Next stay on screen, and read the real Skip size. If the size differs from 70 x 34, update `Layout.defaultSkipSize` and the unit tests; if the Hero does not rise about 40 pt at 393 pt width, or Next is clipped at the largest size, report instead of tuning silently.
  - Requirements: 6.1 to 6.4, 6.6, 2.4, 4.2.
  - Verify: UI test command; the new and updated onboarding tests pass (or the adjust test is handled as above).

- [ ] 7. Full verification
  - Run iOS build, macOS build, full unit tests, and the full tests command from the project rules (skip the launch and performance tests). Run the convention check. Confirm `git -C <repo> status` shows only the planned files and nothing under `.agents/tasks/` is staged. Remove any temporary files created, stating literal paths.
  - Requirements: Non-functional 1 to 3.
  - Verify: all commands succeed.

(The `.kiro/specs/onboarding-flow/` amendment is written by the record_spec step, not here.)

## Digest

| File | Block | Test | Verified |
|---|---|---|---|
| `Onboarding/OnboardingView.swift` | `Layout` enum (lines 46-49 `skipAreaHeight`, `controlsAreaHeight`), `body` call to `pager(topInset: proxy.safeAreaInsets.top + Layout.skipAreaHeight, ...)` (line 21), `skipButton` (53-65), `bottomControls` (67-108: dots HStack spacing 8, 8 pt circles, padding 14/10, `.accessibilityLabel(AppCopy.onboardingPageIndicator(...))`; Next `Button(action: advance)` with `.glassEffect` on the `Text`), `advance()` (116-126) | `OnboardingUITests` | Read; not yet built by me |
| `Onboarding/OnboardingPageView.swift` | `var topInset` (line 6), `.contentMargins(.top, topInset, ...)` (53), `ZStack(alignment: .topTrailing)` (61), frames 220 (68, 79) and 180 (94) | UI screenshots | Grep only |
| `Onboarding/OnboardingPage.swift` | `OnboardingPage.all[0].message` | `OnboardingPageTests` | Not opened; open before editing |
| `Theme/AppCopy.swift` | `onboardingPageIndicator(page:count:)` at line 51 | `AppCopyTests` (`allVisibleStrings` line 40, `plainStrings` line 51) | Grep only |
| `Models/OnboardingPaging.swift`, `Models/OnboardingHeroLayout.swift` (new) | as in tasks 2, 3 | `OnboardingPagingTests`, `OnboardingHeroLayoutTests` (new) | Models folder has no existing file with these names |
| `NYCFarmerMarketsUITests/OnboardingUITests.swift` | `testSwipeMovesToSecondPage` (115-126, reads `.label`); `testNextTwiceThenEnterTheMarket` uses the Next label (unchanged) | itself | Not run; build and test baseline not yet run by me |
