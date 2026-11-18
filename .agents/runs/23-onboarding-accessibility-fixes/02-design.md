# Design: Onboarding accessibility fixes (issue #23), revision 2

## Overview

Four small changes inside `NYCFarmerMarkets/Onboarding/`, plus one pure helper in `Models/`, one string in `Theme/AppCopy.swift`, and test updates. No new dependencies, no `project.pbxproj` edits, no new launch arguments. Stack stays as is: Swift 5 mode, SwiftUI, `@Observable` stores, Swift Testing for unit tests, XCTest for UI tests. The stack is locked once this design is approved.

Files:

| File | Change |
|---|---|
| `NYCFarmerMarkets/Onboarding/OnboardingView.swift` | Adjustable, larger Page_Indicator; capsule-wide Next hit area; shared `move(to:)`; measured Skip height; `Layout` constants |
| `NYCFarmerMarkets/Onboarding/OnboardingPageView.swift` | Hero 220 to 190 pt (fallback 180 to 160), emoji to `topLeading`, shared `heroSize` constant |
| `NYCFarmerMarkets/Models/OnboardingHeroLayout.swift` (new) | `nonisolated` hero top-inset clearance rule |
| `NYCFarmerMarketsTests/OnboardingHeroLayoutTests.swift` (new) | Swift Testing for the clearance rule |
| `NYCFarmerMarkets/Onboarding/OnboardingPage.swift` | "travel an ocean" to "travels an ocean" on page 0 |
| `NYCFarmerMarkets/Models/OnboardingPaging.swift` (new) | `nonisolated` pure page-step logic |
| `NYCFarmerMarkets/Theme/AppCopy.swift` | New `onboardingPageIndicatorLabel` string |
| `NYCFarmerMarketsTests/OnboardingPagingTests.swift` (new) | Swift Testing for the step logic |
| `NYCFarmerMarketsTests/OnboardingPageTests.swift` | Copy assertions |
| `NYCFarmerMarketsTests/AppCopyTests.swift` | New label string |
| `NYCFarmerMarketsUITests/OnboardingUITests.swift` | Label to value, new tests |
| `.kiro/specs/onboarding-flow/*` | Amendment, written by the record_spec step (not here) |

## 1. Adjustable Page_Indicator (Requirements 1, 2)

**Accessibility.** The dot row stays one element (`.accessibilityElement(children: .ignore)`), keeps identifier `onboarding-page-indicator`, and gains:

- `.accessibilityLabel(AppCopy.onboardingPageIndicatorLabel)`, new constant `"Page indicator"` (plain, not spooky).
- `.accessibilityValue(AppCopy.onboardingPageIndicator(page: selection + 1, count: pages.count))`, the existing "Page N of M" text. It derives from `selection`, so it updates on swipe, Next and adjust.
- `.accessibilityAdjustableAction { direction in ... }`. SwiftUI adds the adjustable trait with this modifier. `.increment` calls `step(+1)`, `.decrement` calls `step(-1)`, `@unknown default` does nothing.

VoiceOver reads "Page indicator, Page 2 of 3, adjustable". XCUITest sees the old text in `value` instead of `label`.

**Step logic.** `Models/OnboardingPaging.swift`:

```swift
nonisolated enum OnboardingPaging {
    /// The page index after moving `delta` pages, or nil when that would leave 0..<count.
    static func target(from current: Int, delta: Int, count: Int) -> Int?
}
```

Returns `nil` for out-of-range results, `count <= 0`, or `current` outside `0..<count`. The view's `step(_:)` ignores `nil`, so increment on the last page and decrement on the first are no-ops. The adjust path never touches `hasSeenOnboarding` (AC 1.5).

Index/id coupling: `selection` holds `OnboardingPage.id`, and `advance()` and `pages[selection]` already treat it as an index. This works because the ids are 0, 1, 2 in order. `move(to:)` and `OnboardingPaging` take an index that equals the page id; a code comment says so.

