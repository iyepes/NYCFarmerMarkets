# Implementation Plan: Onboarding Flow

## Overview

Onboarding is placed between the splash and the tabs, shown once per install. The plan builds pure logic and tests first, then theme additions, then adjusts the owner's `Onboarding/` files, then wires `NYCFarmerMarketsApp` and `AppRootView`, then adds UI tests, docs and full verification. Each step compiles and leaves the app working: nothing renders `OnboardingView` until the `AppRootView` task.

Work happens on branch `feature/onboarding-flow`. Never work on `main`. Commits happen only on the feature branch and only with the owner's approval; stage files by name. The owner's image sets `pirate-ship`, `map-image` and `dairy-products-pallete` in `Assets.xcassets` are staged and not yet committed. No task renames or moves them. Page copy (including "or travel an ocean" and "Or existent farmers") stays as written.

Design properties are tested with Swift Testing parameterized `@Test(arguments:)` over small finite domains, with no third-party library. Each test carries the comment `// Feature: onboarding-flow, Property N: <title>`. The design does not mark property tests optional, so none are marked with `*`.

## Tasks

- [x] 1. Add the pure screen-selection logic
  - [x] 1.1 Create `NYCFarmerMarkets/Models/OnboardingDecision.swift`
    - Foundation only, no SwiftUI import
    - `nonisolated enum RootScreen: Equatable, Sendable` with `splash`, `onboarding`, `tabs`
    - `nonisolated enum OnboardingDecision` with `static let defaultsKey = "hasSeenOnboarding"` and `static func screen(phase: SplashPhase, hasSeenOnboarding: Bool) -> RootScreen`
    - No stored state, clock or counters
    - _Requirements: 2.4, 2.6, 5.1, 5.2, 5.3, 5.4, 5.6_

  - [x] 1.2 Write `NYCFarmerMarketsTests/OnboardingDecisionTests.swift`
    - **Property 1: Decision table** over `[.loading, .failed, .dismissed] x [false, true]`, one assertion per combination
    - **Property 2: Failure message does not matter** with empty, whitespace-only, long and non-ASCII messages for both flag values
    - **Property 3: Decision has no memory** with interleaved inputs, `(.dismissed, false)` then `(.dismissed, true)`, and the same input twice
    - **Validates: Requirements 1.1, 2.1, 2.6, 4.5, 4.7, 5.2, 5.3, 5.4, 5.5, 5.6, 10.1**

- [x] 2. Add launch flags and the flag action
  - [x] 2.1 Extend `NYCFarmerMarkets/Models/LaunchOptions.swift`
    - Add `skipOnboarding` and `resetOnboarding`, parsed with `arguments.contains("-uiTestingSkipOnboarding")` and `arguments.contains("-uiTestingResetOnboarding")` (exact, case-sensitive, no value consumed)
    - Add `nonisolated enum OnboardingFlagAction: Equatable, Sendable { none, markSeen, reset }` and the computed `onboardingFlagAction`: reset wins, then markSeen when `skipOnboarding` or `resetFavorites`, else none
    - Add `OnboardingFlagAction.apply(to:key:)` that sets true, removes the key, or does nothing, using `OnboardingDecision.defaultsKey` as the default key
    - Keep the existing parsing of other arguments unchanged
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

  - [x] 2.2 Extend `NYCFarmerMarketsTests/LaunchOptionsTests.swift`
    - **Property 4: Launch arguments parse by exact match** with the known flags, near-miss strings (`-uiTestingResetOnboardingX`, `uiTestingSkipOnboarding`, different case), unrelated strings, any order, and an empty list
    - **Property 5: Onboarding flag action precedence** over all 8 combinations of `resetFavorites`, `skipOnboarding`, `resetOnboarding`
    - Include the four assertions from requirement 10.2 (neither, only skip, only reset, both gives reset)
    - **Validates: Requirements 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 10.2**

  - [x] 2.3 Write `NYCFarmerMarketsTests/OnboardingFlagActionTests.swift`
    - **Property 6: Applying a flag action writes the right value** for starting states absent, true and false, and actions `.none`, `.markSeen`, `.reset`
    - Use a throwaway `UserDefaults(suiteName:)` and remove it in `defer`
    - Apply twice and check the state is the same; check the decision for the stored value (absent read as false) matches Property 1
    - **Validates: Requirements 2.4, 9.1, 9.2, 9.3, 9.5**

