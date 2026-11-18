# Code review: feature/23-onboarding-accessibility-fixes

Verdict: APPROVED. No blockers.

## Requirement check
- Indicator (OnboardingView.swift, bottomControls): the dots are 12 pt with 12 pt spacing. The row has `minWidth` and `minHeight` of 44 and `.contentShape(.accessibility, .capsule)`. It keeps `.accessibilityElement(children: .ignore)`. The label is "Page indicator", the value is "Page N of M", and `.accessibilityAdjustableAction` steps pages through `OnboardingPaging.target`. The identifier `onboarding-page-indicator` is kept. The adjust action plays no sound and never sets `hasSeenOnboarding`. Moves past either end return nil and do nothing.
- Next: `.contentShape(.capsule)` is on the label, inside the `.plain` button. The glass effect, hiss and identifier are unchanged. `testNextTapsOutsideTextAdvance` taps at 4% of the button width, which is outside the text.
- Copy: "travels an ocean" is changed and covered by `pageCopyFixes`.
- Hero spacing: the hero moves up about 40 pt and stays below Skip. This is the owner's accepted amendment (spec AC 4.1). The 190 pt hero size and the emoji at the leading corner are owner decisions from 2026-11-14 (AC 4.3). They are recorded in the spec, so they are not unrequested scope.
- Spec: the amendment is in the existing `onboarding-flow` folder, and no new spec folder was created.
- Conventions: there are no color or icon literals. The new logic types are `nonisolated`. Unit tests use Swift Testing and UI tests use XCTest. Nothing under `.agents/tasks/` is committed.
- Verification evidence in the commit messages: the full iOS test run passed with 165 tests and 0 failures, the macOS build succeeded, and the theme check found nothing. Not verified: VoiceOver on device (the owner checks it) and visionOS.

## Non-blocking notes (no change required)
- `OnboardingView.swift`, the comment above `pager(topInset:...)`: the "beside Skip" branch of `OnboardingHeroLayout` ends up below Skip on screen, because the ScrollView adds the safe area on top of the inset. The comment and the spec both document this.
- The adjust action has no UI test because XCUITest `adjust(toNormalizedSliderPosition:)` only works on sliders. The spec amends AC 6.2 and relies on the `OnboardingPaging` unit tests plus the owner's VoiceOver check.
