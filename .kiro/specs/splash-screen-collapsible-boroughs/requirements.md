# Requirements Document

## Introduction

This feature adds two behaviors to the NYC Farmer Markets iOS app. First, a splash screen appears on every launch, showing the app logo and an animated indicator that market data is downloading. The splash gates access to the tabs until market data is available. Second, the borough sections in the Markets list become collapsible and expandable by tapping the section header, and all sections start collapsed.

## Glossary

- **App**: The NYC Farmer Markets iOS application.
- **Splash_Screen**: The full-screen view shown at launch before the Root_Tab_View is reachable.
- **Root_Tab_View**: The tab container holding the Markets, Map and Favorites tabs.
- **Market_Store**: The observable store that holds the market list, the load state, and the cached-data flag.
- **Market_Data**: The list of farmers markets held by the Market_Store.
- **Cached_Data**: Market data previously saved on the device and loaded by the Market_Store.
- **Data_Available**: The condition in which the Market_Store holds a non-empty Market_Data list, from either Cached_Data or a successful download.
- **Minimum_Display_Time**: The minimum duration of 1 second for which the Splash_Screen stays visible after launch.
- **Logo**: The carrot line-art app icon drawn on the appIconBackground color from the App_Palette.
- **Loading_Indicator**: The animated element on the Splash_Screen showing that data is downloading.
- **Retry_Button**: The button on the Splash_Screen that starts a new download attempt.
- **Markets_List**: The searchable list in the Markets tab that groups markets by borough.
- **Borough_Section**: One group of markets in the Markets_List, identified by borough name.
- **Section_Header**: The whole header row of a Borough_Section, containing the borough name, the market count and a chevron.
- **Search_Query**: The text entered in the Markets_List search field, ignoring leading and trailing whitespace.
- **App_Palette**: The set of color tokens in AppPalette used for all colors in the App.
- **App_Icon_Registry**: The AppIcon enumeration through which all icons are referenced.
- **Reduce_Motion**: The iOS accessibility setting that asks apps to minimize animation.
- **UI_Test_Reset_Argument**: The `-uiTestingReset` launch argument used by UI tests.

## Requirements

### Requirement 1: Launch splash screen

**User Story:** As a user, I want to see a branded splash screen when I open the app, so that I know the app is starting and loading market data.

#### Acceptance Criteria

1. WHEN the App launches, THE Splash_Screen SHALL display the Logo and the Loading_Indicator.
2. THE Splash_Screen SHALL display the Logo on the appIconBackground color from the App_Palette.
3. THE App_Icon_Registry SHALL provide a case that references a new Logo image asset derived from Design/AppIcon.svg.
4. WHILE the Splash_Screen is visible, THE Root_Tab_View SHALL remain unreachable to the user.
5. THE Splash_Screen SHALL use only color tokens from the App_Palette and only icons from the App_Icon_Registry.

### Requirement 2: Splash dismissal

**User Story:** As a user, I want the splash to disappear as soon as my data is ready, so that I can start browsing without unnecessary waiting.

#### Acceptance Criteria

1. WHEN Data_Available is reached and at least the Minimum_Display_Time has elapsed since launch, THE App SHALL dismiss the Splash_Screen and show the Root_Tab_View.
2. WHEN Data_Available is reached before the Minimum_Display_Time has elapsed, THE App SHALL keep the Splash_Screen visible until the Minimum_Display_Time has elapsed.
3. WHEN the Market_Store loads Cached_Data, THE App SHALL treat Data_Available as reached.
4. WHEN the App launches, THE App SHALL start the market data load once, from the Splash_Screen phase.
5. WHEN the Splash_Screen is dismissed, THE App SHALL show the Root_Tab_View without a second initial loading view in the Markets tab.

### Requirement 3: Download failure recovery

**User Story:** As a user with no saved data and a failed download, I want to see what went wrong and be able to try again, so that I am not stuck on a blank screen.

#### Acceptance Criteria

1. IF the download fails and the Market_Store holds no Cached_Data, THEN THE Splash_Screen SHALL remain visible and display the error message from the Market_Store.
2. IF the download fails and the Market_Store holds no Cached_Data, THEN THE Splash_Screen SHALL display the Retry_Button.
3. WHEN the user activates the Retry_Button, THE Market_Store SHALL start a new download attempt.
4. WHEN the user activates the Retry_Button, THE Splash_Screen SHALL display the Loading_Indicator and hide the error message until the attempt completes.
5. WHEN a retry succeeds, THE App SHALL dismiss the Splash_Screen and show the Root_Tab_View.
6. IF the download fails and the Market_Store holds Cached_Data, THEN THE App SHALL dismiss the Splash_Screen after the Minimum_Display_Time and show the offline banner in the Markets tab.

### Requirement 4: Reduce Motion

**User Story:** As a user who relies on Reduce Motion, I want the loading animation to respect that setting, so that the app is comfortable to use.

#### Acceptance Criteria

