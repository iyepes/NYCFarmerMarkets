# Adjustable page indicator, whole-capsule Next, and hero repositioning in onboarding

The change makes the onboarding page-dot row a VoiceOver adjustable element (value "Page N of M", swipe up/down moves one page), enlarges the dots to a 44 pt target, makes the entire Next capsule tappable with `.contentShape(.capsule)`, and fixes the "travels an ocean" copy. The hero-spacing request was implemented as a new geometry model (`OnboardingHeroLayout`) driven by a measured Skip button, together with a smaller hero (220 to 190) and the emoji moved to the leading corner. The spec amendment was appended to the existing `onboarding-flow` folder, as required. The coder's recorded results (165 tests passed, iOS and macOS builds, theme check clean) are consistent with the diff.

Watch for: the hero change goes well beyond "halve the space" and shrinks the artwork and moves the emoji without a request in the issue (confirmed); the inset math models a layout that the code comment admits is not the real one, because the ScrollView adds the safe area a second time (confirmed); the adjust actions have no automated test beyond pure step logic (confirmed, accepted in AC 6.2).

**Verdict**: APPROVED

## High-level view

The indicator and Next fixes are small and match the issue. The indicator gets an explicit accessibility frame, label "Page indicator", value "Page N of M", and an adjustable action routed through a pure `OnboardingPaging.target` that refuses to move past either end. Next only gains a content shape.

The hero spacing is the heavy part. Instead of halving a constant, the change adds a shape-aware clearance rule plus a measured Skip size. The result is accepted by the owner and documented, but it adds a model whose assumptions differ from the real layout, and it bundles two visual changes (hero size, emoji corner) that the issue did not ask for.

Tests cover the pure logic well and the UI for Next, indicator value and frame size. The adjust action itself is only verifiable on device.

<details>
<summary>Issues (4)</summary>

1. **Unrequested visual changes** — hero 220 to 190 pt and emoji moved to `.topLeading` were not in the issue. Confirm the owner approved them in the PR description, or drop them. (confirmed)
2. **Inset model does not match real layout** — `OnboardingHeroLayout` computes a top inset assuming it is the hero top, but the page ScrollView adds the safe area again, so the "beside Skip" branch lands about one safe area lower. Either remove the double inset or simplify the rule to a constant. (confirmed)
3. **Layout shift when Skip is re-measured** — `skipSize` starts at 55x34 and updates via `onGeometryChange`, so at large text sizes the hero inset can change after first render. Check for a visible jump on launch at AX sizes. (possible: the screenshot test attaches images, but nothing asserts stability)
4. **Adjust action untested in UI** — only `OnboardingPaging` is unit tested. State in the PR that the owner verifies VoiceOver on device. (confirmed)

</details>

<details>
<summary>Details</summary>

### Hero positioning: a geometry model for a spacing request

The issue asked to halve the space between the hero and the top of the view without going under Skip. `OnboardingHeroLayout.topInset` checks whether a rounded-rectangle hero of the given width and corner radius, centered, can sit beside Skip (safe top + 8) or must go below it. The math is careful: inputs are sanitized for non-finite values, corner curvature is accounted for, and the rule is unit tested. `OnboardingView` picks the framed radius (32) for all pages because the inset is shared, which is the conservative choice.

The weakness is that the output is not what the model says it is. The comment at the call site states the ScrollView adds the top safe area on top of the inset, so the "beside Skip" result actually lands below Skip, about 40 pt higher than before. That means the clearance rule's two branches are not physically meaningful in the shipped layout, and the "halve" requirement was met by an accepted measurement rather than by construction. A reviewer maintaining this later will trust the doc comment on `OnboardingHeroLayout` and be misled. The simpler alternative is a single constant inset, or removing the extra safe-area inset so the model is true. This is not blocking because the owner accepted the position and the spec records it (AC 4.1 amended).

Two further visual changes ride along: `heroSize` 190 (was 220), `heroFallbackSize` 160 (was 180), and the emoji ZStack alignment moved from `.topTrailing` to `.topLeading`. The shrink is what makes the "beside Skip" branch reachable at common widths, so it is a consequence of the chosen design, but the issue did not request it. The PR body should list both under deviations.

`controlsAreaHeight` grew from 150 to 166 to fit the 44 pt indicator; this is a necessary knock-on and the screenshot test checks Next and the indicator are hittable on the last page at AX-XXXL.

### Page indicator as an adjustable element

The row uses `.accessibilityElement(children: .ignore)`, a label, a value, `accessibilityAdjustableAction` and the preserved `onboarding-page-indicator` identifier. The `.contentShape(.accessibility, .capsule)` addition is a good catch: the coder measured a 12 pt accessibility frame without it, and a UI test now asserts at least 44 x 44. Adjusting calls `step`, which goes through `OnboardingPaging.target` and returns nil at the ends, so there is no wraparound and no clamped double-announcement. Adjusting plays no sound and does not set `hasSeenOnboarding`, which keeps the "enter the market" flag tied to Enter/Skip only.

`move(to:)` assumes `selection` equals the page index because ids are 0, 1, 2. The code documents this, but it is a latent coupling: reordering or renumbering `OnboardingPage.all` ids would silently break paging. Low risk today.

XCUITest cannot drive `adjust` on a non-slider, so the planned UI test was removed and AC 6.2 amended. Coverage is the pure `OnboardingPagingTests` plus the owner's on-device VoiceOver check. Not tested: that the adjustable action is actually exposed to VoiceOver and that the glass capsule does not swallow the swipe gesture.

### Next capsule hit area and copy

`.contentShape(.capsule)` on the label inside the `.plain` button is the minimal fix, and the glass, hiss and identifier are untouched. `testNextTapsOutsideTextAdvance` taps at 4% from the left edge of the button frame, which proves the capsule beyond the text is live. The copy change is a one-word edit with a test, and the spec amendment records that it reverses the earlier "keep copy as written" decision for this phrase only.

</details>

<details>
<summary>File map</summary>

Full diff: `git diff origin/main...HEAD`

- `Models/OnboardingHeroLayout.swift`: new clearance rule for the hero top inset
- `Models/OnboardingPaging.swift`: new pure step logic for the pager
- `Onboarding/OnboardingView.swift`: adjustable indicator, larger dots, capsule content shape, measured Skip, `move`/`step`
- `Onboarding/OnboardingPageView.swift`: hero size constants, emoji corner
- `Onboarding/OnboardingPage.swift`: "travels an ocean"
- `Theme/AppCopy.swift`: indicator label string
- `NYCFarmerMarketsTests/*`: layout, paging, copy and page tests
- `NYCFarmerMarketsUITests/OnboardingUITests.swift`: indicator value, 44 pt frame, Next outside text, screenshots
- `.kiro/specs/onboarding-flow/*`: dated amendments

</details>
