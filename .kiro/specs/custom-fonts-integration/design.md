# Design: Custom fonts integration (issue #7)

> **Current state:** the body font is now **Breath of the House** and `sectionHeader` is a display role. The sections below are the original design (N8ghtmare), then "Amendment after visual review" (Dr. Caligari, PR #8), then "Amendment 2" (manual changes after PR #8). Later sections win where they conflict.

## Overview

Grim Creeper (display) and N8ghtmare (body) are applied through one new type, `AppTypography`, in `NYCFarmerMarkets/Theme/`, in the same spirit as `AppPalette` and `AppIcon`. The type holds the two font families, a semantic `Role` enum, and a `View.appFont(_:)` modifier. Views stop calling `.font(.headline)` and similar, and call `.appFont(.role)` instead. Fonts are registered at launch at runtime with CoreText, which works the same on iOS, macOS and visionOS. System-rendered bars (tab bar, navigation bar, search field) are styled in `ThemeAppearance` with UIKit appearance on iOS. No Xcode project file edits are needed.

**Technology stack (locked on approval):** Swift, SwiftUI (`Font.custom(_:size:relativeTo:)`), CoreText (`CTFontManagerRegisterFontsForURL`, `CTFontCreateWithName`), UIKit appearance (`UITabBarAppearance`, `UINavigationBarAppearance`, `UIFontMetrics`) behind `#if canImport(UIKit) && !os(visionOS)`, AppKit only if a macOS hook turns out to be needed. Swift Testing for unit tests, XCTest for UI tests. No new dependencies.

## What exists today (read from the source)

- `NYCFarmerMarkets/fonts/` holds `DrCaligari.ttf`, `Grim Creeper.ttf`, `N8ghtmare.ttf`, all tracked in git.
- `NYCFarmerMarkets/Info.plist` is tracked and contains only a `UIAppFonts` array with the three file names. `INFOPLIST_FILE = NYCFarmerMarkets/Info.plist` is set together with `GENERATE_INFOPLIST_FILE = YES` (Debug and Release of the app target). The synchronized-group exception set lists `Info.plist` as a membership exception, so it is not copied as a resource. The `.ttf` files are therefore in the synchronized folder and should be copied as resources. Whether they land at the bundle root or in a `fonts/` subfolder is not known yet and must be checked on the built `.app`. `UIAppFonts` lists bare names, so it only resolves if the files are at the bundle root.
- `fc-scan` gives these PostScript names: `Grim-Creeper-Regular` (family "Grim Creeper"), `N8ghtmare` (family "N8ghtmare"), `Dr.Caligari` (unused). The file name `Grim Creeper.ttf` differs from its PostScript name, so the code must use the PostScript names.
- `UIAppFonts` only applies to UIKit platforms. macOS ignores it, and macOS needs `ATSApplicationFontsPath` or runtime registration. Nothing in the repo registers fonts at runtime today.
- `ThemeAppearance.apply()` (in `Theme/ThemeStyling.swift`) styles `UITabBar` through `UITabBarAppearance` and only sets the tint of `UINavigationBar`. It is called from `NYCFarmerMarketsApp.init()` and is guarded by `#if canImport(UIKit) && !os(visionOS)`.
- Fonts are set in views with system styles: `SplashView` (`.title2.weight(.bold)`, `.title3.weight(.semibold)`), `SplashLoadingIndicator` (`.title3.weight(.semibold)`), `MarketRow` (`.headline`, `.subheadline`, `.caption`), `MarketDetailView` (`.title.bold()`, `.title3`, `.caption`, `.body`), `MarketListView` section header (`.subheadline.weight(.bold)`, `.caption.weight(.semibold)`), `MarketMapView` callout (`.headline`, `.subheadline`), `MapFilterIndicator` and `OfflineBanner` (`.footnote.weight(.medium)`), `ThemedButtonStyle` (`.headline`). Text with no explicit font: tab labels, `navigationTitle`s ("Markets", "Favorites", "Market details", and `market.name` in `MarketLocationMapView`), `ContentUnavailableView` content, "Remove", "Go to Map", "Directions", "Retry", the search prompt.
- `MarketRow` is shared by `MarketListView` and `FavoritesView`.

## Key decisions

### 1. Registration: runtime CoreText registration on all platforms (chosen), `UIAppFonts` left as is

Options considered:
- A. `UIAppFonts` (supplemental Info.plist, already present) on iOS and visionOS plus `ATSApplicationFontsPath` on macOS. Two mechanisms, and `ATSApplicationFontsPath` is a macOS-only Info.plist key that would need a per-SDK build setting or a second plist, which means project file edits.
- B. Runtime `CTFontManagerRegisterFontsForURL(url, .process, &error)` for every `.ttf` found in the bundle. One mechanism, no project edits, and it does not depend on where synchronized groups place the files.

Decision: B. `AppTypography.registerFonts()` runs first in `NYCFarmerMarketsApp.init()` (before `ThemeAppearance.apply()`, which needs the fonts). The `UIAppFonts` entry is kept (removing it would need project file edits) but is made correct by this rule: after the first iOS build, list the `.app` contents. If the `.ttf` files are in a `fonts/` subfolder, update the three `UIAppFonts` strings in `NYCFarmerMarkets/Info.plist` to `fonts/<file name>`; this is a plist edit, not a project file edit. If they are at the root, leave the plist as is. The observed layout (iOS and macOS) goes in the PR. Registering a font that `UIAppFonts` already registered returns `kCTFontManagerErrorAlreadyRegistered`; this is treated as success. The design documents the pair honestly: runtime registration is the mechanism that is verified on every platform; `UIAppFonts` is redundant on iOS and visionOS.

Implementation of the URL lookup: `Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) + Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "fonts")`, de-duplicated by `lastPathComponent`. Only the two used families are registered (match by file name against the `Family.fileName` values); `DrCaligari.ttf` stays bundled and no code references it. Note that on iOS and visionOS it is still registered by the existing `UIAppFonts` entry; the runtime code does not register it.

Idempotence: registration lives in a `static let registration: Registration = ...` initializer, so it runs once per process even if called from tests, previews and the app.

### 2. Availability and fallback

`Font.custom` with an unknown name silently falls back to the system font at its own size, without scaling rules we control. To make the fallback explicit and testable, each role asks the cached availability set first. The single lookup is `static func isAvailable(postScriptName: String) -> Bool`, implemented as `CTFontCopyPostScriptName(CTFontCreateWithName(name as CFString, 12, nil)) as String == name` (works on all three platforms without UIKit or AppKit). It is called only while building the `registration` static (see Decision 1), which stores `availableFamilies: Set<Family>`. `Role.font` reads that static, which also triggers registration, so previews and tests without app launch work, and CoreText is never called during view body evaluation. If available: `Font.custom(postScriptName, size: size, relativeTo: textStyle)`. If not: `Font.system(textStyle, design: .default)` (with the weight the role declares, which is `.regular` for most). Text is therefore never empty, and the system fallback still scales with Dynamic Type.

For testability, the lookup is a pure function: `AppTypography.resolvedFont(for role: Role, isAvailable: (Family) -> Bool) -> Resolved`, where `Resolved` is a small `nonisolated enum { case custom(name: String, size: CGFloat, relativeTo: Font.TextStyle); case system(Font.TextStyle, Font.Weight) }` (weight comes from `Role.fallbackWeight`). `Role.font` calls it with the real availability check and maps `Resolved` to `Font`. Tests inject `{ _ in false }` to check the fallback, and `{ _ in true }` to check family mapping, without depending on the host app's bundle.

### 3. Type shape (`Theme/AppTypography.swift`, `nonisolated`)

```swift
nonisolated enum AppTypography {
    // Every nested type is also marked `nonisolated` (the project default isolation is MainActor).
    nonisolated enum Family: CaseIterable, Sendable {
        case display   // Grim Creeper
        case body      // N8ghtmare
        var postScriptName: String   // "Grim-Creeper-Regular", "N8ghtmare"
        var fileName: String         // "Grim Creeper.ttf", "N8ghtmare.ttf"
    }
    nonisolated enum Role: CaseIterable, Sendable {
        // Display family (title roles)
        case splash            // splash error message and loading caption
        case splashHint        // splash hint under the message
        case tabTitle          // large navigation title of the three tabs
        case tabBarLabel       // tab bar item labels (12 pt, .caption2)
        case navigationTitle   // inline navigation titles, e.g. "Market details" (20 pt, .headline)
        case detailTitle       // market name in the detail header
        case favoriteItemTitle // market name in Favorites rows
        // Body family
        case body              // detail values, empty/error text, default
        case bodyEmphasis      // buttons, list row titles, callout titles (was .headline)
        case subheadline       // row subtitles, borough in detail, callout subtitle
        case sectionHeader     // borough headers and counts
        case caption           // row days, detail field labels
        case footnote          // offline banner, map filter indicator
        var family: Family
        var size: CGFloat
        var textStyle: Font.TextStyle
        var fallbackWeight: Font.Weight
        var font: Font
    }
}
// Also nonisolated: Resolved (enum) and Registration (struct).
extension View { func appFont(_ role: AppTypography.Role) -> some View }
```

Initial size table (points at the default Dynamic Type size; `relativeTo` supplies scaling). These are starting values from the system sizes; the implementer may tune them in this one file after reading screenshots, because the fonts have different metrics than SF:

| Role | Family | Size | relativeTo | fallbackWeight |
|---|---|---|---|---|
| splash | display | 26 | .title2 | .bold |
| splashHint | display | 22 | .title3 | .semibold |
| tabTitle | display | 34 | .largeTitle | .semibold |
| tabBarLabel | display | 12 | .caption2 | .semibold |
| navigationTitle | display | 20 | .headline | .semibold |
| detailTitle | display | 30 | .title | .bold |
| favoriteItemTitle | display | 20 | .headline | .semibold |
| body | body | 17 | .body | .regular |
| bodyEmphasis | body | 17 | .headline | .semibold |
| subheadline | body | 15 | .subheadline | .regular |
| sectionHeader | body | 15 | .subheadline | .bold |
| caption | body | 12 | .caption | .regular |
| footnote | body | 13 | .footnote | .medium |

The custom fonts have a single regular weight each, so roles do not request `.bold` or `.semibold`; asking for it would produce synthetic bold. Where a view used bold or semibold, hierarchy now comes from size and family. The system fallback uses the `fallbackWeight` column in `Resolved.system`, matching today's weights (`.title.bold()` for detailTitle, `.headline` semibold for the title-like roles, `.medium` for footnote), so the fallback looks like today's UI. The count badge (`.caption.weight(.semibold)` today) uses `caption` and accepts regular weight in the fallback; a minor documented difference.

A default body font is also set once at the root: the `WindowGroup` content in `NYCFarmerMarketsApp` gets `.environment(\.font, AppTypography.Role.body.font)` directly. This catches text that has no explicit font (button titles in `Label`, "Remove", "Go to Map", "Directions", "Retry", `ContentUnavailableView` content). Every view that previously set a system font gets an explicit role.

### 4. Which text gets which role

- Splash (`SplashView`, `SplashLoadingIndicator`): message and caption `.splash`, hint `.splashHint`. "Retry" is a button, so it uses `.bodyEmphasis` through `ThemedButtonStyle` (assumption: the Retry button is Other_Text). The logo is an image and is unchanged.
- Tab titles: The three tab-item `Text`s in `RootTabView` get `.appFont(.tabBarLabel)` (honoured on macOS and possibly visionOS). On iOS the tab bar ignores SwiftUI fonts, so `ThemeAppearance` sets `titleTextAttributes[.font]` with the `tabBarLabel` font (see 5). `tabTitle` is used only for the large navigation title, set through the navigation bar appearance. The Map tab has no navigation bar and no navigation title (`MarketMapView` has no `NavigationStack`), so it gets the Display_Font only on its tab bar label. No title is added, since that would change UI and copy. The PR states that the navigation-title clause of requirement 4.2 applies to Markets and Favorites only.
- Detail title: `MarketDetailView.header` market name `.detailTitle`; the borough under it `.subheadline`. The inline navigation title "Market details" and `MarketLocationMapView`'s `navigationTitle(market.name)` use the display font via the navigation bar appearance (their inline size is the standard nav title size, 17 to 20 pt, so the display font is applied at a size set in the appearance code, see 5).
- Favorites item title: `MarketRow` gets a new parameter `titleRole: AppTypography.Role = .bodyEmphasis`. `MarketListView` rows keep the default (assumption 3: Markets list rows are Other_Text; the PR asks the owner to confirm). `FavoritesView` passes `.favoriteItemTitle`. Row subtitle `.subheadline`, days `.caption`. `MarketRow`'s accessibility label code does not change.
- Everything else: `MarketListView` section headers `.sectionHeader`, count badge `.caption`; detail field label `.caption`, value `.body`; `MarketMapView` callout title `.bodyEmphasis`, subtitle `.subheadline`; `OfflineBanner` and `MapFilterIndicator` `.footnote`; `ThemedButtonStyle` `.bodyEmphasis`.

### 5. System-rendered elements (`ThemeAppearance`, iOS only)

All code stays under `#if canImport(UIKit) && !os(visionOS)`.

- A platform helper `AppTypography.uiFont(for role: Role, textStyle override: ...) -> UIFont` in a new file `Theme/AppTypography+UIKit.swift` returns `UIFontMetrics(forTextStyle: role.uiTextStyle).scaledFont(for: UIFont(name: postScriptName, size: role.size) ?? .systemFont(ofSize: role.size))`. The fallback is the system font, same as for SwiftUI roles. A `Role` to `UIFont.TextStyle` mapping lives next to it.
- Tab bar: in the existing loop over the three item appearances, add `.font: tabBarFont` to both `titleTextAttributes` dictionaries (keeping the `.foregroundColor`). The `tabBarLabel` role (display, 12 pt, `.caption2`) is used by this appearance code and by the SwiftUI tab `Text`. `Role` has 13 cases.
- Navigation bar: the deployment target is iOS 26.5 (Liquid Glass) and the existing code deliberately sets only the tint, so the change is the smallest possible. Create `UINavigationBarAppearance()`, do NOT call any `configureWith...` method, set only `largeTitleTextAttributes = [.font: uiFont(.tabTitle)]` and `titleTextAttributes = [.font: uiFont(.navigationTitle)]`, and assign it to `standardAppearance`, `compactAppearance` and `scrollEdgeAppearance`. The tint line stays. Required check: screenshots of the Markets list with the large title unscrolled and scrolled, compared with the same screens on the base commit (`373af50`). If the bar background or scroll-edge look changed, drop the navigation bar appearance and fall back to SwiftUI: inline titles through `.toolbar { ToolbarItem(placement: .principal) { Text(...).appFont(.navigationTitle) } }` (keeping `navigationTitle` for accessibility), and report in the PR that large titles stay in the system font. Do not accept a changed system look silently.
- Search field: `.searchable` text and the prompt are system-owned. Best effort: `UISearchTextField.appearance().font = uiFont(.body)`. The prompt placeholder font cannot be set through appearance; if the simulator screenshot shows it still in SF, it is listed as a system-owned element in the PR (allowed by requirement 5.3).
- Swipe action title ("Remove"): set the label explicitly as `Text("Remove").appFont(.bodyEmphasis)` inside the `Label`, then check the simulator screenshot. If the system still renders it in SF, list it in the PR as a system-owned element (requirement 5.3). The same explicit-role-then-screenshot check applies to the search prompt (try `UISearchTextField.appearance().font`; if the prompt stays SF, document it). Both results go in the PR either way.
- macOS: navigation titles and window titles are drawn by AppKit and are not changed. The macOS tab control gets the SwiftUI font from the `Text` in the tab `Label` if the system honours it. This is recorded as "not verified visually" in the PR (requirement 8.8). No AppKit appearance code is added, because there is no supported global hook for title fonts.
- visionOS: the code compiles with the SwiftUI roles; UIKit appearance is excluded by the existing `!os(visionOS)` guard. Not verified at runtime.

### 6. Convention check

The gate lives in the `"prompt"` of step 6 (line 157) of the tracked file `.kiro/workflows/feature-to-pr.workflow.json`, in its "Project conventions" paragraph. This feature edits that prompt text to add the new rules (a tracked, in-scope change). Because the running workflow's gate still uses the old prompt text, the implementer also runs the checks by hand and pastes the commands and their (empty) output into the PR. Command form, run from the repo root, expecting zero lines each:

```
grep -rnE '<pattern>' NYCFarmerMarkets --include='*.swift' | grep -v '^NYCFarmerMarkets/Theme/'
```

The three new patterns:
- `\.custom\(|\bFont\.(system|custom)\(` (no custom or explicit system fonts in views)
- `Grim|N8ghtmare|Caligari|\.ttf` (no font or file names in Swift files outside `Theme/`)
- `\.font\(\s*(\.|Font\.)` (no `.font(.headline)` or `.font(Font.headline)`; views use `.appFont`)

`.font(variable)` forms are not caught by a regex; code review covers them. `IconView` in `Theme/AppIcon.swift` uses `.font(.system(size:))` inside `Theme/`, so it is allowed.

Layer ownership: the convention that "views use only roles" is enforced by this grep (the CI-like gate), not by the compiler. The "role maps to family" invariant is owned by `AppTypography.Role.family` and tested.

## Error handling

| Operation | Failure | Recoverable? | What the caller receives | Logging |
|---|---|---|---|---|
| `registerFonts()` finds no `.ttf` for a family | Resource not in the bundle | Yes | Registration reports the family as not registered; `isAvailable` returns false; roles return the system fallback | `Logger` (subsystem = bundle id, category `typography`), level `.error`, once per family, no user data |
| `CTFontManagerRegisterFontsForURL` returns false | Corrupt file, or already registered | Already registered: yes, treated as success, no log. Other errors: yes, fallback | Same as above | `.error` with the CFError description for non-"already registered" errors |
| `isAvailable(family)` false | Font not registered or name wrong | Yes | System font with the same text style and weight | Logged once at registration time, not per render |
| `uiFont(for:)` returns nil from `UIFont(name:size:)` | Same | Yes | `UIFont.systemFont(ofSize:)`, scaled with `UIFontMetrics` | Not logged separately |

No failure here is fatal and none is surfaced to the user. Registration never throws or crashes, and it uses no force unwraps. The registration result type is `struct Registration: Sendable { let registeredFamilies: Set<Family> }`; tests read it.

## Validation of inputs

The only external inputs are the bundle file names and the font files themselves. Rules: the file name must match `Family.fileName` exactly (case-sensitive); the PostScript name read back after registration must equal `Family.postScriptName`, otherwise the family is treated as unavailable (this catches a replaced file with a different internal name). No runtime user input reaches the typography code. Market names and other strings are rendered as before.

## Licensing report (requirement 2)

Done as a verification task, not in app code. A throwaway script (`python3` with `fontTools` if it can be installed in a temporary virtual environment, otherwise a small CoreText/`fc-scan` script, since `fontTools` is not installed on this machine) prints name IDs 0 (copyright), 7 (trademark), 8 (manufacturer), 9 (designer), 13 (license description) and 14 (license URL) for all three fonts. The PR description quotes the output verbatim. If name ID 13 and 14 are absent or say personal use, the PR says so plainly and does not state license terms. The script is deleted after use.

## Readability and layout (requirements 6 and 7)

- Splash: messages come from `LoadFailureMessage` and are short, but the hint is a sentence. The splash texts already use `.fixedSize(horizontal: false, vertical: true)` and centred multi-line text, so they wrap. The hint is the most likely hard-to-read case in the display font; the design keeps Display_Font per requirement 4.1, sets `splashHint` to a larger size than the old `.title3`, and the implementer reviews it on screen. If it is unreadable, the fix is a size change in the one file; switching the hint to the body font is a deviation from requirement 4.1 and must be raised with the owner, not done silently.
- Tab bar labels: three short words. Check at the largest standard size (`.accessibilityExtraExtraExtraLarge` is outside "standard", use `.xxxLarge`) that labels are not clipped.
- Navigation titles: large titles wrap or truncate in the system bar. "Favorites" and "Markets" are short (the Map tab has no navigation title). The detail inline title "Market details" is short. `MarketLocationMapView` shows `market.name` as an inline title, which can be long; the system truncates it with a tail ellipsis as before, and the full name is visible in the detail header (no information is lost that was visible elsewhere).
- Detail header market name: add `.fixedSize(horizontal: false, vertical: true)` only if screenshots with the longest market name show clipping; today it wraps in a `VStack`.
- Favorites rows: add `.lineLimit(nil)` is the default; the row `VStack` already grows. Check with a long name at `.xxxLarge`.
- Glyph coverage: the implementer checks that the fonts cover the characters in the market data (letters, digits, `.`, `,`, `-`, `'`, `&`, `/`, `·`, parentheses). Missing glyphs fall back per character to the system font by CoreText. Anything noticed is reported in the PR (localization is out of scope).
- Accessibility: only visual fonts change. `accessibilityLabel`, values, hints, identifiers and traits are not touched. UI tests find elements by identifier and by a few visible texts; text content is unchanged.

## Files

New:
- `NYCFarmerMarkets/Theme/AppTypography.swift` (families, roles, registration, availability, `appFont`).
- `NYCFarmerMarkets/Theme/AppTypography+UIKit.swift` (UIKit font helper, iOS guard `#if canImport(UIKit) && !os(visionOS)`).
- `NYCFarmerMarketsTests/AppTypographyTests.swift` (Swift Testing).
- `.kiro/specs/custom-fonts-integration/requirements.md`, `design.md`, `tasks.md` (copied from the task artifacts after approval).

Modified:
- `NYCFarmerMarkets/NYCFarmerMarketsApp.swift`: call `AppTypography.registerFonts()` first in `init()`; apply the root `.appFont(.body)`.
- `NYCFarmerMarkets/Theme/ThemeStyling.swift`: `ThemedButtonStyle` font; `ThemeAppearance.apply()` tab bar and navigation bar fonts and search field font.
- `NYCFarmerMarkets/Views/SplashView.swift`, `SplashLoadingIndicator.swift`, `RootTabView.swift`, `MarketDetailView.swift`, `MarketListView.swift`, `MarketMapView.swift`, `FavoritesView.swift`, `Views/Shared/MarketRow.swift`, `Views/Shared/OfflineBanner.swift`, `Views/Shared/MapFilterIndicator.swift`: replace system `.font(...)` calls with `.appFont(...)`.
- `.kiro/workflows/feature-to-pr.workflow.json`: extend the step 6 prompt's conventions paragraph with the three patterns.
- `NYCFarmerMarkets/Info.plist`: only if the built bundle shows the fonts in a `fonts/` subfolder (Decision 1).
- Not modified: `project.pbxproj`, the font files.

## Testing

Unit tests (Swift Testing, `NYCFarmerMarketsTests/AppTypographyTests.swift`), pure and fast:
1. `Family.postScriptName` values equal `Grim-Creeper-Regular` and `N8ghtmare`.
2. After `registerFonts()` in the test host, `CTFontCopyPostScriptName(CTFontCreateWithName(...))` equals each family's name (this covers the "resolves by real PostScript name" criterion on whichever platform runs the tests, and `UIFont(name:size:)` or `NSFont(name:size:)` non-nil under `#if canImport(UIKit)` / `#elseif canImport(AppKit)`).
3. Title roles (`splash`, `splashHint`, `tabTitle`, `tabBarLabel`, `navigationTitle`, `detailTitle`, `favoriteItemTitle`) have family `.display`; every other role has `.body`. Written as an exhaustive `switch` over `Role.allCases` so a new role forces a decision.
4. `resolvedFont(for:isAvailable:)` returns `.custom` with the right name, size and text style when available, and `.system` with the same text style and the role's `fallbackWeight` when not available, for every role.
5. A file-name check: the files named by `Family.fileName` are present in the test host's `Bundle.main` (or `Bundle(for:)`) resources, which covers "present in the built app bundle" per platform.

Integration and manual checks (cannot be unit tested):
- Build for iOS Simulator and macOS (scheme `NYCFarmerMarkets`), list the `.app` contents to confirm the `.ttf` paths, and check the build log for font or resource warnings.
- Run the unit suite and the UI suite (XCTest) on the iOS simulator and the unit suite on macOS.
- Simulator screenshots: splash (loading and failed via the existing `failDownload` launch option), each tab with large title visible, detail sheet, Favorites with at least one favorite, and one at a large Dynamic Type size with a long market name.
- The macOS visual check and visionOS are listed as not verified unless run.

## Out of scope reminders

No colors, icons, copy or accessibility labels change. `DrCaligari.ttf` stays tracked and bundled and is not registered or used. No font setting for users.

## Assumptions to confirm in the PR

1. Markets list row titles use the body font (only Favorites item titles use the display font).
2. The Retry button on the splash uses the body font.
3. The Map tab has the display font on its tab bar label only. Navigation titles of the detail sheet and the single-market map use the display font because they are "detail title" and share the global navigation appearance.

## Responses to design review findings

1. Addressed. Map tab gets the display font on the tab bar label only; no title added; the PR notes 4.2 applies to Markets and Favorites navigation titles.
2. Addressed. Tab-item `Text` and UIKit tab bar use `tabBarLabel`; `tabTitle` is for large navigation titles only; the enum has 13 cases.
3. Addressed. `fallbackWeight` added to `Role` and to the table; test 4 asserts it.
4. Addressed. Conditional `Info.plist` rule added to Decision 1 and the Files list.
5. Addressed. Gate named (step 6 prompt in `.kiro/workflows/feature-to-pr.workflow.json`), three regexes and command form given, manual run pasted in the PR.
6. Addressed. Minimal `UINavigationBarAppearance` without `configureWith...`, required before/after screenshots, SwiftUI `.principal` fallback.
7. Addressed. Claim reworded.
8. Addressed. One `isAvailable(postScriptName:)`, cached in the `registration` static, read by `Role.font`.
9. Addressed. Nested types marked `nonisolated`.
10. Addressed. Root font on `WindowGroup` content; Catalyst wording removed; grep covers `Font.` forms.
11. Addressed. Explicit `Text("Remove").appFont(.bodyEmphasis)` and search prompt check, results reported either way.

## Implementation notes (from design review round 2; the design loop was ended by the user with these still open)

These items override anything earlier in this document that conflicts with them. Treat them as requirements for the plan and the implementation.

1. **Dynamic Type for the UIKit-rendered bars: user chose (a) (was MEDIUM).** Do not rely on launch-time scaling. Observe `UIContentSizeCategory.didChangeNotification` and re-run the font part of `ThemeAppearance.apply()` (re-assign the tab bar, navigation bar and `UISearchTextField` appearances) so the system-owned bars rescale while the app is running. Add the notification hook to the Files list. Verify with a screenshot at `.xxxLarge` taken after changing the text size in a running app (simulator: Settings > Accessibility > Display & Text Size > Larger Text, or `xcrun simctl ui booted content_size extra-extra-extra-large`). State in the "Readability and layout" check that option (a) was used. If it proves impossible for a specific bar (appearance proxies only affect views created afterwards), say so explicitly in the PR as a limitation instead of claiming it works.
2. **macOS titles: user chose (b) (was MEDIUM).** Keep macOS as designed: navigation titles and tab titles on macOS stay in the system font. Do NOT add `.principal` toolbar items for macOS. Remove the sentence claiming macOS has "no supported hook" for title fonts (it is not true: a `.principal` toolbar item works on macOS); say instead that the owner chose not to style macOS titles in this change. In the PR description, add a named section "Deviations": macOS tab and navigation titles stay in the system font, deviating from requirements 4.2, 4.3 and 4.5 by the owner's decision, and the owner has confirmed it.
3. **Naming (NIT).** Define `struct Registration: Sendable { let availableFamilies: Set<Family> }` (a family is available if its PostScript name resolves after the registration attempt, including when `UIAppFonts` already registered it), `@discardableResult static func registerFonts() -> Registration` and `static func isAvailable(postScriptName: String) -> Bool`. Do not use the name `registeredFamilies`. `resolvedFont(for:isAvailable:)` keeps `(Family) -> Bool`, and `Role.font` passes `{ registration.availableFamilies.contains($0) }`.
4. **Snippets (NIT).** Write `static func uiFont(_ role: Role) -> UIFont` (no override parameter), define `let tabBarFont = AppTypography.uiFont(.tabBarLabel)`, combine bundle URLs as `(Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []) + (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "fonts") ?? [])`, and declare `nonisolated enum Resolved: Equatable, Sendable`.
5. **Detail borough line and splash caption (NIT).** Do not silently shrink them: map the detail borough line to a body-family role at the previous `.title3` size (for example `bodyEmphasis` at `.title3`), and the splash caption keeps a size comparable to its previous `.title3.weight(.semibold)` unless the design explicitly states the change is intended.
6. **Favorites rows (NIT).** No code change expected (line limit is already unlimited); verify with a long market name at `.xxxLarge`.
7. **Licenses.** The owner has already seen the license metadata read from the font files (Grim Creeper: 'Free to use for personal & commercial purposes' from sinisterfonts.com; N8ghtmare: copyright 'LionelPailloncy', no license text; DrCaligari: placeholder copyright, no license text). Confirm these in the license review and put the license findings AT THE TOP of the push approval request. The owner decided to KEEP DrCaligari.ttf for now (bundled, tracked, unused in the UI).

## Amendment after visual review (owner decisions)

After the first implementation was reviewed on the iOS simulator, the owner made these decisions. Where this section conflicts with earlier text in this document, this section wins.

1. **The body font is Dr. Caligari, not N8ghtmare.** N8ghtmare's digits were hard to read (the "5" looks like a backwards "s", so "57th Street" read like "s7th Street"). Dr. Caligari (`DrCaligari.ttf`, PostScript name `Dr.Caligari`) renders digits clearly and covers every character the app shows (letters, digits, curly quotes, "·" and "…"). `Grim Creeper` is unchanged for the title roles. `N8ghtmare.ttf` stays bundled and tracked but is no longer used. Earlier statements that "DrCaligari.ttf stays bundled and unused" and that N8ghtmare is the body family are superseded.
2. **Body sizes are scaled.** Dr. Caligari has a small x-height and thin strokes, so each family has a `sizeScale` (body 1.15, display 1.0) and a `minimumSize` (body 14 pt). `Role.effectiveSize = max(size * family.sizeScale, family.minimumSize)` is the size used with the custom font, in SwiftUI and in the UIKit bars. The system-font fallback keeps the original size and weight.
3. **Tab bar labels are capped.** `tabBarLabel` is limited to 15 pt when it scales with Dynamic Type (`Role.maximumPointSize`), because Grim Creeper's tall letters overlapped the tab icons at large accessibility sizes.
4. **The Markets screen is rebuilt when the text size changes** (`.id(dynamicTypeSize)` on its navigation container). The system search field keeps its old height after a live text-size change and its icon and prompt were clipped. The search text lives in `MarketStore` and the expanded sections in the view's state, so both are kept.
5. **The row separator is a comma** ("Manhattan, Tenth Avenue & W 57th Street"). Dr. Caligari maps the "·" character but does not draw it.

### Known limitations and deviations (to state in the PR)

- **Map tab tab-bar labels use the system font.** On the Map tab (a full-screen map under the bar) the tab bar is drawn by the system without the app's tab bar appearance, so its three labels are not in Grim Creeper. Two attempts to fix it (a second font source on `UITabBarItem` and a visible tab bar background on the Map screen) had no effect and were removed. Cause not confirmed.
- **macOS tab and navigation titles stay in the system font** (owner's decision), which deviates from requirements 4.2, 4.3 and 4.5. The macOS build compiles and the fonts are registered at launch in code; no macOS visual check was done.
- **Letter shapes.** Dr. Caligari is a calligraphic face: "t" can look like "r" or a cross and "h" has a flourish, so some words ("Street", "Greenmarket") need a second look. Digits are clear. This comes from the font, not the size.
- **Licenses.** Dr. Caligari's file has a placeholder copyright ("(your company)") and no license text, so its author and terms are unknown. It now covers most of the UI text, so this is the main distribution risk. N8ghtmare (copyright "LionelPailloncy", no license text) is no longer used but is still in the repository. Grim Creeper states "Free to use for personal & commercial purposes" (sinisterfonts.com). Confirm the terms before distributing.
- **Not verified:** visionOS; macOS at runtime; the live text-size change was checked on the Markets screen only.

## Amendment 2: manual design changes after PR #8 (owner commits)

The owner changed the typography by hand on `main` after PR #8 was merged (`d74e03e` "Replace fonts for readability, correct section header size", `40dd19c` "Correct Section headers size", `a3ad360` "update test to match change in Family Font role"). Where this section conflicts with earlier text, including the first amendment, this section wins. This is the current state of `Theme/AppTypography.swift`.

### Changes

1. **The body font is Breath of the House** (`Breath of the House.ttf`, by BlackFridayFont), chosen for readability. `Family.body.postScriptName` is `"Breath-of-the-House"` and `fileName` is `"Breath of the House.ttf"`. Grim Creeper is unchanged for the display family.
2. **Unused fonts removed.** `DrCaligari.ttf` and `N8ghtmare.ttf` were deleted from `NYCFarmerMarkets/fonts/`. `Info.plist` `UIAppFonts` lists exactly `Grim Creeper.ttf` and `Breath of the House.ttf`. Earlier statements that Dr. Caligari or N8ghtmare stay bundled are superseded.
3. **`sectionHeader` is a display role.** It moved from the body family to Grim Creeper so the borough headers read as headers. `Role` still has 13 cases; the display family now has 8 roles.
4. **Sizes changed:** `sectionHeader` 15 → 30 pt; `splash` 26 → 40 pt. The display family has scale 1 and no floor, so both draw at their design size.
5. **Borough header row (`Views/MarketListView.swift`):** the market count uses `.appFont(.sectionHeader)` (was `.caption`) and the chevron `IconView` is 30 pt (was 12), so the whole row matches the header size.
6. **Unchanged from the first amendment:** body `sizeScale` 1.15 and `minimumSize` 14 pt; tab bar label cap 15 pt (`maximumPointSize`); `.id(dynamicTypeSize)` on the Markets screen; ", " as the row separator.
7. **Tests:** `AppTypographyTests` expects the new body PostScript name and `sectionHeader` in `.display`. All 10 typography tests pass on the iOS simulator (checked 2026-11-14).

### Current size table

| Role | Family | Size | relativeTo | Drawn at (custom font) |
|---|---|---|---|---|
| splash | display | 40 | .title2 | 40 |
| splashHint | display | 22 | .title3 | 22 |
| tabTitle | display | 34 | .largeTitle | 34 |
| tabBarLabel | display | 12 | .caption2 | 12 (cap 15 in the UIKit bar) |
| navigationTitle | display | 20 | .headline | 20 |
| detailTitle | display | 30 | .title | 30 |
| sectionHeader | display | 30 | .subheadline | 30 |
| favoriteItemTitle | display | 20 | .headline | 20 |
| body | body | 17 | .body | 19.55 |
| bodyEmphasis | body | 17 | .headline | 19.55 |
| subheadline | body | 15 | .subheadline | 17.25 |
| caption | body | 12 | .caption | 14 (floor) |
| footnote | body | 13 | .footnote | 14.95 |

### Notes and open points

- **PostScript name.** The font file stores its PostScript name as `Breath of the House` (with spaces) in both name records. The code uses `Breath-of-the-House`, and CoreText resolves it: `bothFamiliesResolveAfterRegistration` passes. No change needed, but if a future CoreText version stops matching, the body text would fall back to the system font silently (logged as "Font not available").
- **Scale and floor not re-checked.** The 1.15 scale, the 14 pt floor and the comment "small x-height and thin strokes" were tuned for Dr. Caligari. They were kept as is for Breath of the House and have not been reviewed on screen for the new font.
- **Separator glyph not re-checked.** The ", " separator replaced "·" because Dr. Caligari does not draw it. Whether Breath of the House draws "·" has not been checked.
- **Section header and Dynamic Type.** `sectionHeader` draws at 30 pt but scales relative to `.subheadline`, so at accessibility sizes it grows by the subheadline curve to well above 30 pt. Not checked at `.xxxLarge` with the 30 pt chevron.
- **Convention gate.** The font-name pattern in the workflow gate is `Grim|N8ghtmare|Caligari|\.ttf`. It does not match `Breath`, so a hard-coded "Breath of the House" string outside `Theme/` would not be caught by the name part (the `.custom(` pattern still catches the call itself).

### Licensing (supersedes the license notes above)

- **Breath of the House:** embedded copyright "Copyright (c) 2026 by BlackFridayFont. All rights reserved."; the license field asks for a €2 payment, after which the font may be used for one project; OS/2 `fsType` 0x0004 (preview & print). The [dafont page](https://www.dafont.com/breath-of-the-house.font) states the same €2 terms. Some mirror sites list it as donationware or personal use only. No license file is in the repository, and the `.ttf` is published in this public GitHub repository, which the license text does not mention. The owner paid the €2 license (confirmed 2026-11-14). Still open: ask the author whether the `.ttf` may stay in the public repository.
- **Grim Creeper:** "Free to use for personal & commercial purposes" (sinisterfonts.com), as before.
- Dr. Caligari and N8ghtmare are no longer in the repository; their licensing open points no longer apply to new builds (they remain in git history).

### Known limitations (still current)

- Map tab tab-bar labels use the system font (cause not confirmed).
- macOS tab and navigation titles stay in the system font (owner's decision).
- Not verified: visionOS; macOS at runtime; the new font at large Dynamic Type sizes.
