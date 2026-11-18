# Merged code review: feature/23-onboarding-accessibility-fixes

Verdict: APPROVED. No blocking findings, and every task in `.kiro/specs/onboarding-flow/tasks.md` is checked `- [x]` (original tasks 1 to 11 and amendment tasks 1 to 7).

Both reviewers (agent and semantic) approved. They agree on all four requirements: adjustable indicator with 44 pt target, whole-capsule Next, hero spacing, and "travels an ocean".

## Findings (all non-blocking)

1. **Inset model does not match the real layout** (both reviewers). The ScrollView adds the safe area on top of `OnboardingHeroLayout`'s inset, so the "beside Skip" branch lands below Skip. The owner accepted the position, and the spec records it (AC 4.1). A comment and the spec document it. Follow-up option: simplify to a constant.
2. **Unrequested visual changes** (both reviewers; the agent reviewer treats them as owner decisions). Hero size 220 to 190 and 180 to 160, and the emoji moved to the leading corner. They are recorded in the spec (AC 4.3, 2026-11-14). List them as deviations in the PR body.
3. **Adjust action has no UI test** (both reviewers). XCUITest `adjust(toNormalizedSliderPosition:)` works only on sliders. AC 6.2 is amended, and `OnboardingPagingTests` plus the owner's on-device VoiceOver check cover it. State this in the PR.
4. **Skip size re-measured after first render** (semantic reviewer, possible). `skipSize` starts at its default and updates via `onGeometryChange`, so the hero inset may shift at accessibility text sizes. Screenshots were attached, but nothing asserts stability.
5. **`selection` equals page id equals index** (semantic reviewer, low risk). Renumbering `OnboardingPage.all` ids would break paging. It is documented in a comment.

## Verification evidence
Full iOS test run passed (165 tests, 0 failures), macOS build succeeded, and the theme check found nothing. Not verified: VoiceOver on a device (the owner checks it) and visionOS.
