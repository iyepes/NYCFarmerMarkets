# Requirements Document

## Introduction

The owner added three onboarding files in `NYCFarmerMarkets/Onboarding/`: `OnboardingPage` (content for three pages), `OnboardingPageView` (one scrolling page) and `OnboardingView` (swipeable pages, page dots, a Skip button and a Next / "Enter the market" button). `OnboardingView` stores completion in `@AppStorage("hasSeenOnboarding")`. Nothing uses these files yet. This feature places onboarding between the splash screen and the tabs, shows it on the first launch only, keeps existing UI tests reaching the tabs, and adds unit tests and UI tests.

Current behavior: `AppRootView` shows `SplashView` until data is available and the minimum display time has elapsed, then latches `hasDismissed` and shows `RootTabView`. `RootTabView` plays the door sound once when it first appears.

Observations about the added files that shape these requirements:

- `OnboardingView` has no accessibility identifiers. The page indicator is a single element labeled "Page N of M".
- Skip is hidden (opacity 0) and disabled on the last page. Both Skip and the last-page button set `hasSeenOnboarding` to true.
- `OnboardingPageView` uses the literal SF Symbol `"moon.stars.fill"`, and `OnboardingPage` stores literal SF Symbol names. Theme conventions require icons to come from `AppIcon`.
- Onboarding buttons use `.glass` and plain styles, so they do not hiss on press like `ThemedButtonStyle` buttons.
- Page copy, including the wording "or travel an ocean" and "Or existent farmers", is kept as written by the owner and is not changed by this feature.

The owner added three image assets in `NYCFarmerMarkets/Assets.xcassets/`: `dairy-products-pallete`, `map-image` and `pirate-ship`. In `OnboardingPage.all`, page 0 uses `pirate-ship` (illustration), page 1 uses `map-image` (framed) and page 2 uses `dairy-products-pallete` (illustration). Each of the three assets is used by exactly one page, and no page references any other image name.

## Glossary

- **App**: The Spooky Markets application (target `NYCFarmerMarkets`).
- **Splash**: `SplashView`, the launch screen shown while markets load.
- **Onboarding**: `OnboardingView`, the swipeable introduction with three pages.
- **Onboarding_Page**: One entry of `OnboardingPage.all`, with eyebrow, emoji, hero image or symbol, title, message and three bullets.
- **Root_View**: `AppRootView`, which chooses between the Splash, Onboarding and the Tabs.
- **Tabs**: `RootTabView`, the Markets, Map and Favorites tabs.
- **Onboarding_Flag**: The `UserDefaults` boolean key `hasSeenOnboarding`, true once the user has finished or skipped Onboarding.
- **Onboarding_Decision**: A pure `nonisolated` type in `Models/` that maps the Splash result and the Onboarding_Flag to the screen to show.
- **Launch_Options**: `LaunchOptions`, the parser of UI-test launch arguments.
- **Sound_Controller**: `SoundController`, which decides whether a sound cue plays.
- **Skip_Button**: The button labeled "Skip" in Onboarding.
- **Next_Button**: The bottom button of Onboarding, labeled "Next" on pages 1 and 2 and "Enter the market" on the last page.
- **Page_Indicator**: The row of dots in Onboarding with accessibility label "Page N of M".
- **UI_Test_Suite**: The XCTest cases in `NYCFarmerMarketsUITests/`.

## Requirements

### Requirement 1: Show Onboarding After the Splash

**User Story:** As a first-time user, I want to see an introduction after the splash screen, so that I understand what the app does before I use it.

#### Acceptance Criteria