**Motion.** A private `move(to index: Int)` in `OnboardingView` holds the Reduce Motion branch (`selection = index`, or `withAnimation(.easeInOut) { selection = index }`). `advance()` uses it for non-last pages and `step(_:)` uses it with the clamped target (AC 1.6).

**Sound.** Adjusting plays no sound, like swiping. Only Next and Skip play the hiss (assumption; requirements are silent).

**Size.** `Layout` gains `dotDiameter = 12`, `dotSpacing = 12`, `indicatorMinimumSize = 44`. The row:

```swift
HStack(spacing: Layout.dotSpacing) { dots at Layout.dotDiameter }
    .padding(.horizontal, 16)
    .padding(.vertical, 16)
    .frame(minWidth: Layout.indicatorMinimumSize, minHeight: Layout.indicatorMinimumSize)
    .glassEffect(.regular, in: .capsule)
    .accessibilityElement(children: .ignore) ...
```

Height is 12 + 2 x 16 = 44 pt (the `minHeight` is a guard if values are tuned). Width is 3 x 12 + 2 x 12 + 32 = 92 pt. The frame precedes `.glassEffect`, so the visible capsule equals the accessibility frame (VoiceOver uses that frame; the row has no gesture, so no `contentShape` is added). Dot colors stay `AppPalette.accent` and `AppPalette.textPrimary` at 0.4 opacity.

**Controls area.** The row grows from 28 to 44 pt, so `Layout.controlsAreaHeight` goes from 150 to 166. The controls are a bottom-aligned overlay, so nothing moves off screen. The Next label scales with Dynamic Type, so the check is a screenshot at `accessibility-extra-extra-extra-large` (the largest size) confirming the dots and Next stay on screen (AC 2.4). If Next is clipped there, the coder raises `controlsAreaHeight` or reports it; it is not assumed fine.

## 2. Whole Next capsule tappable (Requirement 3)

Cause: with `.buttonStyle(.plain)` the hit area is the label's content shape, and `.glassEffect` is only a visual layer on the `Text`. Fix: add `.contentShape(.capsule)` to the label after `.glassEffect(...)`. The label already has `.frame(maxWidth: .infinity)` and `.padding(.vertical, 16)`, so the capsule spans the row. Look, `.interactive()` glass, hiss (inside `advance()`, once per tap), label and `onboarding-next` are unchanged.

**Fallback (finding 6):** if `testNextTapsOutsideTextAdvance` still fails, also apply `.contentShape(.capsule)` to the `Button` itself (after `.buttonStyle(.plain)`). If that also fails, report to the orchestrator; do not switch to `.glass`/`.glassProminent` (changes the look; `glassProminent` is nearly opaque).

## 3. Hero spacing (Requirement 4)

Current numbers on a 59 pt safe-area iPhone: top of view to Hero top is 59 + 48 = 107 pt. Of that, 59 is the safe area, 8 is Skip's top padding, about 34 is Skip's height and about 6 is the gap below Skip. Skip's bottom edge is at about 101 pt.

**Owner decision: option (c).** A literal half (53.5 pt) would sit above Skip's top edge, so the owner chose: the Hero top at safe-area top + 8 pt (67 pt on a 59 pt safe area, 40 pt higher, a 37% reduction), a smaller hero (190 pt), and the emoji moved to the left. The Hero then rises beside Skip instead of under it. AC 4.1 is restated in the amendment as these numbers. AC 4.2 ("never under Skip") is met by the clearance rule below, at every screen width and text size.

**Hero size.** In `OnboardingPageView`, the illustration circle, the framed picture and the symbol fallback shrink: 220 to 190 pt (`Layout.heroSize`), and the fallback circle 180 to 160 pt (`Layout.heroFallbackSize`). The emoji overlay alignment changes from `.topTrailing` to `.topLeading`, so the emoji sits at the left corner, away from Skip. The ZStack stays `.accessibilityHidden(true)`, and colors and fonts stay `AppPalette` tokens and `.appFont(.splash)`.