- [x] 3. Checkpoint - Ensure all tests pass
  - Run the unit tests command from `tech.md` (`test -only-testing:NYCFarmerMarketsTests`). Ensure all tests pass, ask the user if questions arise.

- [x] 4. Add theme icons and copy
  - [x] 4.1 Add four cases to `NYCFarmerMarkets/Theme/AppIcon.swift`
    - `onboardingBullet` (`moon.stars.fill`, "Bullet"), `onboardingShipping` (`shippingbox.fill`, "Shipping"), `onboardingMap` (`map.fill`, "Map"), `onboardingPeople` (`person.2.fill`, "Neighbors and growers")
    - Fill both the `source` and `accessibilityName` switches
    - The existing `everyIconResolves` test covers the new cases without edits
    - _Requirements: 7.1_

  - [x] 4.2 Add onboarding strings to `NYCFarmerMarkets/Theme/AppCopy.swift`
    - `onboardingSkip` "Skip", `onboardingNext` "Next", `onboardingEnter` "Enter the market"
    - `onboardingPrimaryLabel(isLast:)` and `onboardingPageIndicator(page:count:)` returning "Page N of M"
    - _Requirements: 3.2, 3.3, 3.9, 6.1, 7.4_

  - [x] 4.3 Extend `NYCFarmerMarketsTests/AppCopyTests.swift`
    - **Property 7: Button and indicator labels follow the page** for page counts 1 to 5 and every index in range
    - Add the three labels and one indicator string to `allVisibleStrings` so the existing tone checks cover them
    - **Validates: Requirements 3.2, 3.3, 3.9, 6.1, 6.8, 7.4**

  - [x] 4.4 Increase the `splash` role to 44 pt
    - In `NYCFarmerMarkets/Theme/AppTypography.swift` change `case .splash: 40` to `44`. This also enlarges the Splash failure message (`splash-error`), the only other `.splash` user; the loading caption uses `.splashHint` and does not change.
    - Add the example test `splashRoleIsFortyFourPoints` to `NYCFarmerMarketsTests/AppTypographyTests.swift`: `AppTypography.Role.splash.size == 44` and `effectiveSize == 44`. No existing test pins the splash size, and every existing typography test must pass unchanged.
    - _Requirements: 7.8, 10.13_

- [x] 5. Adjust the owner's onboarding files
  - [x] 5.1 Update `NYCFarmerMarkets/Onboarding/OnboardingPage.swift`
    - Mark `HeroStyle` and `OnboardingPage` `nonisolated` and `Sendable`
    - Change `symbol: String` to `symbol: AppIcon` with `.onboardingShipping`, `.onboardingMap`, `.onboardingPeople` for pages 0 to 2
    - Keep ids, eyebrows, emoji, copy, `heroImage` names (`pirate-ship`, `map-image`, `dairy-products-pallete`) and `heroStyle` values exactly as written
    - _Requirements: 5.7, 7.1, 7.7_

  - [x] 5.2 Write `NYCFarmerMarketsTests/OnboardingPageTests.swift`
    - **Property 8: Page content shape**: exactly 3 pages, unique ids, non-blank eyebrow, title and message after trimming, exactly 3 non-blank bullets per page
    - **Property 9: Hero images exist**: every non-nil `heroImage` resolves in the app bundle via `Bundle(for: MarketStore.self)` (`UIImage(named:in:with:)`, `NSImage` on macOS, guarded with `#if canImport`); each of the three asset names is used by exactly one page and no other name appears
    - Do not rename or move the image sets
    - **Validates: Requirements 1.4, 5.7, 7.7, 10.3, 10.12**

  - [x] 5.3 Update `NYCFarmerMarkets/Onboarding/OnboardingPageView.swift`
    - Bullet icon through `AppIcon.onboardingBullet.image`, still hidden from VoiceOver
    - Hero symbol drawn by `IconView(page.symbol, size: 72)`, which satisfies requirement 7.3: the size is set inside `Theme/`, and `Onboarding/` contains no `.font(` call
    - Emoji through `.appFont(.splash)` (44 pt, after task 4.4)
    - Add `.accessibilityAddTraits(.isHeader)` on the title and `.accessibilityIdentifier("onboarding-page-\(page.id)")` on the scroll view
    - Keep hero, emoji and symbol hidden from VoiceOver, and eyebrow, title, message and bullets as separate text elements in order
    - _Requirements: 6.2, 6.3, 6.5, 6.6, 7.1, 7.3, 7.5, 7.8_

  - [x] 5.4 Update `NYCFarmerMarkets/Onboarding/OnboardingView.swift`
    - Replace `@AppStorage("hasSeenOnboarding")` with `@Binding var hasSeenOnboarding: Bool`; add `@Environment(SoundController.self)` and `@Environment(\.accessibilityReduceMotion)`; update the `#Preview` to pass `.constant(false)` and a muted `SoundController`
    - Root: `.accessibilityElement(children: .contain)` and identifier `onboarding-screen`
    - Skip button: `AppCopy.onboardingSkip` text and label, identifier `onboarding-skip`, `.opacity(isLast ? 0 : 1)`, `.disabled(isLast)`, `.accessibilityHidden(isLast)`
    - Next button: `AppCopy.onboardingPrimaryLabel(isLast:)` text and label, identifier `onboarding-next`, keep `.glass` styling
    - Page indicator: `AppCopy.onboardingPageIndicator` label, identifier `onboarding-page-indicator`, one accessibility element
    - Actions `skip()` and `advance()` guard on `!hasSeenOnboarding`, call `sounds.play(.hiss)` once, set the flag on skip or on the last page, and advance without `withAnimation` when Reduce Motion is on. Swipes send no cue.
    - _Requirements: 2.2, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10, 6.1, 6.4, 6.7, 6.8, 7.1, 7.2, 7.3, 7.4, 7.5, 8.1, 8.5, 8.6, 8.7_