1. WHEN the Splash is dismissed and the Onboarding_Flag is false, THE Root_View SHALL show Onboarding in place of the Splash.
2. WHILE Onboarding is shown, THE Root_View SHALL keep the Tabs out of the view hierarchy, so that no Tabs element (Markets, Map or Favorites tab bar item) exists in the accessibility tree.
3. WHEN Onboarding is shown, THE Onboarding SHALL display the first Onboarding_Page (page 1 of 3), with the Page_Indicator exposing the label "Page 1 of 3".
4. WHILE Onboarding is shown, THE Onboarding SHALL present exactly three Onboarding_Pages, reachable in the order defined by `OnboardingPage.all`.
5. WHEN the user swipes horizontally toward the next page on an Onboarding_Page that is not the last, THE Onboarding SHALL move to the next Onboarding_Page.
6. WHEN the user swipes horizontally toward the previous page on an Onboarding_Page that is not the first, THE Onboarding SHALL move to the previous Onboarding_Page.
7. WHEN the user swipes horizontally past the first or last Onboarding_Page, THE Onboarding SHALL remain on the current Onboarding_Page.

### Requirement 2: Skip Onboarding for Returning Users

**User Story:** As a returning user, I want to go straight to the app, so that I am not shown the introduction again.

#### Acceptance Criteria

1. WHEN the Splash phase becomes dismissed and the Onboarding_Flag is true, THE Root_View SHALL show the Tabs and SHALL NOT add Onboarding to the view hierarchy at any point during that transition.
2. WHEN the user taps the Next_Button on the last Onboarding_Page or taps the Skip_Button, THE Onboarding SHALL set the Onboarding_Flag to true before the Root_View removes Onboarding from the view hierarchy.
3. WHEN the App is launched again after the user finished or skipped Onboarding in an earlier launch, THE Root_View SHALL show the Splash first and then the Tabs, and SHALL NOT show Onboarding at any point during that launch.
4. IF the Onboarding_Flag has no stored value, THEN THE Onboarding_Decision SHALL treat the Onboarding_Flag as false.
5. WHILE the Onboarding_Flag is true, THE Root_View SHALL NOT show Onboarding again until the Onboarding_Flag is removed or set to false by a UI-test launch argument.
6. THE Onboarding_Decision SHALL return the same screen every time it is given the same Splash phase and Onboarding_Flag values, with no dependency on time, launch count, or previous results.

### Requirement 3: Navigate or Leave Onboarding

**User Story:** As a user, I want to move through the introduction or leave it at any time, so that I control how long it takes.

#### Acceptance Criteria

1. WHEN the user taps the Next_Button on an Onboarding_Page that is not the last, THE Onboarding SHALL move to the next Onboarding_Page, so that the Page_Indicator reports the page number increased by exactly 1 and the Onboarding_Flag remains unchanged.
2. WHILE an Onboarding_Page that is not the last is shown, THE Next_Button SHALL be labeled "Next".
3. WHILE the last Onboarding_Page is shown, THE Next_Button SHALL be labeled "Enter the market".
4. WHEN the user taps the Next_Button on the last Onboarding_Page, THE Onboarding SHALL set the Onboarding_Flag to true and THE Root_View SHALL show the Tabs without showing Onboarding.
5. WHILE an Onboarding_Page that is not the last is shown, THE Skip_Button SHALL be visible, enabled and exposed to VoiceOver with the label "Skip".
6. WHEN the user taps the Skip_Button, THE Onboarding SHALL set the Onboarding_Flag to true and THE Root_View SHALL show the Tabs without showing Onboarding, from any Onboarding_Page on which the Skip_Button is enabled.
7. WHILE the last Onboarding_Page is shown, THE Skip_Button SHALL be fully transparent, not tappable, and hidden from VoiceOver.
8. WHEN the user swipes horizontally to a different Onboarding_Page, THE Skip_Button and the Next_Button SHALL update their state and label to match the criteria for the page that is now shown, so that a swipe to the last page produces the same state as tapping the Next_Button to reach it.
9. WHILE an Onboarding_Page is shown, THE Page_Indicator SHALL display one dot per Onboarding_Page (3 dots), draw only the dot of the shown page in the accent color, and expose the single accessibility label "Page N of M", where N is the 1-based number of the shown page (1 to 3) and M is the page count (3).
10. IF the user taps the Next_Button or the Skip_Button repeatedly in quick succession, THEN THE Onboarding SHALL never show a page number below 1 or above M, and SHALL set the Onboarding_Flag to true at most once.