**Skip measured.** `OnboardingView` replaces the fixed `skipAreaHeight` (48) with `@State private var skipSize: CGSize = Layout.defaultSkipSize` (about 70 x 34, used until the first measurement). The Skip button is measured before its padding:

```swift
Button(...)...buttonStyle(.glass)
    .onGeometryChange(for: CGSize.self) { $0.size } action: { skipSize = $0 }
    .padding(.top, 8)   // Layout.skipTopPadding
    .padding(.horizontal, 24)  // Layout.skipTrailingPadding
```

Skip is hidden on the last page with `opacity(0)` and `disabled`, not removed, so it keeps laying out and its size stays measured; pages do not jump. `onGeometryChange` needs iOS 18 / macOS 15, below the deployment targets.

**Clearance rule (pure logic).** A new `nonisolated` type in `Models/OnboardingHeroLayout.swift`:

```swift
nonisolated enum OnboardingHeroLayout {
    static let topMargin: CGFloat = 8           // Hero top below the safe area when beside Skip
    static let gapBelowSkip: CGFloat = 3        // fallback when Skip is wider than the free space
    static let sideGap: CGFloat = 4             // horizontal space kept between Hero and Skip
    static func topInset(safeAreaTop: CGFloat, containerWidth: CGFloat,
                         heroWidth: CGFloat, skipSize: CGSize,
                         skipTopPadding: CGFloat, skipTrailingPadding: CGFloat) -> CGFloat
}
```

The Hero is centered, so its right edge is `containerWidth / 2 + heroWidth / 2`. Skip's left edge is `containerWidth - skipTrailingPadding - skipSize.width`. If `heroRight + sideGap <= skipLeft`, the Hero cannot touch Skip, and the result is `safeAreaTop + topMargin`. Otherwise (narrow screen or large text making Skip wide) the result falls back to `safeAreaTop + skipTopPadding + skipSize.height + gapBelowSkip`, below Skip. Inputs are sanitized: non-finite or negative values count as 0. The result is never less than `safeAreaTop + topMargin`. A zero `skipSize` (before measurement) cannot occur because the state starts at the default size. The rule uses the largest hero width (190), so it also holds for the 160 pt fallback.

Numbers, default text, 393 pt screen: hero right edge 196.5 + 95 = 291.5; with a 4 pt gap 295.5. Skip left is about 393 - 24 - 70 = 299, so 295.5 <= 299 and the Hero rises to 67 pt. The rule uses `sideGap = 4`. The 70 pt Skip width is an estimate: the coder reads the real width from a screenshot, and the owner's target (about 40 pt higher on a 393 pt screen at default text) must hold. If it does not, the coder reports it rather than shrinking the Hero further. On a 320 pt screen: 160 + 95 + 4 = 259 > 320 - 24 - 70 = 226, so the Hero falls back to below Skip (safe top + 8 + 34 + 3). At large Dynamic Type Skip grows wider, so the rule falls back at the size where it would collide, which is what AC 4.2 asks for ("never under Skip at any Dynamic Type size"). The circle's bounding box, not its curved corner, is used, which is conservative.

**Wiring.** `OnboardingView` computes `topInset` with `OnboardingHeroLayout.topInset(...)` from `proxy.safeAreaInsets.top`, `proxy.size.width`, `Layout.heroWidth` (shared constant 190, defined once in `OnboardingPageView` as `static let heroSize` and read by `OnboardingView`), `skipSize` and the padding constants, and passes it to the pages. `topInset` flows through `contentMargins(.top, ...)`, so all pages, both hero styles and the symbol fallback change together, and the same value is used on the last page (AC 4.3). The pager's `.ignoresSafeArea()` stays. Scrolling under Skip and the bottom controls is unchanged (AC 4.4). The macOS pager shows one page at a time and uses the same inset.

**Content side effect.** The Hero is 30 pt smaller and 40 pt higher, so about 70 pt more content is visible at scroll offset zero. No page scrolling logic changes.

