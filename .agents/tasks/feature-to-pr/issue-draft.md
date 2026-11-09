Show selected market on in-app map and add "Directions" button

## Description
In the market detail view, the "Open in Maps" button currently opens the market in the external Apple Maps app. Change it so it pushes an internal map screen inside the existing detail sheet's NavigationStack (a NavigationLink/navigation destination pushed from MarketDetailView), showing only the selected market. It must not be presented as a separate sheet or full-screen cover. Add a second button, "Directions", that performs the current behavior (opening the market in external Apple Maps).

## Acceptance criteria
- [ ] "Open in Maps" pushes an internal map screen inside the detail sheet's existing NavigationStack (no separate sheet or full-screen cover).
- [ ] The internal map shows only the selected market (no other markets' pins).
- [ ] The standard back button returns to the market detail view.
- [ ] A new "Directions" button is shown in the market detail view.
- [ ] "Directions" opens the market in the external Apple Maps app, exactly as "Open in Maps" does today.
- [ ] Both buttons have accessibility labels and work on iOS and macOS.
- [ ] Existing tests pass; tests cover the new behavior where practical.