### Requirement 4: Keep Data Loading During Onboarding

**User Story:** As a user, I want the app to keep data loading while I read the introduction, so that markets are ready when I enter.

#### Acceptance Criteria

1. WHEN the App launches, THE Root_View SHALL start exactly one market load, and THE Root_View SHALL NOT start another market load when Onboarding appears or when Onboarding is left. A load started by the user tapping Retry on the Splash is the only allowed additional load.
2. WHILE Onboarding is shown and the market load started at launch is still running, THE Root_View SHALL let that load continue without interruption, and THE market store SHALL keep its current markets until the load completes.
3. WHEN the user leaves Onboarding, THE Tabs SHALL show the markets that the market store holds at that moment (at least one market, including any refresh that completed while Onboarding was shown), without showing the Splash again.
4. IF the network refresh fails while Onboarding is shown and cached markets exist, THEN THE Root_View SHALL keep showing Onboarding without an error message, and THE Tabs SHALL show the cached markets with the offline banner after the user leaves Onboarding.
5. IF the market download fails with no cached data, or the load succeeds with zero markets, THEN THE Root_View SHALL keep showing the Splash failure message and Retry button and SHALL NOT show Onboarding, for both Onboarding_Flag values.
6. WHEN the user taps Retry on the Splash and the load succeeds with at least one market, THE Root_View SHALL apply the Onboarding_Decision once the Splash minimum display time has elapsed: Onboarding if the Onboarding_Flag is false, the Tabs if it is true.
7. IF the load started by Retry fails or returns zero markets, THEN THE Root_View SHALL keep the Splash failure message and Retry button visible and SHALL NOT show Onboarding or the Tabs.

### Requirement 5: Pure Screen-Selection Logic

**User Story:** As a developer, I want the screen-selection logic in a pure type, so that it can be unit tested.

#### Acceptance Criteria

1. THE Onboarding_Decision SHALL be a `nonisolated` value type in `NYCFarmerMarkets/Models/` that imports Foundation only and has no SwiftUI dependency.
2. WHEN the Splash phase is `loading` or `failed`, THE Onboarding_Decision SHALL return the Splash for both Onboarding_Flag values (true and false).
3. WHEN the Splash phase is `dismissed` and the Onboarding_Flag is false, THE Onboarding_Decision SHALL return Onboarding.
4. WHEN the Splash phase is `dismissed` and the Onboarding_Flag is true, THE Onboarding_Decision SHALL return the Tabs.
5. WHEN the Onboarding_Decision is evaluated with the Splash phase `dismissed` and the Onboarding_Flag true, after an earlier evaluation with the Splash phase `dismissed` and the Onboarding_Flag false, THE Onboarding_Decision SHALL return the Tabs.
6. THE Onboarding_Decision SHALL hold no state between evaluations, so that each result depends only on the Splash phase and the Onboarding_Flag passed to that evaluation.
7. THE Onboarding_Page content SHALL contain exactly three pages in `OnboardingPage.all`, with these properties:
   - The three `id` values are unique.
   - The `eyebrow`, `title` and `message` of each page each contain at least one non-whitespace character.
   - Each page has exactly three bullets, and each bullet contains at least one non-whitespace character.

### Requirement 6: Accessibility

**User Story:** As a user who relies on assistive technology, I want onboarding to work with VoiceOver and larger text, so that I can read it and continue.

#### Acceptance Criteria

