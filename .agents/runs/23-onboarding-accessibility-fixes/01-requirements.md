# Requirements: Onboarding accessibility fixes (issue #23)

## Summary

Follow-up to PR #22 (feature `onboarding-flow`). Four small fixes in `NYCFarmerMarkets/Onboarding/`: make the page-dot row adjustable with VoiceOver and larger, make the whole Next capsule tappable, halve the space above the hero image, and correct one word of page 0 copy. The existing spec in `.kiro/specs/onboarding-flow/` gets a dated "Amendment: onboarding accessibility fixes" (written by the record_spec step); no new spec is created.

Current behavior (read from the code):
- `OnboardingView.bottomControls` draws the dots (8 pt circles, 8 pt spacing, 14/10 pt padding in a glass capsule) as one element with `.accessibilityElement(children: .ignore)`, label "Page N of M" and identifier `onboarding-page-indicator`. It has no adjustable trait or actions.
- The Next button uses `.buttonStyle(.plain)`. The glass capsule is applied to the `Text` inside the label, so the hit area is only the text.
- `OnboardingPageView` rests content below `topInset` = safe-area top + `skipAreaHeight` (48 pt: Skip height about 34 pt, 8 pt top padding, small gap).
- `OnboardingPage.all[0].message` contains "or travel an ocean".

## Glossary

Terms from `.kiro/specs/onboarding-flow/requirements.md` are reused: Onboarding, Onboarding_Page, Page_Indicator, Next_Button, Skip_Button, Sound_Controller, UI_Test_Suite. Added here:
- **Hero**: the hero image (or symbol) block at the top of an Onboarding_Page, with its emoji overlay.
- **Skip_Area**: the region occupied by the Skip_Button, from the top of the screen to the bottom of the button including its 8 pt top padding.

## Functional Requirements

### Requirement 1: Adjustable Page_Indicator for VoiceOver

**User Story:** As a VoiceOver user, I want to change pages from the page dots, so that I can move through Onboarding without relying on a horizontal swipe on the page.

#### Acceptance Criteria

1. THE Page_Indicator SHALL remain a single accessibility element with identifier `onboarding-page-indicator` and SHALL expose the adjustable trait.
2. THE Page_Indicator SHALL expose the accessibility value "Page N of M" (N = current page number, M = page count), using the existing `AppCopy.onboardingPageIndicator(page:count:)` text, and SHALL update it whenever the current page changes by any means (swipe, Next, adjust).
3. WHEN VoiceOver sends increment (swipe up) to the Page_Indicator and the current page is not the last, THE Onboarding SHALL move to the next Onboarding_Page.
4. WHEN VoiceOver sends decrement (swipe down) to the Page_Indicator and the current page is not the first, THE Onboarding SHALL move to the previous Onboarding_Page.
5. WHEN increment is sent on the last page or decrement on the first page, THE Onboarding SHALL stay on the current Onboarding_Page and SHALL NOT set the Onboarding_Flag.
6. WHEN the Page_Indicator is adjusted, THE Onboarding SHALL follow the Reduce Motion setting as the Next_Button does (animated change unless Reduce Motion is on).
7. THE accessibility label of the Page_Indicator SHALL stay plain and descriptive (no spooky wording).

### Requirement 2: Larger dots with a 44 pt tap target

**User Story:** As a user with low vision or limited dexterity, I want bigger page dots that are easier to see and hit.

#### Acceptance Criteria

1. THE dots SHALL be larger than the current 8 pt diameter and SHALL have more spacing than the current 8 pt. Exact sizes are a design decision. (Assumption: roughly 12 pt dots and 12 pt spacing.)
2. THE Page_Indicator row SHALL have a hit and accessibility frame of at least 44 pt in height. (Assumption: the width is not constrained beyond the dots and padding; 44 pt is the minimum in both dimensions.)
3. THE glass capsule look behind the dots, and the existing accent/secondary dot colors, SHALL be kept, using `AppPalette` tokens only.
4. THE larger row SHALL fit above the Next_Button inside the bottom controls without moving the Next_Button off screen at the largest Dynamic Type size, and without overlapping page content in a way that hides it (content still scrolls under the controls as before; if `controlsAreaHeight` must grow, the design adjusts it).

### Requirement 3: Whole Next capsule is tappable

**User Story:** As a user, I want to tap anywhere on the Next button, so that I do not have to hit the text exactly.

#### Acceptance Criteria

1. WHEN the user taps anywhere inside the Next_Button capsule, including the padded area left and right of the text, THE Onboarding SHALL perform the same action as tapping the text (advance, or on the last page set the Onboarding_Flag).
2. THE Next_Button SHALL keep its glass look (tinted, interactive glass in a capsule), the `onboarding-next` identifier, its accessibility label, and its hiss through `Sound_Controller`, played once per tap.
3. THE hit shape SHALL match the capsule (for example `.contentShape(.capsule)`), so taps outside the capsule do not activate the button.

### Requirement 4: Half the space above the Hero

**User Story:** As a user, I want the hero image closer to the top, so that more of the page content is visible without scrolling.

#### Acceptance Criteria