- [x] 6. Wire onboarding into the app
  - [x] 6.1 Apply the flag action in `NYCFarmerMarkets/NYCFarmerMarketsApp.swift`
    - After the existing `options.resetFavorites` block, add `options.onboardingFlagAction.apply(to: .standard)` inside `init`, before the root view exists
    - Keep the existing clearing of favorites and the sound setting under `-uiTestingReset`
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

  - [x] 6.2 Switch screens in `NYCFarmerMarkets/Views/AppRootView.swift`
    - Add one `@AppStorage(OnboardingDecision.defaultsKey) private var hasSeenOnboarding = false`
    - Compute `screen` with `OnboardingDecision.screen(phase: hasDismissed ? .dismissed : phase, hasSeenOnboarding:)`
    - Render `SplashView`, `OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)` or `RootTabView` from a three-way switch; `RootTabView` exists only in the `.tabs` case; transitions use `.identity` under Reduce Motion
    - Leave the single `store.load()` task, the minimum-time task, the `hasDismissed` latch and the VoiceOver `onChange` unchanged; `RootTabView` is not modified
    - _Requirements: 1.1, 1.2, 2.1, 2.2, 2.3, 2.5, 3.4, 3.6, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 8.2, 8.3, 8.4_

- [x] 7. Checkpoint - Ensure all tests pass
  - Build iOS and macOS and run the unit tests command from `tech.md`. Ensure all tests pass, ask the user if questions arise.

- [x] 8. Add UI tests
  - [x] 8.1 Write `NYCFarmerMarketsUITests/OnboardingUITests.swift`
    - Each test launches with `-uiTestingReset`, `-uiTestingResetOnboarding`, `-uiTestingMuteSounds` and finds elements by the identifiers `onboarding-screen`, `onboarding-next`, `onboarding-skip`, `onboarding-page-indicator`
    - `testOnboardingShowsAfterSplashWithoutTabs`: `onboarding-screen` exists within 30 s; Markets, Map and Favorites tab items do not exist
    - `testNextTwiceThenEnterTheMarket`: tap next twice; label "Enter the market"; skip not hittable; tap next; tab items exist within 30 s; `onboarding-screen` gone
    - `testSkipLeavesOnboarding`: tap skip on page 1; tab items exist within 30 s; `onboarding-screen` gone
    - `testOnboardingShowsOnlyOnce`: finish onboarding, terminate, relaunch with only `-uiTestingMuteSounds`; tab items exist within 30 s and `onboarding-screen` never exists
    - `testSwipeMovesToSecondPage`: swipe left on `onboarding-screen`; indicator label "Page 2 of 3"
    - If `.contain` hides an inner identifier, put the identifiers on the elements themselves
    - Do not change the existing UI tests or identifiers; every existing and new launch already passes `-uiTestingMuteSounds`
    - _Requirements: 1.1, 1.2, 1.3, 1.5, 2.2, 2.3, 2.5, 3.1, 3.3, 3.4, 3.5, 3.6, 3.7, 3.9, 9.3, 10.4, 10.5, 10.6, 10.7, 10.8, 10.9, 10.10_

