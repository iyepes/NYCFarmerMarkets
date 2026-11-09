# Requirements Document

> Retroactive spec. The app was built from a plan agreed in chat and never had spec files. This document describes the behavior of the app as built and verified. The splash screen, collapsible borough sections and friendly failure messages were added later and are specified in `.kiro/specs/splash-screen-collapsible-boroughs/`.

## Introduction

NYC Farmer Markets is a SwiftUI app (iOS, macOS and visionOS targets) that loads farmers markets from NYC Open Data and presents them in three tabs: a searchable list grouped by borough, a map with pins, and a list of favorites. All tabs open the same detail sheet. The app works offline from a saved copy of the last successful download. The UI uses a single-point palette and a spooky icon set.

## Glossary

- **App**: The NYC Farmer Markets application.
- **Dataset**: The NYC Open Data "NYC Farmers Markets" dataset, Socrata ID `8vwk-6iz2`, endpoint `https://data.cityofnewyork.us/resource/8vwk-6iz2.json`.
- **Market**: One farmers market, identified by a stable ID built from its lowercased name and address.
- **Market_Store**: The observable store holding the market list, load state, offline flag and the selected market.
- **Favorites_Store**: The observable store holding the set of favorite market IDs, persisted locally.
- **Market_Cache**: The JSON file holding the last successful download.
- **Markets_Tab**, **Map_Tab**, **Favorites_Tab**: The three tabs of the App.
- **Detail_Sheet**: The sheet showing the full data of one Market, shared by all tabs.
- **App_Palette**: The color definitions in `AppPalette`, the only place hex values may appear.
- **App_Icon_Registry**: The `AppIcon` enumeration through which every icon is referenced.
- **App_Icon**: The home-screen icon of the App.

## Requirements

### Requirement 1: Load market data from NYC Open Data

**User Story:** As a user, I want the App to load the current farmers markets from NYC Open Data, so that I see up-to-date, official data.

#### Acceptance Criteria

1. THE App SHALL download markets from the Dataset, requesting up to 5000 rows.
2. THE Dataset returns every value as a string and contains one row per market per year; THE App SHALL keep only the rows of the most recent year present in the download.
3. THE App SHALL remove duplicate markets, treating two rows as the same market when their names and addresses match ignoring case.
4. THE App SHALL discard rows that have no market name.
5. THE App SHALL parse latitude and longitude from text to numbers, and SHALL treat missing, unparseable or zero values as no coordinate.
6. THE App SHALL trim whitespace from text values, capitalize the first letter of the EBT, year-round and cooking values, and map a missing or blank borough to "Unknown".
7. THE App SHALL canonicalize known borough names (Manhattan, Brooklyn, Queens, Bronx, Staten Island) regardless of input capitalization.
8. IF the server answers with a non-success HTTP status, THEN THE App SHALL treat the download as failed.

### Requirement 2: Offline-first loading

**User Story:** As a user, I want the App to work without a connection, so that I can still look up markets.

#### Acceptance Criteria

1. WHEN a download succeeds, THE Market_Store SHALL replace its markets and THE Market_Cache SHALL be written atomically.
2. WHEN the App starts and the Market_Cache holds markets, THE Market_Store SHALL show the cached markets first and then refresh from the network.
3. IF a refresh fails and the Market_Store holds markets, THEN THE Market_Store SHALL keep them and SHALL set its offline flag.
4. IF a refresh fails and the Market_Store holds no markets, THEN THE Market_Store SHALL enter an error state.
5. WHEN a later refresh succeeds, THE Market_Store SHALL clear the offline flag.
6. WHILE the offline flag is set, THE Markets_Tab, Map_Tab and Favorites_Tab SHALL show an "Offline, showing saved data" banner.
7. THE Markets_Tab SHALL support pull to refresh.
8. IF a refresh is cancelled, THEN THE Market_Store SHALL NOT report an error.

### Requirement 3: Markets tab

**User Story:** As a user, I want a searchable list of markets grouped by borough, so that I can find markets near me.

#### Acceptance Criteria

1. THE Markets_Tab SHALL group markets into one section per borough in the fixed order Manhattan, Brooklyn, Queens, Bronx, Staten Island, followed by any other borough alphabetically.
2. THE Markets_Tab SHALL sort the markets within a section by name.
3. THE Markets_Tab SHALL show the borough name and market count in each section header.
4. THE Markets_Tab SHALL show, for each market, its name, address and days of operation, and a favorite indicator when the market is a favorite.
5. WHEN the user enters a search query, THE Markets_Tab SHALL show only markets whose name, address or borough contains the query, ignoring case and diacritics, and SHALL hide sections left empty.
6. IF no market matches the query, THEN THE Markets_Tab SHALL show a "No markets found" state.
7. WHEN the user taps a market, THE App SHALL open the Detail_Sheet for it.

### Requirement 4: Map tab

**User Story:** As a user, I want to see markets as pins on a map, so that I can find the ones near me.

#### Acceptance Criteria

1. THE Map_Tab SHALL show a pin for every market that has a coordinate.
2. THE Map_Tab SHALL start centered on New York City.
3. THE Map_Tab SHALL draw favorite markets with a pin style different from other markets.
4. WHEN the user selects a pin, THE Map_Tab SHALL show a card with the market name and borough and a "More info" button.
5. WHEN the user taps "More info", THE App SHALL open the Detail_Sheet for that market.
6. WHEN the Detail_Sheet is closed, THE Map_Tab SHALL be shown with the pin still selected.
7. THE Map_Tab SHALL expose each pin to assistive technologies with the market name, and the word "favorite" for favorites.