1. (Amended 2026-11-17, accepted by the owner): THE top of the Hero on each Onboarding_Page SHALL be about 40 pt higher than before this change (the old inset was safe-area top + 48 pt) and SHALL sit below the Skip button, never under it. The page ScrollView adds the top safe area on top of the computed inset, so `OnboardingHeroLayout`'s "beside Skip" result (safe-area top + 8 pt) places the Hero about one safe area lower, below Skip rather than beside it (iPhone 17 screenshot at default text: Hero top about 129 pt, Skip bottom about 104 pt). The owner accepted this outcome; the 2026-11-14 decisions below still set the Hero size, emoji position and clearance rule. Original wording, kept for the record: (Owner decision, 2026-11-14, option (c), reworded from "half"): THE top of the Hero on each Onboarding_Page SHALL be at safe-area top + 8 pt (about 40 pt higher than today) whenever the Hero clears the Skip button, as measured at scroll offset zero; otherwise it SHALL sit just below Skip. Clearance SHALL be shape-aware: for circular heroes (illustration, symbol fallback) the check uses the circle's horizontal extent at the height of Skip's bottom edge, for the framed hero its rounded-rectangle extent (owner decision, 2026-11-14), so the Hero rises on 375 pt and wider iPhones at the default text size.
2. THE Hero SHALL NOT overlap the Skip button at scroll offset zero, on any device, at any Dynamic Type size, and on the last page (where Skip is hidden, the same position is kept so pages do not jump).
3. THE change SHALL apply to all three pages and to both hero styles (`illustration`, `framed`) and the symbol fallback. THE Hero SHALL be 190 pt wide (symbol fallback circle 160 pt), and the emoji SHALL move to the left of the Hero (owner decision, 2026-11-14).
4. Content SHALL still scroll under the Skip and bottom controls as before.

### Requirement 5: Copy fix on page 0

**User Story:** As a reader, I want grammatical copy.

#### Acceptance Criteria

1. THE message of `OnboardingPage.all[0]` SHALL read "...crosses coast to coast or travels an ocean before it reaches you..." (only "travel" becomes "travels"; the rest of the text is unchanged).
2. THE other pages' copy, including "Or existent farmers", SHALL NOT change.
3. THE spec amendment SHALL record that this reverses the earlier "keep copy as written" decision for this phrase only.

### Requirement 6: Tests

#### Acceptance Criteria

1. THE UI_Test_Suite SHALL include a test that taps the Next_Button at a point inside the capsule but outside its text (for example a coordinate near the left edge) and verifies the page advances (Page_Indicator value becomes "Page 2 of 3").
2. (Amended 2026-11-17, owner decision): THE Page_Indicator SHALL expose the value "Page N of M"; the adjust behavior is covered by `OnboardingPagingTests` plus the owner's VoiceOver check. XCUITest's `adjust(toNormalizedSliderPosition:)` throws "Can only adjust position of slider elements" on this element, so no UI test drives increment/decrement. Original wording: THE UI_Test_Suite SHALL include tests that call the Page_Indicator's increment and decrement adjust actions (`adjust(toNormalizedSliderPosition:)` or the XCUI equivalent that triggers accessibility increment/decrement) and verify "Page N of M" values, including the no-op at the first and last page.
3. THE UI_Test_Suite SHALL verify the Page_Indicator frame height is at least 44 pt.
4. Existing onboarding UI tests that read the Page_Indicator "label" SHALL be updated to the new value where the label/value split requires it. Existing identifiers are not renamed.
5. IF a unit test is useful for any pure logic extracted (for example page-step clamping), it SHALL be a Swift Testing test in `NYCFarmerMarketsTests/<Type>Tests.swift` and the logic SHALL be a `nonisolated` type in `Models/`. If no logic is extracted, no unit test is required. Copy change coverage: an existing or new unit test SHALL assert page 0 contains "travels an ocean".
6. All UI tests keep passing `-uiTestingMuteSounds`.

## Non-Functional Requirements

1. Colors come only from `AppPalette` tokens; icons only from `AppIcon`; no new literals outside `Theme/`.
2. No new dependencies. No `project.pbxproj` edits.
3. The iOS build and unit tests pass, the macOS build passes (the shared `OnboardingView` compiles there; the macOS pager shows one page at a time and the adjustable behavior applies equally), and the onboarding UI tests pass.
4. Errors and logging: none needed; no new failure paths.

## Assumptions

- Sizes (dot diameter, spacing, row height) are not specified in the issue beyond "larger", "more spacing" and "at least 44 pt"; the design picks values.
- "Space between the hero image and the top of the view" is read as the distance from the top of the view (screen top, including the safe area) to the top of the Hero at scroll offset zero, which is now safe-area top + 48 pt. Halving this literally would put the Hero under the Skip button (Skip bottom is about safe-area top + 42 pt), which the issue forbids. The design must therefore define the reduction concretely, for example by halving the gap added on top of the Skip_Area's bottom edge / the reducible part of the margin, and clamp so the Hero never overlaps the Skip_Area. If the design finds the only non-overlapping result is a small reduction, it states the numbers. This is flagged for design review.
- VoiceOver on a physical device is verified by the owner; UI tests cover the adjust actions only through XCUITest.
- Tests for increment/decrement use whatever XCUITest can trigger on an adjustable element (`adjust(toNormalizedSliderPosition:)` may not drive increment/decrement on non-slider elements; the design picks the approach, e.g. a `XCUIElement` accessibility action or a fallback to checking the adjustable trait).

## Out of Scope

- Changing other onboarding copy, images, page count, Skip behavior or sounds (except the Hero size and emoji position in Requirement 4.3, by owner decision).
- Redesigning the glass style or fonts.
- New launch arguments (existing ones suffice).
- Voice Control, Switch Control or Full Keyboard Access tuning beyond what the adjustable element gives for free.
- On-device VoiceOver verification by the agent (owner checks).