1. THE Onboarding SHALL expose the Skip_Button to VoiceOver with the label "Skip" and the Next_Button with a label equal to its current visible text ("Next" on pages 1 and 2, "Enter the market" on the last page), and SHALL NOT add a hint or value that repeats the label.
2. THE Onboarding SHALL hide the hero image (illustration, framed image and symbol variants), the emoji and every bullet icon from VoiceOver, so that VoiceOver navigation of an Onboarding_Page does not stop on any of them.
3. WHILE the Dynamic Type size is any size from `xSmall` up to `accessibility5`, THE Onboarding_Page SHALL be vertically scrollable and SHALL NOT truncate the eyebrow, title, message or bullets, so that every text element can be scrolled to a position fully below the Skip_Button area and fully above the Next_Button and Page_Indicator.
4. WHILE Reduce Motion is on, WHEN the user taps the Next_Button on an Onboarding_Page that is not the last, THE Onboarding SHALL show the next Onboarding_Page with no animated transition.
5. WHEN VoiceOver focus moves to an Onboarding_Page, THE Onboarding SHALL expose the title and the message each as a separate text element whose spoken text equals the visible text.
6. WHEN VoiceOver focus moves through an Onboarding_Page, THE Onboarding SHALL expose the eyebrow, title, message and the three bullets in that top-to-bottom order, with no other element between them.
7. WHILE VoiceOver is running, WHEN the user activates the Next_Button on an Onboarding_Page that is not the last, THE Onboarding SHALL move to the next Onboarding_Page, so that the user can reach every page without a horizontal swipe gesture.
8. WHEN the Onboarding_Page changes, THE Page_Indicator SHALL update its accessibility label to "Page N of M" for the new page before the next VoiceOver focus event.

### Requirement 7: Theme Conventions and Identifiers

**User Story:** As a developer, I want onboarding to follow the theme conventions, so that a theme change stays a one-file change.

#### Acceptance Criteria

1. THE Onboarding files SHALL obtain every SF Symbol through an `AppIcon` case, including the bullet icon, the three page symbols and the hero symbol, and SHALL contain no `Image(systemName:)` call and no SF Symbol name string literal.
2. THE Onboarding files SHALL obtain every color from an `AppPalette` token and SHALL contain no hex literal and no `Color.<name>` constant (such as `Color.red`).
3. THE Onboarding files SHALL set every text font, including the emoji, only through `.appFont(<role>)` with a role defined in `AppTypography`, and SHALL contain no `.font(` call and no `Font.system` or `Font.custom` call. THE hero symbol SHALL be drawn by `IconView` at 72 pt, so its size is set inside `Theme/` and not in the Onboarding files.
4. THE Onboarding SHALL define the Skip_Button label "Skip", the Next_Button labels "Next" and "Enter the market", and the Page_Indicator label template "Page N of M" in `AppCopy`, and THE Onboarding SHALL set each accessibility label equal to its visible text, with N from 1 to M.
5. THE Onboarding SHALL assign these kebab-case accessibility identifiers, each to exactly one element while Onboarding is shown: `onboarding-screen` on the root view, `onboarding-skip` on the Skip_Button, `onboarding-next` on the Next_Button, `onboarding-page-indicator` on the Page_Indicator, and `onboarding-page-<id>` on each Onboarding_Page, with `<id>` the integer id of the page (`onboarding-page-0`, `onboarding-page-1`, `onboarding-page-2`).
6. WHEN the convention-check commands from the "Convention check" section of `theme-conventions.md` are run from the repo root, THE check SHALL print zero lines for paths beginning with `NYCFarmerMarkets/Onboarding/`.
7. THE Onboarding_Pages SHALL reference only image assets that exist in `Assets.xcassets` (`dairy-products-pallete`, `map-image`, `pirate-ship`, keeping the asset names as spelled).
8. THE `AppTypography` role `splash` SHALL have a design size of 44 pt, used by the Splash screen text and the onboarding emoji.

### Requirement 8: Onboarding Sounds

**User Story:** As a user, I want sounds to behave consistently during onboarding, so that the app feels the same from the first tap.

#### Acceptance Criteria