1. WHILE Reduce_Motion is disabled, THE Loading_Indicator SHALL display a continuous animation.
2. WHILE Reduce_Motion is enabled, THE Loading_Indicator SHALL display a static, non-animated representation of the loading state.
3. WHILE Reduce_Motion is enabled, THE Splash_Screen SHALL dismiss without a motion transition.

### Requirement 5: Splash accessibility

**User Story:** As a VoiceOver user, I want the splash screen to be described in plain language, so that I understand what the app is doing.

#### Acceptance Criteria

1. WHILE the Loading_Indicator is visible, THE Splash_Screen SHALL expose an accessibility label of "Loading farmers markets".
2. THE Splash_Screen SHALL expose the Logo to assistive technologies with the accessibility label "NYC Farmer Markets".
3. THE Splash_Screen SHALL expose the accessibility identifier "splash-screen" on its root view.
4. THE Retry_Button SHALL expose the accessibility identifier "splash-retry" and the accessibility label "Retry loading markets".
5. WHEN the Splash_Screen displays an error message, THE Splash_Screen SHALL expose the accessibility identifier "splash-error" on the message.

### Requirement 6: Collapsible borough sections

**User Story:** As a user, I want to expand or collapse a borough by tapping its name, so that I can scan the list by borough and see only the markets I care about.

#### Acceptance Criteria

1. WHEN the Markets_List first appears after launch, THE Markets_List SHALL show every Borough_Section collapsed.
2. WHEN the user taps anywhere on a Section_Header of a collapsed Borough_Section, THE Markets_List SHALL expand that Borough_Section and show its markets.
3. WHEN the user taps anywhere on a Section_Header of an expanded Borough_Section, THE Markets_List SHALL collapse that Borough_Section and hide its markets.
4. THE Section_Header SHALL display the borough name, the market count and a chevron that indicates the expanded or collapsed state.
5. WHEN a Borough_Section expands or collapses, THE Markets_List SHALL animate the change, except WHILE Reduce_Motion is enabled, when THE Markets_List SHALL apply the change without animation.
6. WHEN the App is relaunched, THE Markets_List SHALL show every Borough_Section collapsed.
7. THE Section_Header SHALL use only color tokens from the App_Palette and only icons from the App_Icon_Registry.

### Requirement 7: Search auto-expand

**User Story:** As a user searching for a market, I want matching boroughs to open automatically, so that I can see results without extra taps.

#### Acceptance Criteria

1. WHILE the Search_Query is not empty, THE Markets_List SHALL show every Borough_Section that contains at least one matching market as expanded.
2. WHILE the Search_Query is not empty, THE Markets_List SHALL show only the markets that match the Search_Query within each expanded Borough_Section.
3. WHEN the user clears the Search_Query, THE Markets_List SHALL restore each Borough_Section to the expanded or collapsed state it had before the Search_Query was entered.
4. WHEN the user taps a Section_Header while the Search_Query is not empty, THE Markets_List SHALL toggle that Borough_Section between expanded and collapsed.

### Requirement 8: Section header accessibility

**User Story:** As a VoiceOver user, I want each borough header to announce its name, count and state, so that I can navigate and operate the list without seeing it.

#### Acceptance Criteria

1. THE Section_Header SHALL expose the header accessibility trait.
2. THE Section_Header SHALL expose an accessibility label in the form "<borough name>, <count> markets".
3. WHILE a Borough_Section is collapsed, THE Section_Header SHALL expose the accessibility value "Collapsed" and the hint "Double tap to expand".
4. WHILE a Borough_Section is expanded, THE Section_Header SHALL expose the accessibility value "Expanded" and the hint "Double tap to collapse".
5. THE Section_Header SHALL expose the accessibility identifier "section-header-<borough name>", where spaces in the borough name are replaced by hyphens.

### Requirement 9: Test coverage

**User Story:** As a developer, I want the existing tests to keep passing and new behavior to be covered, so that regressions are caught.

#### Acceptance Criteria

1. WHEN the UI tests launch the App with the UI_Test_Reset_Argument, THE App SHALL show the Splash_Screen and then the Root_Tab_View once data is available.
2. THE existing UI tests that rely on the identifiers market-row, market-list, close-detail, favorite-toggle, more-info and favorites-empty SHALL pass after expanding a Borough_Section where a market row is required.
3. THE unit test suite SHALL include Swift Testing tests for the splash dismissal decision across the combinations of Data_Available, Minimum_Display_Time elapsed, and error state.
4. THE unit test suite SHALL include Swift Testing tests for the expanded-section decision across the combinations of manual toggle state and Search_Query presence.
5. THE UI test suite SHALL include tests that verify the Splash_Screen appears, the Borough_Sections start collapsed, tapping a Section_Header expands and collapses the Borough_Section, and a search auto-expands matching Borough_Sections.
6. THE UI test suite SHALL include a test that verifies the Retry_Button appears with the error message when the download fails and no Cached_Data exists.
