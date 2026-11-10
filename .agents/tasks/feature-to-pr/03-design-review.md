# Design review (revision 2): Custom fonts integration (issue #7)

Reviewed `.agents/tasks/feature-to-pr/02-design.md` against `01-requirements.md`, with claims checked against the source. This is a revision, so the previous findings are re-checked first.

Verdict: CHANGES_REQUESTED (0 HIGH, 2 MEDIUM, 4 NIT)

## Previous findings

| # | Was | Status |
|---|---|---|
| 1 | MEDIUM Map tab has no navigation title | Closed. Section 4 limits the Map tab to the tab bar label and the PR notes 4.2 applies to Markets and Favorites. |
| 2 | MEDIUM tabTitle/tabBarLabel conflict, 12 vs 13 cases | Closed. `tabBarLabel` is used for tab items, `tabTitle` for large titles, 13 cases. |
| 3 | MEDIUM fallback weights | Closed. `fallbackWeight` column added and asserted in test 4. |
| 4 | MEDIUM `UIAppFonts` path | Closed. Conditional plist rule added. |
| 5 | MEDIUM convention gate location | Closed. Step 6 prompt (line 157 of `.kiro/workflows/feature-to-pr.workflow.json`) named, three regexes and command given. |
| 6 | MEDIUM nav bar appearance risk | Closed. Minimal appearance, before/after screenshots, `.principal` fallback. |
| 7 | NIT DrCaligari claim | Closed. |
| 8 | NIT availability signature | Partly closed. See finding 3 below (residual naming drift). |
| 9 | NIT nested `nonisolated` | Closed. |
| 10 | NIT wording gaps | Closed. |
| 11 | NIT Remove/search prompt | Closed. |

## Findings

1. MEDIUM. Dynamic Type is not preserved for the UIKit-rendered bars (tab bar labels, navigation titles, search field), which breaks requirement 6.1.
   - Where: Section 5. `ThemeAppearance.apply()` runs once at launch and builds fonts with `UIFontMetrics.scaledFont(for:)`. That returns a font sized for the content size category at the moment of the call. Appearance dictionaries do not re-scale when the user changes text size while the app is running. The design states "text scales with Dynamic Type" without covering this.
   - Fix: add an explicit rule. Either (a) observe `UIContentSizeCategory.didChangeNotification` and re-run the font part of `ThemeAppearance.apply()` (re-assign the tab bar, navigation bar and `UISearchTextField` appearances), or (b) accept launch-time scaling for system-owned bars, and list this in the PR as a documented limitation for requirement 6.1 and 5.3. Pick one. If (a), add the notification hook to the Files list and a screenshot at `.xxxLarge` taken after changing the size in a running app. Then state which choice was made in the Dynamic Type check under "Readability and layout".

2. MEDIUM. macOS gets no Display_Font on Title_Roles outside the root views, and the design calls the alternative unsupported without checking.
   - Where: Section 5, "macOS". It says navigation titles and window titles "are not changed" and "there is no supported global hook for title fonts". Requirements 4.2, 4.3 and 4.5 require the Display_Font on tab and detail navigation titles, and "the equivalent on macOS where applicable". macOS `TabView` also usually ignores the `Text` font in `tabItem`, so on macOS neither the tab titles nor the navigation titles would use the Display_Font.
   - Problem: the per-view route exists on macOS too. A `.toolbar { ToolbarItem(placement: .principal) { Text(title).appFont(.navigationTitle) } }` is a SwiftUI API. The design already proposes it as the iOS fallback. Leaving macOS unstyled is a requirement deviation, but the design only records it as "not verified visually", and that is a different statement.
   - Fix: choose one and write it into the design.
     - (a) Under `#if os(macOS)`, add the `.principal` toolbar title with `.appFont(.tabTitle)` for Markets and Favorites, and `.appFont(.navigationTitle)` for "Market details" and the single-market map. Keep `navigationTitle` for accessibility. Add a macOS build and a screenshot check if run.
     - (b) Keep macOS as is, but say in the PR, as a named deviation from 4.2, 4.3 and 4.5, that macOS tab and navigation titles stay in the system font, and ask the owner to confirm. Remove the "no supported hook" sentence, since it is not true for `.principal` toolbar items.

3. NIT. Names drift between sections for the same availability concept.
   - Where: Decision 2 stores `availableFamilies: Set<Family>`. The "Error handling" section stores `Registration.registeredFamilies`. The error table row still says `isAvailable(family)`, while Decision 2 defines `isAvailable(postScriptName:)` and `resolvedFont(for:isAvailable:)` takes `(Family) -> Bool`. `registerFonts()` has no signature.
   - Fix: use `registeredFamilies` nowhere. Define `struct Registration: Sendable { let availableFamilies: Set<Family> }` (a family is available if its PostScript name resolves after the registration attempt, including when `UIAppFonts` already registered it). State `@discardableResult static func registerFonts() -> Registration` and `static func isAvailable(postScriptName: String) -> Bool`. Rewrite the error table row as `isAvailable(postScriptName:)` false. `resolvedFont` keeps `(Family) -> Bool`, and `Role.font` passes `{ registration.availableFamilies.contains($0) }`.