1. WHEN the user taps the Skip_Button or the Next_Button, THE Onboarding SHALL call `play(.hiss)` on the Sound_Controller exactly once for that tap, including the tap on the Next_Button on the last Onboarding_Page.
2. WHEN the Tabs appear for the first time after Onboarding is dismissed, THE Tabs SHALL play the `.door` sound exactly once.
3. WHEN the Tabs appear after Onboarding is dismissed, THE Tabs SHALL NOT play the `.door` sound again until the next launch of the App, unless the user changes the selected tab.
4. WHILE Onboarding is shown, THE Root_View SHALL NOT create the Tabs, so that no `.door` sound for the Tabs is sent to the Sound_Controller.
5. WHILE Onboarding is shown, THE Onboarding SHALL send no cue to the Sound_Controller other than the `.hiss` cue from criterion 1. Swiping between Onboarding_Pages sends no cue.
6. IF VoiceOver is running or the user has turned sounds off, THEN THE Sound_Controller SHALL play no Onboarding sound and SHALL NOT start any audio from an Onboarding cue.
7. WHERE the launch argument `-uiTestingMuteSounds` is passed, THE Sound_Controller SHALL play no sound during Onboarding, and THE App SHALL NOT start an audio session for Onboarding.

### Requirement 9: UI Test Launch Arguments

**User Story:** As a developer, I want existing UI tests to keep reaching the tabs, so that adding onboarding does not break them.

#### Acceptance Criteria

1. WHERE the launch argument `-uiTestingSkipOnboarding` is passed without `-uiTestingResetOnboarding`, THE Launch_Options SHALL set `skipOnboarding` to true and THE App SHALL write true to the Onboarding_Flag in `UserDefaults` during App initialization, before the Root_View is created.
2. WHERE the launch argument `-uiTestingResetOnboarding` is passed, THE Launch_Options SHALL set `resetOnboarding` to true and THE App SHALL remove the Onboarding_Flag from `UserDefaults` during App initialization, before the Root_View is created, so that the flag reads false and Onboarding is shown after the Splash.
3. WHERE the launch argument `-uiTestingReset` is passed without `-uiTestingResetOnboarding`, THE App SHALL write true to the Onboarding_Flag during App initialization, before the Root_View is created, so that the existing UI_Test_Suite lands on the Tabs after the Splash. The existing clearing of favorites and the sound setting by `-uiTestingReset` SHALL remain unchanged.
4. IF `-uiTestingResetOnboarding` is passed together with `-uiTestingSkipOnboarding`, `-uiTestingReset`, or both, THEN THE App SHALL remove the Onboarding_Flag and SHALL NOT write true to it, so that `-uiTestingResetOnboarding` takes precedence.
5. WHEN none of `-uiTestingSkipOnboarding`, `-uiTestingResetOnboarding` and `-uiTestingReset` is passed, THE App SHALL NOT write to or remove the Onboarding_Flag, so that a stored true stays true and an absent flag stays absent.
6. THE Launch_Options SHALL parse `-uiTestingSkipOnboarding` and `-uiTestingResetOnboarding` as boolean flags that are true only when the exact, case-sensitive argument string appears in the launch arguments, that default to false, and that do not consume the following argument as a value, in the same way as `-uiTestingMuteSounds` and `-uiTestingFailDownload`.
7. THE tech steering file SHALL list `-uiTestingSkipOnboarding` and `-uiTestingResetOnboarding` under "Launch arguments", each with a one-line description of its effect on the Onboarding_Flag and the precedence stated in criterion 4.

### Requirement 10: Tests

**User Story:** As a maintainer, I want tests for onboarding, so that regressions are caught.

#### Acceptance Criteria

1. THE unit tests SHALL cover the Onboarding_Decision in `OnboardingDecisionTests.swift` using Swift Testing, with one `@Test` assertion for each of the four combinations of Splash phase (not dismissed, dismissed) and Onboarding_Flag (false, true), and one assertion that the same inputs called twice return the same screen.
2. THE unit tests SHALL cover the Launch_Options arguments in `LaunchOptionsTests.swift` using Swift Testing, with assertions that:
   - `skipOnboarding` and `resetOnboarding` are both false when neither `-uiTestingSkipOnboarding` nor `-uiTestingResetOnboarding` is passed.
   - `skipOnboarding` is true when only `-uiTestingSkipOnboarding` is passed.
   - `resetOnboarding` is true when only `-uiTestingResetOnboarding` is passed.
   - When both arguments are passed, the onboarding outcome is a reset, as in requirement 9.4.
