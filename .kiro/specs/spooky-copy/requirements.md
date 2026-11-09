# Requirements Document

## Introduction

This feature gives the visible text of the NYC Farmer Markets app a consistent, light spooky tone that matches the existing copy ("No haunts yet", "Favorite a market to summon it here.", and the failure titles such as "Something spooked the data"). It also moves all user-facing text into one place, in the same way `AppPalette` holds colors and `AppIcon` holds icons. VoiceOver text stays plain, so the theme never gets in the way of understanding.

The failure messages in `LoadFailureMessage` already follow this tone and are out of scope.

## Glossary

- **App**: The NYC Farmer Markets application.
- **App_Copy**: The single type that holds user-facing text, as `nonisolated` static strings and pure functions.
- **Spooky_Copy**: Visible text with a light spooky flavor: at most one spooky word or phrase per message, drawn from a small recurring vocabulary (summon, haunt, lurk, fog, mist, spooked).
- **Plain_Label**: The accessibility label, value or hint that a screen reader announces. It describes the function in plain language, with no spooky wording.
- **Splash_Screen**: The launch screen with the logo and loading indicator.
- **Offline_Banner**: The banner shown when the App shows saved data because a refresh failed.
- **Search_Prompt**: The placeholder text of the search field on the Markets tab.
- **No_Results_State**: The empty state of the Markets tab when a search matches no market.
- **Map_Filter_Indicator**: The indicator on the Map tab that shows the applied search text and the number of matching markets.
- **Missing_Value**: The text shown in the detail view for a field the dataset leaves blank.
- **Action_Text**: The text of buttons and swipe actions that change something (Remove, Retry, Close, Directions, Go to Map, More info).

## Requirements

### Requirement 1: Central copy type

**User Story:** As the owner of the App, I want all user-facing text in one place, so that tone changes are quick and consistent.

#### Acceptance Criteria

1. THE App SHALL define the text covered by this spec in App_Copy.
2. THE App_Copy type SHALL be `nonisolated` and SHALL expose pure functions for text that depends on a value, such as the number of results.
3. THE views covered by this spec SHALL read their text from App_Copy and SHALL NOT contain a string literal for that text.
4. THE App_Copy type SHALL expose a Plain_Label for every Spooky_Copy string whose meaning matters to a screen reader user.

### Requirement 2: Splash loading caption

**User Story:** As a user waiting at launch, I want to see what the App is doing, so that the dots do not look like a hang.

#### Acceptance Criteria

1. WHILE the Splash_Screen shows the loading indicator, THE Splash_Screen SHALL show the visible caption "Summoning markets…" below the dots.
2. THE loading indicator SHALL remain one accessibility element with the Plain_Label "Loading farmers markets" and the identifier `splash-loading`.
3. THE caption SHALL use a large, semibold text style, because the splash text contrast is 3.5:1.
4. WHEN the Splash_Screen shows a failure message, THE Splash_Screen SHALL NOT show the caption.

### Requirement 3: Offline banner

**User Story:** As a user without a connection, I want the banner to tell me I am seeing saved data, in the same voice as the rest of the App.

#### Acceptance Criteria

1. THE Offline_Banner SHALL read "Lost in the fog, showing saved markets".
2. THE Offline_Banner SHALL expose the Plain_Label "Offline, showing saved data".
3. THE Offline_Banner SHALL keep the identifier `offline-banner`.

### Requirement 4: Search prompt and empty results

**User Story:** As a user searching the list, I want clear prompts and empty states with a bit of character.

#### Acceptance Criteria

1. THE Search_Prompt SHALL read "Hunt by name, address or borough".
2. WHEN a search matches no market, THE No_Results_State SHALL show the title "Nothing lurking here" and the hint "No markets match “<query>”. Try another search."
3. THE No_Results_State SHALL expose the Plain_Label "No markets found" for its title.

### Requirement 5: Map filter indicator

**User Story:** As a user who filtered the list, I want the Map tab to say what is filtering it.

#### Acceptance Criteria

1. WHEN one market matches, THE Map_Filter_Indicator SHALL read "1 market lurking for “<query>”".
2. WHEN more than one market matches, THE Map_Filter_Indicator SHALL read "<count> markets lurking for “<query>”".
3. WHEN no market matches, THE Map_Filter_Indicator SHALL read "No markets lurking for “<query>”".
4. THE text SHALL use the trimmed query, and the function that builds it SHALL be pure and unit tested.
5. THE Map_Filter_Indicator SHALL expose the Plain_Label "Showing <count> result(s) for <query>" with the singular "result" for a count of one.
6. THE Map_Filter_Indicator SHALL keep the identifier `map-filter-indicator` and SHALL stay hidden when no search is active.

### Requirement 6: Missing values

**User Story:** As a user reading a market's details, I want blank fields to be clearly blank without looking like an error.

#### Acceptance Criteria

1. WHEN a detail field has no value, THE detail view SHALL show "Shrouded in mist".
2. THE field's accessibility text SHALL announce "Not listed" for a missing value.

### Requirement 7: Scope limits and tone rules

**User Story:** As a user, I want actions to be unambiguous, so that the theme never costs me clarity.

#### Acceptance Criteria

1. THE Action_Text SHALL stay literal and SHALL NOT be changed by this feature.
2. THE tab names, navigation titles, section headers and the "Directions" and "Go to Map" buttons SHALL NOT be changed by this feature.
3. THE `LoadFailureMessage` texts and the Favorites empty state SHALL NOT be changed by this feature.
4. EVERY new Spooky_Copy string SHALL use at most one spooky word or phrase.
5. NO App_Copy string shown to users SHALL contain technical error text such as an error domain or code.

### Requirement 8: Tests

**User Story:** As a developer, I want tests to protect the tone and the accessibility rules.

#### Acceptance Criteria

1. THE unit tests SHALL cover the singular, plural and zero forms of the filter indicator text, the trimming of the query, and the matching Plain_Label.
2. THE unit tests SHALL check that no App_Copy string contains technical error text and that every Plain_Label is non-empty and contains none of the spooky vocabulary words.
3. THE existing tests that assert the old texts SHALL be updated to the new texts: the search no-results UI test, and the unit tests of the filter summary.
4. THE UI tests SHALL still find the splash, banner and indicator by their identifiers.
5. THE full unit and UI test suites SHALL pass.
