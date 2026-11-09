# Requirements: Internal map and directions button (issue #1)

## Summary
In the Detail_Sheet, "Open in Maps" currently opens the market in the external Apple Maps app. It should instead push an in-app map screen, inside the sheet's existing NavigationStack, that shows only the selected market. A new "Look for directions" button takes over the current behavior (open the market in external Apple Maps). Amends Requirement 5.4 of `.kiro/specs/nyc-farmer-markets/requirements.md`.

## Glossary
- **Detail_Sheet**: `MarketDetailView`, the sheet shared by all tabs, which owns a NavigationStack.
- **Market_Map_Screen**: New in-app screen showing a single market on a map.
- **Selected_Market**: The market shown in the Detail_Sheet.

## Functional Requirements

### Requirement 1: In-app map for the selected market
**User Story:** As a user, I want "Open in Maps" to show the market on the app's own map, so that I can see where it is without leaving the app.

#### Acceptance Criteria
1. WHERE the Selected_Market has a coordinate, THE Detail_Sheet SHALL show an "Open in Maps" button.
2. WHEN the user taps "Open in Maps", THE App SHALL push the Market_Map_Screen onto the Detail_Sheet's existing NavigationStack.
3. THE App SHALL NOT present the Market_Map_Screen as a separate sheet or full-screen cover.
4. THE Market_Map_Screen SHALL show exactly one annotation, for the Selected_Market, and SHALL NOT show any other market.
5. THE Market_Map_Screen SHALL center on the Selected_Market's coordinate at a zoom level where the pin is clearly visible.
6. THE Market_Map_Screen SHALL show the market name as its navigation title or annotation label.
7. WHEN the user uses the standard back button, THE App SHALL return to the Detail_Sheet showing the same market.
8. "Open in Maps" SHALL NOT open the external Apple Maps app.

### Requirement 2: Look for directions
**User Story:** As a user, I want a "Look for directions" button, so that I can still get directions in Apple Maps.

#### Acceptance Criteria
1. WHERE the Selected_Market has a coordinate, THE Detail_Sheet SHALL show a "Look for directions" button.
2. WHEN the user taps "Look for directions", THE App SHALL open the Selected_Market in the external Apple Maps app exactly as "Open in Maps" does today (map item at the market coordinate, named with the market name).
3. IF the Selected_Market has no coordinate, THEN THE Detail_Sheet SHALL show neither button.

### Requirement 3: Accessibility and platforms
1. Both buttons SHALL have accessibility labels matching their titles and stable accessibility identifiers (existing `open-in-maps` kept for "Open in Maps"; a new identifier for "Look for directions").
2. The Market_Map_Screen SHALL be usable with VoiceOver (annotation labelled with the market name).
3. The feature SHALL work on iOS and macOS (and keep visionOS building).

## Non-Functional Requirements
- All colors come from AppPalette tokens and all icons from the AppIcon registry; no Color literals, hex literals or raw SF Symbol names outside `NYCFarmerMarkets/Theme/`.
- Any new pure logic (e.g. building the single-market map region or the external map item) is `nonisolated` and unit tested with Swift Testing.
- New files go in existing `NYCFarmerMarkets/` folders (auto-included; no project file edits).

## Acceptance Criteria (numbered, testable)
1. Tapping "Open in Maps" pushes a map screen inside the detail sheet (back button visible on iOS; no new sheet/cover presented).
2. The pushed map has exactly one annotation, for the selected market.
3. The back button returns to the market detail view.
4. A "Look for directions" button appears in the detail view whenever "Open in Maps" does, and not otherwise.
5. Tapping "Look for directions" opens the market in external Apple Maps with the same map item as before.
6. Both buttons expose accessibility labels and identifiers; works on iOS and macOS.
7. Existing unit and UI tests pass; new tests cover the single-market logic and the UI navigation where practical.

## Assumptions
- The "Look for directions" button needs a new icon entry in the AppIcon registry (or reuses `openInMaps`); the design step decides. "Open in Maps" may need a different icon since both would otherwise match.
- The in-app map reuses MapKit's SwiftUI `Map`, as `MarketMapView` does; whether that view is reused or a new view is created is a design decision.
- The pushed screen has no "More info" callout and no favorites toggle of its own; the sheet's toolbar (Close, favorite) stays as is.
- Only a market with a valid coordinate gets the buttons, consistent with today's behavior.
- The "Look for directions" title is the exact user-visible text (sentence case as given).

## Out of Scope
- Showing the user's location, routing, or in-app directions.
- Changes to the Map tab, its pins, or clustering.
- Changes to data loading, caching, or favorites.
- Changing the existing behavior of how the external Apple Maps item is built.