3. THE unit tests SHALL cover `OnboardingPage.all` in `OnboardingPageTests.swift` using Swift Testing, with assertions that the array has exactly 3 elements, that the 3 ids are unique, that each eyebrow, title and message is non-empty after trimming whitespace, and that each page has exactly 3 bullets.
4. THE UI_Test_Suite SHALL include a test that launches with `-uiTestingReset`, `-uiTestingResetOnboarding` and `-uiTestingMuteSounds`, waits up to 30 seconds for `onboarding-screen` to exist, and checks that the Markets, Map and Favorites tab items do not exist.
5. THE UI_Test_Suite SHALL include a test that launches with the same three arguments, taps `onboarding-next` twice, and checks that the label of `onboarding-next` is "Enter the market" and that `onboarding-skip` is not hittable. The test SHALL then tap `onboarding-next` and check that the Markets, Map and Favorites tab items exist within 30 seconds and that `onboarding-screen` does not exist.
6. THE UI_Test_Suite SHALL include a test that launches with the same three arguments, taps `onboarding-skip` on the first page, and checks that the Markets, Map and Favorites tab items exist within 30 seconds and that `onboarding-screen` does not exist.
7. THE UI_Test_Suite SHALL include a test that launches with the same three arguments and finishes Onboarding with `onboarding-next` or `onboarding-skip`. The test SHALL then terminate the App and relaunch it with only `-uiTestingMuteSounds`. After the relaunch it SHALL check that the Markets, Map and Favorites tab items exist within 30 seconds and that `onboarding-screen` does not exist at any point in that window.
8. THE UI_Test_Suite SHALL include a test that launches with the same three arguments, swipes left once on `onboarding-screen`, and checks that the label of `onboarding-page-indicator` is "Page 2 of 3".
9. THE UI_Test_Suite SHALL include `-uiTestingMuteSounds` in the launch arguments of every launch and relaunch in every UI test, including the existing `setUpWithError` and the relaunch in `testSoundToggleIsSaved`.
10. WHEN the full test command from `tech.md` runs, THE existing UI_Test_Suite cases SHALL pass with no changes to their accessibility identifiers and with the same launch arguments they use before this feature (`-uiTestingReset` and `-uiTestingMuteSounds`, plus the existing per-test arguments).
11. WHEN the iOS and macOS build commands from `tech.md` run, THE App SHALL build with zero warnings in the new and changed files and with a total warning count no higher than the count on `origin/main`.
12. THE unit tests SHALL assert in `OnboardingPageTests.swift` that every non-nil `heroImage` name referenced by `OnboardingPage.all` resolves to an image asset in the app bundle.
13. THE unit tests in `AppTypographyTests.swift` SHALL expect the `splash` role design size to be 44 pt, and every existing typography test SHALL pass.

## Decisions and Assumptions

Owner decisions:

- Decision: `-uiTestingReset` also marks onboarding as seen (requirement 9.3), so no existing UI test changes.
- Decision: Onboarding waits for loaded data, as the Splash does now. The user sees Onboarding only when data or cache is ready (requirement 4).
- Decision: the page copy, including "or travel an ocean" and "Or existent farmers", is intended and is not changed by this feature.
- Decision: the onboarding buttons keep the `.glass` style instead of `ThemedButtonStyle`, and the hiss cue is sent explicitly in the button actions (requirement 8.1).
- Decision: the hero symbol size is set by `IconView` (72 pt) inside `Theme/` (requirement 7.3).
- Decision: the `splash` role grows from 40 pt to 44 pt for the onboarding emoji; the Splash screen text grows with it (requirements 7.8, 10.13).

Assumptions:

- Assumption: onboarding shows once per install, stored in the existing `hasSeenOnboarding` key. There is no "replay onboarding" entry point in this feature.

Out of scope: visionOS verification, replaying onboarding from settings, localization.
