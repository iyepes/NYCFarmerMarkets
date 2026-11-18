Onboarding fixes: adjustable page dots, full-capsule Next tap, hero spacing, copy
## Summary

Follow-up to PR #22 (onboarding flow). Four small fixes found while testing onboarding, mainly with VoiceOver.

1. **Page dots are not adjustable with VoiceOver.** The dot row in `OnboardingView` is one element labeled "Page N of M" (`.accessibilityElement(children: .ignore)`). VoiceOver reads it but cannot change pages. The dots are also small and close together.
2. **Next button only taps on its text.** The glass capsule is drawn on the `Text` inside a `.plain` button, so only the text area responds to taps.
3. **Hero image sits too low.** The space between the hero image and the top of the view in `OnboardingPageView` is too large.
4. **Copy.** Page 0 in `OnboardingPage.all` says "travel an ocean". It should say "travels an ocean". This reverses the earlier "keep copy as written" decision for this phrase only.

## Acceptance criteria

- [ ] The page indicator in `OnboardingView` is an adjustable accessibility element: VoiceOver swipe up moves to the next page, swipe down to the previous page, and it does nothing past the first or last page.
- [ ] The indicator's accessibility value reads "Page N of M" and its identifier stays `onboarding-page-indicator`.
- [ ] The dots are larger and have more spacing, and the indicator row has a tap target of at least 44 pt in height.
- [ ] The whole Next capsule is tappable, not just its text. The glass look, the hiss sound and the identifier `onboarding-next` are unchanged.
- [ ] The space between the hero image and the top of the view in `OnboardingPageView` is halved, and the image does not go under the Skip area.
- [ ] Page 0 copy reads "travels an ocean".
- [ ] UI tests cover tapping Next outside its text and the indicator's increment and decrement actions, where reachable.
- [ ] iOS and macOS builds succeed and the existing unit and UI tests pass.
- [ ] The existing spec in `.kiro/specs/onboarding-flow/` gets a dated "Amendment: onboarding accessibility fixes" instead of a new spec.

## Not verified by the agent

VoiceOver behavior on a physical device is checked by the owner.