Side effect to note: at the default text size the measured Skip height may differ slightly from 34, so the real gap is the measured value plus 3, not a fixed 3 from the old 48. The coder reads the real height from a screenshot and states it in the PR.

## 4. Copy (Requirement 5)

`OnboardingPage.all[0].message`: "...or travel an ocean before..." becomes "...or travels an ocean before...". Nothing else changes. The amendment notes the reversal of "keep copy as written" for this phrase only.

## Error handling and validation

No new failure paths, I/O or external input. `OnboardingPaging.target` is total: it returns `nil` for invalid input instead of trapping, and the caller treats `nil` as a silent no-op (expected VoiceOver behavior at the ends). Nothing is logged because no technical error exists. Invariants: "selection stays in `0..<pages.count`" is owned by `OnboardingPaging` for adjust and by the `isLast` guard for Next; "the Onboarding_Flag is set only by Next on the last page or Skip" is owned by `advance()`/`skip()`, which the adjust path cannot reach. `skipHeight` is only a layout value; an unmeasured or zero reading falls back to the default 34 via the initial state and is clamped with `max(_, 0)`.

## Testing

**Unit (Swift Testing):**
- `OnboardingPagingTests.swift`: `target` for +1 and -1 in the middle, nil at both ends, `count` 0 and 1, `current` out of range, deltas other than +-1 (nil if out of range, not clamped).
- `OnboardingHeroLayoutTests.swift`: 393 pt wide, default Skip (70 x 34), safe top 59 gives 67; 320 pt wide falls back to 59 + 8 + 34 + 3; wide Skip (large text) on 393 falls back; a Skip that barely fits (equality) rises; negative and non-finite inputs; the result is never below `safeAreaTop + 8`.
- `OnboardingPageTests.swift`: `OnboardingPage.all[0].message` contains "travels an ocean" and not "travel an ocean"; `OnboardingPage.all[2].message.contains("Or existent farmers")` (page id 2; id equals index).
- `AppCopyTests.swift`: `onboardingPageIndicatorLabel == "Page indicator"`, and add it to `plainStrings` (and `allVisibleStrings` if that list exists) so `noTechnicalErrorText` covers it. The "Page N of M" test stays.

**UI (XCTest, `OnboardingUITests.swift`, all via `launchWithOnboarding()` with `-uiTestingMuteSounds`):**
- `testSwipeMovesToSecondPage` reads `pageIndicator.value as? String` instead of `.label` (helper `indicatorValue`).
- `testNextTapsOutsideTextAdvance`: tap `nextButton.coordinate(withNormalizedOffset: CGVector(dx: 0.04, dy: 0.5))` (inside the capsule, left of the centered text); wait for "Page 2 of 3".
- `testPageIndicatorFrameIsAtLeast44Points`: `frame.height >= 44` and `frame.width >= 44`.
- `testPageIndicatorAdjustActions` (finding 3), success defined as:
  1. On page 1, one `adjust(toNormalizedSliderPosition: 1.0)` changes the value to "Page 2 of 3"; one `adjust(toNormalizedSliderPosition: 0.0)` returns it to "Page 1 of 3".
  2. No-op at the first page: `adjust(0.0)` on page 1, wait 1 s, value still "Page 1 of 3".
  3. No-op at the last page: navigate to page 3 with Next taps, `adjust(1.0)`, wait 1 s, value still "Page 3 of 3" and `onboarding-screen` still exists (flag not set).

The design does not claim this works: XCUITest's behavior with `adjust(toNormalizedSliderPosition:)` on a non-slider adjustable SwiftUI element is unverified. The code step runs it as a spike first. If it fails or the value does not change, the fallback needs approval: **AC 6.2 is amended** to "the indicator exposes the value 'Page N of M' and the adjustable behavior is covered by `OnboardingPagingTests` plus the owner's VoiceOver check", the UI value and frame tests stay, and the result goes in the PR body under "not verified". The coder reports the spike result to the orchestrator rather than silently dropping the test.