- [x] 9. Update documentation
  - [x] 9.1 Update `.kiro/steering/tech.md`
    - Under "Launch arguments" list `-uiTestingSkipOnboarding` (writes `hasSeenOnboarding = true`) and `-uiTestingResetOnboarding` (removes the flag; wins over `-uiTestingSkipOnboarding` and `-uiTestingReset`), and note that `-uiTestingReset` also writes `true` unless the reset argument is present
    - Add `OnboardingDecision` and `Onboarding/` to the Layout list
    - _Requirements: 9.7_

  - [x] 9.2 Update `.kiro/steering/theme-conventions.md`
    - Add the four `AppIcon` cases, the onboarding strings, the identifiers, the note that onboarding buttons use `.glass` and call `sounds.play(.hiss)` explicitly, and the note that the emoji uses `.splash` and the hero symbol is drawn by `IconView` at 72 pt
    - Change the role list entry `splash` (40) to `splash` (44)
    - _Requirements: 7.1, 7.3, 7.4, 7.5, 7.8, 8.1_

  - [x] 9.3 Update `.kiro/steering/product.md`
    - Add the onboarding screen between Splash and Tabs under Screens and the `hasSeenOnboarding` key under Data
    - _Requirements: 1.1, 2.3_

- [x] 10. Verify
  - [x] 10.1 Build iOS and macOS
    - Run the iOS and macOS build commands from `tech.md`; zero warnings in new and changed files and a total no higher than `origin/main`
    - _Requirements: 10.11_

  - [x] 10.2 Run the convention check from `theme-conventions.md`
    - Run the five `grep` commands from the "Convention check" section at the repo root; confirm zero lines for paths beginning with `NYCFarmerMarkets/Onboarding/`
    - _Requirements: 7.1, 7.2, 7.3, 7.6_

  - [x] 10.3 Run the full test command from `tech.md`
    - iOS command with `test -skip-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITestsLaunchTests -skip-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITests/testLaunchPerformance`; use a `-resultBundlePath` that does not exist yet; re-run once on a transient xctrunner launch error
    - Existing UI tests must pass unchanged
    - _Requirements: 9.3, 10.9, 10.10_

  - [x] 10.4 Run the manual checks that automation cannot cover and record results
    - Reduce Motion on: tapping Next shows the next page with no slide. If the paged `TabView` still animates, add a `Transaction` with `disablesAnimations` and re-check (requirement 6.4)
    - VoiceOver: order eyebrow, title (heading), message, three bullets; no stop on hero, emoji or bullet icons; Skip and Next announce their labels; Next advances without swiping; the indicator reads the new page (requirements 6.1, 6.2, 6.5, 6.6, 6.7, 6.8)
    - Dynamic Type `xSmall` to `accessibility5` (`xcrun simctl ui booted content_size ...`): no truncation, every text scrolls clear of Skip and the bottom controls (requirement 6.3)
    - Sound on, VoiceOver off: hiss on Skip and Next, door once when the tabs appear (requirements 8.1, 8.2, 8.3)
    - Splash screen text at 44 pt reads well and fits on iPhone 17 at the default and largest Dynamic Type size (requirement 7.8)
    - Report anything not verified (visionOS, audio in tests) in the PR body
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 7.8, 8.1, 8.2, 8.3_

- [x] 11. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise. Commits happen only on `feature/onboarding-flow` and only with the owner's approval.

## Notes

