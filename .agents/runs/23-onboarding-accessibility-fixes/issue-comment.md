## Plan recorded

The plan is recorded as a dated "Amendment: onboarding accessibility fixes" in `.kiro/specs/onboarding-flow/` (requirements, design, tasks), not as a new spec.

### Key requirements
- **Page dots (VoiceOver):** one element, identifier `onboarding-page-indicator`, adjustable. Swipe up/down moves to the next/previous page, value "Page N of M", no-op at the first and last page, Reduce Motion respected.
- **Dot size:** 12 pt dots, 12 pt spacing, row at least 44 x 44 pt, glass capsule and `AppPalette` colors kept.
- **Next button:** the whole glass capsule is tappable (`.contentShape(.capsule)`); look, hiss and `onboarding-next` unchanged.
- **Hero spacing:** a literal half would put the hero under Skip. Owner decision: hero top at safe-area top + 8 pt (about 40 pt higher) when it clears Skip, otherwise just below Skip; hero 190 pt (fallback 160 pt); emoji moves to the left.
- **Copy:** page 0 "travel an ocean" becomes "travels an ocean". This reverses the earlier "keep copy as written" decision for this phrase only.

### Design approach
- `OnboardingView`: `.accessibilityAdjustableAction`, label "Page indicator", value "Page N of M", shared `move(to:)`, Skip size measured with `onGeometryChange`.
- New pure `nonisolated` types in `Models/`: `OnboardingPaging` (page step) and `OnboardingHeroLayout` (shape-aware hero clearance), both with Swift Testing tests.
- `OnboardingPageView`: shared hero size constants, emoji at `topLeading`.

### Tasks
- [ ] 1. Copy fix and indicator label string (+ unit tests)
- [ ] 2. Pure paging logic (`OnboardingPaging`) and tests
- [ ] 3. Hero clearance logic (`OnboardingHeroLayout`) and tests
- [ ] 4. Hero size and emoji position in `OnboardingPageView`
- [ ] 5. `OnboardingView`: adjustable larger indicator, whole-capsule Next, measured Skip, hero inset
- [ ] 6. UI tests: Next tapped outside its text, indicator frame, adjust actions (spike first), screenshots at default and largest text size
- [ ] 7. Full verification (iOS and macOS builds, unit and UI tests, convention check)

### Not verified by the agent
VoiceOver on a device (owner checks). `adjust(toNormalizedSliderPosition:)` on a non-slider element may not work in XCUITest; if the spike fails, the workflow asks before changing the acceptance criterion.