### Requirement 5: Detail sheet

**User Story:** As a user, I want to see all the data of a market and return to where I was, so that I can browse comfortably.

#### Acceptance Criteria

1. THE Detail_Sheet SHALL be presented from a single place in the App, driven by the selected market in the Market_Store.
2. THE Detail_Sheet SHALL show the market name, borough, address, community district, days, hours, EBT acceptance, year-round status, Health Department cooking permission and data year, showing "Not listed" for missing values.
3. WHEN the user taps Close, THE App SHALL dismiss the Detail_Sheet and return to the tab it was opened from.
4. WHERE the market has a coordinate, THE Detail_Sheet SHALL offer an "Open in Maps" button.
   > Amended by issue #1 (see `.kiro/specs/internal-map-and-directions-button/`): "Open in Maps" now pushes the in-app map showing only the selected market, and a new "Directions" button opens the market in the external Apple Maps app (the previous behavior of "Open in Maps").
5. THE Detail_Sheet SHALL offer a toggle to add or remove the market from favorites, with an accessibility label that states the action ("Add to favorites" or "Remove from favorites") and haptic feedback on change.

### Requirement 6: Favorites

**User Story:** As a user, I want to save markets as favorites and see them in one list, so that I can get back to them quickly.

#### Acceptance Criteria

1. THE Favorites_Store SHALL persist the set of favorite market IDs on the device and restore it at launch.
2. THE Favorites_Tab SHALL list the favorite markets that exist in the current data, sorted by name, with borough, address and days.
3. WHEN the user taps a favorite, THE App SHALL open the Detail_Sheet, and closing it SHALL return to the Favorites_Tab.
4. WHEN the user swipes a favorite, THE Favorites_Tab SHALL offer a Remove action that removes it from favorites; THE Favorites_Tab SHALL NOT offer an Edit button.
5. IF a stored favorite ID matches no market in the data, THEN THE Favorites_Tab SHALL skip it and THE Favorites_Store SHALL keep the ID.
6. IF there are no favorites to show, THEN THE Favorites_Tab SHALL show the empty state "No haunts yet" with the text "Favorite a market to summon it here."
7. THE Favorites_Tab SHALL expose a "Remove from favorites" accessibility action on each row.

### Requirement 7: Single-point palette

**User Story:** As the owner of the App, I want to change the colors in one place, so that re-theming is quick and consistent.

#### Acceptance Criteria

1. THE App_Palette SHALL define five base colors: #C7D93D (primary), #98A62E (secondary), #525919 (deep), #E6F28D (highlight) and #F2F2F2 (surface), plus the app icon olive #78872B.
2. THE App_Palette SHALL expose semantic tokens with light and dark variants, and views SHALL use only these tokens.
3. THE App SHALL NOT contain color literals, hex values or system color names outside the `Theme` folder.
4. THE App_Palette SHALL be defined in code, not in the asset catalog.
5. THE App SHALL apply the palette to the tint, tab bar and list and sheet backgrounds.
6. THE text and background token pairs used for body text SHALL have a contrast ratio of at least 4.5:1 in light and dark appearance.

### Requirement 8: Spooky icon set

**User Story:** As a user, I want a light spooky look in the icons, so that the App has a distinctive character.

#### Acceptance Criteria

1. THE App SHALL reference every icon through the App_Icon_Registry, and views SHALL NOT use raw SF Symbol names.
2. THE App SHALL provide custom vector icons for a ghost (filled and outline), a bat and a pumpkin as template images tinted by the theme.
3. THE App SHALL use the ghost for favorites, the bat for map pins and the pumpkin for the Markets tab and market rows.
4. THE App SHALL give every icon a plain-language accessibility name, not a spooky name.
5. THE App SHALL give every registry icon a symbol or asset that exists.

### Requirement 9: App icon

**User Story:** As a user, I want a recognizable home-screen icon, so that I can find the App.

#### Acceptance Criteria

1. THE App_Icon SHALL show a white line-art carrot with three leaves on the olive background #78872B.
2. THE App SHALL keep the vector source of the App_Icon in `Design/AppIcon.svg`.
3. THE App SHALL provide the App_Icon as opaque PNG files for the iOS 1024 point slot and for the macOS slots from 16 to 512 points at 1x and 2x.
4. THE asset catalog SHALL build without warnings.

### Requirement 10: Platforms and accessibility

**User Story:** As a user on any supported device, I want the App to be usable, so that I can rely on it.

#### Acceptance Criteria

1. THE App SHALL build for iOS (iPhone and iPad) and macOS, and SHALL allow outgoing network connections under the macOS sandbox.
2. THE App SHALL use system text styles so that Dynamic Type applies.
3. THE App SHALL give interactive elements an accessibility label or identifier suitable for assistive technology and UI tests.
4. THE App SHALL NOT claim full accessibility compliance; full validation requires manual testing with assistive technologies.

### Requirement 11: Test coverage

**User Story:** As a developer, I want automated tests for the core behavior, so that regressions are caught.

#### Acceptance Criteria

1. THE unit tests SHALL cover decoding, year filtering, de-duplication, coordinate handling and stable IDs, using a mocked network.
2. THE unit tests SHALL cover the cache round trip and the success, failure-with-cache and failure-without-cache outcomes of a refresh.
3. THE unit tests SHALL cover borough grouping order, search filtering, favorites toggling and persistence, and the palette and icon checks.
4. THE UI tests SHALL cover opening and closing the Detail_Sheet from the list, favoriting and removing a favorite by swipe, and opening the Detail_Sheet from a map pin.