- No tasks are optional: the design does not mark its property tests optional.
- Every task references requirement numbers from `requirements.md`.
- Property tests use exhaustive enumeration of small domains instead of random generation, because no third-party dependency may be added.
- The owner's image sets are never renamed or moved.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "4.1", "4.2", "4.4"] },
    { "id": 1, "tasks": ["1.2", "2.1", "4.3", "5.1"] },
    { "id": 2, "tasks": ["2.2", "2.3", "5.2", "5.3", "5.4"] },
    { "id": 3, "tasks": ["6.1", "6.2"] },
    { "id": 4, "tasks": ["8.1", "9.1", "9.2", "9.3"] },
    { "id": 5, "tasks": ["10.1", "10.2", "10.3"] },
    { "id": 6, "tasks": ["10.4"] }
  ]
}
```


---

## Amendment: onboarding accessibility fixes (2026-11-17)

Issue #23, branch `feature/23-onboarding-accessibility-fixes`, follow-up to PR #22. Task numbers below are local to this amendment (original tasks above stay as recorded); checkboxes start unchecked.


Branch: `feature/23-onboarding-accessibility-fixes`. Design: `02-design.md` (including its "Implementation notes", which override earlier text). Requirements: `01-requirements.md`. All paths are under `/Users/isabelyepes/Documents/XCode/NYCFarmerMarkets/`. Never stage `.agents/tasks/`. Commit only when the owner approves; run `git branch --show-current` first.

Commands (repo root):
- iOS build: `xcodebuild -project NYCFarmerMarkets.xcodeproj -scheme NYCFarmerMarkets -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/dd-fonts build`
- macOS build: same with `-destination 'platform=macOS' -derivedDataPath /tmp/ddmac`
- Unit tests: iOS command with `test -only-testing:NYCFarmerMarketsTests`
- UI tests: iOS command with `test -only-testing:NYCFarmerMarketsUITests/NYCFarmerMarketsUITests` (class holding the onboarding tests in `OnboardingUITests.swift`; confirm the class name when opening the file). Re-run once on a transient xctrunner error. `-resultBundlePath` must not exist yet.

- [x] 1. Copy fix and indicator label string
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
  - Run iOS build, macOS build, full unit tests, and the full tests command from the project rules (skip the launch and performance tests). Run the convention check. Confirm `git -C /Users/isabelyepes/Documents/XCode/NYCFarmerMarkets status` shows only the planned files and nothing under `.agents/tasks/` is staged. Remove any temporary files created, stating literal paths.
  - Requirements: Non-functional 1 to 3.
  - Verify: all commands succeed.

(The `.kiro/specs/onboarding-flow/` amendment is written by the record_spec step, not here.)

### Digest

| File | Block | Test | Verified |
|---|---|---|---|
| `Onboarding/OnboardingView.swift` | `Layout` enum (lines 46-49 `skipAreaHeight`, `controlsAreaHeight`), `body` call to `pager(topInset: proxy.safeAreaInsets.top + Layout.skipAreaHeight, ...)` (line 21), `skipButton` (53-65), `bottomControls` (67-108: dots HStack spacing 8, 8 pt circles, padding 14/10, `.accessibilityLabel(AppCopy.onboardingPageIndicator(...))`; Next `Button(action: advance)` with `.glassEffect` on the `Text`), `advance()` (116-126) | `OnboardingUITests` | Read; not yet built by me |
| `Onboarding/OnboardingPageView.swift` | `var topInset` (line 6), `.contentMargins(.top, topInset, ...)` (53), `ZStack(alignment: .topTrailing)` (61), frames 220 (68, 79) and 180 (94) | UI screenshots | Grep only |
| `Onboarding/OnboardingPage.swift` | `OnboardingPage.all[0].message` | `OnboardingPageTests` | Not opened; open before editing |
| `Theme/AppCopy.swift` | `onboardingPageIndicator(page:count:)` at line 51 | `AppCopyTests` (`allVisibleStrings` line 40, `plainStrings` line 51) | Grep only |
| `Models/OnboardingPaging.swift`, `Models/OnboardingHeroLayout.swift` (new) | as in tasks 2, 3 | `OnboardingPagingTests`, `OnboardingHeroLayoutTests` (new) | Models folder has no existing file with these names |
| `NYCFarmerMarketsUITests/OnboardingUITests.swift` | `testSwipeMovesToSecondPage` (115-126, reads `.label`); `testNextTwiceThenEnterTheMarket` uses the Next label (unchanged) | itself | Not run; build and test baseline not yet run by me |