**Manual/screenshot:** an XCUITest attaches screenshots (`XCTAttachment`) of page 0 and the last page at default and `accessibility-extra-extra-extra-large` text, to confirm the Hero clears Skip and the dots and Next are visible. VoiceOver on a device is the owner's check.

## Build checks

iOS build, macOS build (the shared view compiles there; `accessibilityAdjustableAction` and `onGeometryChange` exist on macOS), unit tests, and onboarding UI tests, using the repo commands. No `Color(...)`, hex or raw SF Symbol names added.

## Review responses (revision 2)

1. MEDIUM, hero 3 pt not "half": Addressed by owner decision (c): Hero top at safe-area top + 8 (about 40 pt higher), hero 190 pt, emoji at the left, with a horizontal clearance rule (section 3). AC 4.1 is restated in the amendment with these numbers.
2. MEDIUM, fixed Skip height: Addressed. Skip's size (width and height) is measured with `onGeometryChange`, and `OnboardingHeroLayout.topInset` falls back to below Skip whenever the Hero would not clear Skip horizontally, at any text size or screen width.
3. MEDIUM, adjust test: Addressed. Success and no-op criteria are defined; the spike is explicitly unverified; the fallback is an owner-approved amendment of AC 6.2, not a silent drop.
4. NIT, largest size: Addressed. Uses `accessibility-extra-extra-extra-large`, with no assumption that Next fits.
5. NIT, indicator `contentShape`: Addressed. Removed.
6. NIT, Next fallback: Addressed (section 2).
7. NIT, `plainStrings`: Addressed.
8. NIT, concrete copy test and id/index note: Addressed.

## Implementation notes (from design review round 2; the design loop was ended by the owner with these still open)

These notes override anything earlier in this document that conflicts with them. Treat them as requirements for the plan and the implementation.

0. **Owner decisions (2026-11-14), recorded by the orchestrator:** the owner chose hero option (c) in the chat in reply to the design step's question, and then chose the shape-aware clearance rule. `01-requirements.md` AC 4.1, 4.2, 4.3 and Out of Scope were updated to match; they no longer say "half".
1. **Shape-aware clearance (was MEDIUM, owner chose option (b)).** `OnboardingHeroLayout.topInset` takes a `heroCornerRadius` input (`heroWidth / 2` for the circular illustration and symbol fallback, 32 for the framed style). It computes the Hero's horizontal half-extent at the height of Skip's bottom edge (relative to the Hero top) for a rounded rectangle with that corner radius, and checks `centerX + halfExtent + sideGap <= skipLeft`. If it clears, the top is safe-area top + 8; otherwise just below Skip (`safe + 8 + skipHeight + 3`). `sideGap` is a named, tested constant (4 pt), not screenshot-tuned.
2. **Tests.** `OnboardingHeroLayoutTests` covers 375 pt, 390 pt and 393 pt widths at the default Skip size (70 x 34) for circle and framed styles, expecting the raised position for the circle on all three; a large-Skip case (Dynamic Type) that falls back; and the framed style result stated explicitly. Remove the 320 pt case (no supported device). The coder confirms the real Skip size from a screenshot and updates `defaultSkipSize` if it differs; the rule uses the measured size at runtime regardless.
3. **Names (NIT).** One constant each: `OnboardingPageView.heroSize = 190`, `OnboardingPageView.heroFallbackSize = 160`, read by `OnboardingView`. State is `skipSize` with `Layout.defaultSkipSize`; replace every `skipHeight`/"default 34" mention accordingly.
4. **Adjust test decision path (NIT).** If the spike for the indicator's increment/decrement UI test fails, the coder sends `send_message` to 'parent' with severity 'warning' and waits; it does not edit AC 6.2 itself.
5. **Expected spike result (NIT).** `adjust(toNormalizedSliderPosition:)` will probably fail on "Page 1 of 3" because XCTest parses slider values. That failure is the expected spike outcome and goes straight to the warning in note 4, not to view changes.
