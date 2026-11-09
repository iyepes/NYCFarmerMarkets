# Requirements Document

## Introduction

The Markets_Tab has a search field (name, address or borough). Today the Map_Tab ignores it and always shows every market. This feature makes the Map_Tab show only the markets that match the list's active search, so both tabs stay consistent. Terms (Markets_Tab, Map_Tab, Market_Store, Market) follow `.kiro/specs/nyc-farmer-markets/requirements.md`. Issue: https://github.com/iyepes/NYCFarmerMarkets/issues/3

## Glossary

- **Search_Query**: The text typed in the Markets_Tab search field.
- **Active_Search**: A Search_Query that is non-empty after trimming whitespace (the same rule the list uses to decide it is searching).
- **Matching_Markets**: The markets the Markets_Tab shows for a Search_Query.
- **Filter_Indicator**: A chip or banner on the Map_Tab showing the Search_Query and the count of Matching_Markets.

## Requirements

### Requirement 1: Map shows the list's search results

**User Story:** As a user, I want the map to show the same markets I just searched for in the list, so that I can see where they are.

#### Acceptance Criteria

1. WHILE an Active_Search exists, THE Map_Tab SHALL show pins only for Matching_Markets.
2. THE Map_Tab and THE Markets_Tab SHALL derive Matching_Markets from one shared filtering rule, so that both show exactly the same markets for any Search_Query.
3. WHEN the Search_Query changes in the Markets_Tab, THE Map_Tab SHALL reflect the new Matching_Markets without needing a reload.
4. WHEN the Search_Query is cleared, THE Map_Tab SHALL show all markets again.
5. WHILE no Active_Search exists, THE Map_Tab SHALL behave as it does today.
6. IF an Active_Search has no Matching_Markets, THEN THE Map_Tab SHALL show no pins and SHALL NOT crash.
7. Markets without coordinates remain not shown on the map, as today; this applies to Matching_Markets too.

### Requirement 2: Map camera is not changed by the filter

**User Story:** As a user, I want the map to stay where I left it, so that filtering does not disorient me.

#### Acceptance Criteria

1. WHEN the filter is applied or cleared, THE Map_Tab SHALL keep its current zoom and camera position.
2. THE Map_Tab SHALL NOT zoom to fit or re-center on Matching_Markets.

### Requirement 3: Filter indicator on the map

**User Story:** As a user, I want to see that the map is filtered, so that I do not think markets are missing.

#### Acceptance Criteria

1. WHILE an Active_Search exists, THE Map_Tab SHALL show the Filter_Indicator with the Search_Query and the number of Matching_Markets, for example `Showing 12 results for "cafe"`.
2. WHILE no Active_Search exists, THE Map_Tab SHALL NOT show the Filter_Indicator.
3. WHEN there are no Matching_Markets, THE Filter_Indicator SHALL show a count of 0 (wording for 0 and 1 handled grammatically, e.g. "1 result").
4. THE Filter_Indicator SHALL use only AppPalette colors and AppIcon icons and SHALL be readable by VoiceOver.

### Requirement 4: Tests

**User Story:** As a maintainer, I want the filtering logic tested, so that list and map cannot drift apart.

#### Acceptance Criteria

1. THE shared filtering logic SHALL be a pure `nonisolated` type covered by Swift Testing unit tests: empty and whitespace-only queries, match on name, address and borough, case-insensitivity, no results, and unchanged results for the previously existing list behavior.
2. THE Markets_Tab SHALL show the same results as before this change for every Search_Query.

## Acceptance Criteria Summary (from the issue)

1. With an active search that has results, the Map_Tab shows only the markets in the list results.
2. The map's markets match the list results exactly.
3. Clearing the search shows all markets on the map.
4. With no active search, the Map_Tab is unchanged.
5. A search with no results shows no markets and does not crash.
6. Zoom and camera position are kept when the filter is applied or cleared.
7. The indicator with search text and count shows while filtered.
8. The indicator is hidden when no search is active.
9. Unit tests cover the shared filtering logic.

## Assumptions

- The Search_Query is shared state (not per-view) that survives switching tabs; the Markets_Tab keeps its search text when the user leaves and returns.
- Selecting a pin still opens the Detail_Sheet as today.
- "Active" uses the list's existing trimmed non-empty rule; the indicator shows the trimmed query.
- The Favorites_Tab is not affected.
- Search text is not persisted across app launches.
- The indicator is display-only (no clear button) in this iteration.

## Out of Scope

- Zoom-to-fit or re-centering on results.
- A search field on the Map_Tab.
- Changing the matching rules (name, address, borough) or search UI of the list.
- Applying the search to the Favorites_Tab.
- Persisting the search across launches.
- A clear-filter control on the indicator.