4. NIT. Several snippets are not compilable or do not match their call sites.
   - `AppTypography.uiFont(for role: Role, textStyle override: ...)` contains a literal `...`, and section 5 calls it as `uiFont(.tabTitle)` with no label. `tabBarFont` is used but never defined.
   - `Bundle.main.urls(forResourcesWithExtension:subdirectory:)` returns `[URL]?`, so `a + b` does not compile.
   - `Resolved` needs `Equatable` for test 4 to compare values.
   - Fix: write `static func uiFont(_ role: Role) -> UIFont` (drop the override), define `let tabBarFont = AppTypography.uiFont(.tabBarLabel)`, use `(Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []) + (... subdirectory: "fonts") ?? [])`, and declare `nonisolated enum Resolved: Equatable, Sendable`.

5. NIT. The detail borough line changes size without being stated. Source: `MarketDetailView.header` uses `.title3` for the borough. The design maps it to `.subheadline` (15 pt), which is a visible reduction from `.title3`. Fix: either map it to a role with `.title3` (for example a new body-family 20 pt role, or `bodyEmphasis`) or state that the shrink is intended. The same applies to the `SplashLoadingIndicator` caption, which is `.title3.weight(.semibold)` today and becomes the 26 pt `.splash` role.

6. NIT. The sentence "Favorites rows: add `.lineLimit(nil)` is the default; the row `VStack` already grows." is garbled. Fix: "Favorites rows: no change expected, since `lineLimit` is already unlimited; verify with a long name at `.xxxLarge`."

## Verified Assumptions

- `NYCFarmerMarkets/fonts/` holds the three `.ttf` files. `NYCFarmerMarkets/Info.plist` contains only `UIAppFonts` with `DrCaligari.ttf`, `Grim Creeper.ttf`, `N8ghtmare.ttf` (bare names).
- `project.pbxproj`: `INFOPLIST_FILE = NYCFarmerMarkets/Info.plist` plus `GENERATE_INFOPLIST_FILE = YES` for the app target; `membershipExceptions` lists `Info.plist`; `SUPPORTED_PLATFORMS = iphoneos iphonesimulator macosx xros xrsimulator`; `IPHONEOS_DEPLOYMENT_TARGET = 26.5`; `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` for the app target (the test target does not set it).
- `ThemeAppearance.apply()` sets only the `UINavigationBar` tint and a `UITabBarAppearance` over three item appearances, under `#if canImport(UIKit) && !os(visionOS)`. `NYCFarmerMarketsApp.init()` calls it first, and `AppRootView` is the `WindowGroup` content.
- Every system `.font(...)` usage the design lists exists in the source at the described places (SplashView, SplashLoadingIndicator, MarketRow, MarketDetailView, MarketListView, MarketMapView, MapFilterIndicator, OfflineBanner, ThemedButtonStyle). `IconView` in `Theme/AppIcon.swift` uses `.font(.system(size:))` inside `Theme/`.
- `RootTabView` uses `Label { Text("Markets") } icon:` and the same for Map and Favorites. `FavoritesView` has `Label { Text("Remove") } icon:` inside `swipeActions`, and `.navigationTitle("Favorites")`. `MarketListView` has `.navigationTitle("Markets")`. `MarketDetailView` has `.navigationTitle("Market details")`. `MarketLocationMapView` has `.navigationTitle(market.name)`. `MarketMapView` has none.
- The convention gate is the step 6 prompt at line 157 of `.kiro/workflows/feature-to-pr.workflow.json`.
- I ran the three proposed regexes on the current source (outside `Theme/`). Patterns 1 and 2 return no lines now, so they will not give false positives on the existing code. Pattern 3 returns exactly the 16 system-font calls the design plans to replace, so the gate is meaningful.
- `Info.plist` is the only plist edit and does not need a project file change. Unit tests use Swift Testing and the test target exists (`NYCFarmerMarketsTests/`).

## Unverified / Wrong Assumptions

- Wrong: macOS has "no supported hook" for title fonts (finding 2). A `.principal` toolbar item works on macOS.
- Wrong (by omission): `UIFontMetrics.scaledFont` in appearance code keeps text scaling with the user's setting (finding 1).
- Unverified (I did not build): where the synchronized group copies the `.ttf` files in the built bundle (root or `fonts/`). The design handles both cases with a conditional rule, so this is not a defect.
- Unverified: that assigning a minimal `UINavigationBarAppearance` keeps the iOS 26 look, and that `UISearchTextField.appearance().font` and the swipe action label take the font. The design has a screenshot gate and a documented fallback for each, which is adequate.
- Unverified: glyph coverage, font license metadata, and macOS and visionOS runtime behaviour. They are assigned to verification tasks.
