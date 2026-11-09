# Design Document

## Overview

A new `AppCopy` type holds the text covered by `requirements.md`. Views read strings from it, in the same way they already read colors from `AppPalette` and icons from `AppIcon`. Strings that depend on a value are pure functions, so they can be unit tested. Accessibility text is exposed separately and stays plain.

The design is based on the code as merged in PR #4 (`origin/main` at `d7d3ee8`).

| Topic | Decision |
|---|---|
| Home of the text | `Theme/AppCopy.swift`, a `nonisolated enum AppCopy` with static strings and pure functions |
| Value-dependent text | Pure functions: `mapFilterSummary(query:count:)` and `mapFilterAccessibility(query:count:)` |
| Accessibility | Each Spooky_Copy string that matters has a plain counterpart used with `.accessibilityLabel` |
| Failure texts | `LoadFailureMessage` stays where it is; it already follows the tone |
| Localization | Out of scope. Strings stay as plain Swift literals inside `AppCopy` |

## Changes by file

### `Theme/AppCopy.swift` (new)

```swift
nonisolated enum AppCopy {
    // Splash
    static let splashLoadingCaption = "Summoning markets…"
    static let splashLoadingAccessibility = "Loading farmers markets"   // unchanged

    // Offline banner
    static let offlineBanner = "Lost in the fog, showing saved markets"
    static let offlineBannerAccessibility = "Offline, showing saved data"

    // Search
    static let searchPrompt = "Hunt by name, address or borough"
    static let noResultsTitle = "Nothing lurking here"
    static let noResultsTitleAccessibility = "No markets found"
    static func noResultsHint(query: String) -> String { "No markets match “\(query)”. Try another search." }

    // Map filter indicator
    static func mapFilterSummary(query: String, count: Int) -> String
    static func mapFilterAccessibility(query: String, count: Int) -> String

    // Detail view
    static let missingValue = "Shrouded in mist"
    static let missingValueAccessibility = "Not listed"
}
```

`mapFilterSummary` trims the query with the same rule as `MarketSearch.normalized`. It returns `No markets lurking for “q”` for 0, `1 market lurking for “q”` for 1 and `<n> markets lurking for “q”` otherwise. `mapFilterAccessibility` returns the plain `Showing <n> result(s) for <q>` form that the indicator had before.

### Existing code

- `MarketSearch.summary(query:count:)` currently builds `Showing 3 results for "kale"`. It becomes a thin call to `AppCopy.mapFilterSummary`, or is removed and its callers updated. The decision: remove it, so the search rule and the wording live in different places. `MapFilterIndicator` calls `AppCopy` directly.
- `MapFilterIndicator`: shows `AppCopy.mapFilterSummary`, with `.accessibilityLabel(AppCopy.mapFilterAccessibility(...))`. The identifier `map-filter-indicator` stays.
- `OfflineBanner`: `Text(AppCopy.offlineBanner)` with the accessibility label `AppCopy.offlineBannerAccessibility` on the combined element. The identifier `offline-banner` stays.
- `MarketListView`: `.searchable(..., prompt: AppCopy.searchPrompt)`; the no-results `ContentUnavailableView` uses `noResultsTitle` and `noResultsHint(query:)`, and the title `Text` carries `noResultsTitleAccessibility` and the identifier `search-no-results-title`. The label and identifier stay on the title only, so the description (hint) is still read by VoiceOver.
- `MarketDetailView`: the detail row shows `value ?? AppCopy.missingValue`. The row uses `.accessibilityElement(children: .combine)` today, so the missing-value case needs an explicit accessibility value `AppCopy.missingValueAccessibility`.
- `SplashLoadingIndicator`: wrap the dots in a `VStack` with a caption `Text(AppCopy.splashLoadingCaption)` in `.title3.weight(.semibold)`. The VStack remains one accessibility element (`children: .ignore`) with the label `AppCopy.splashLoadingAccessibility` and identifier `splash-loading`. `SplashView` shows the indicator only for the loading phase already, so the failure state never shows the caption.

## Tone rules (for reviewers)

- Spooky in titles and passive text; plain in hints, buttons and anything that changes data.
- One spooky word per message. Vocabulary: summon, haunt, lurk, fog, mist, spooked.
- Never put an error code or domain in a user-facing string.
- VoiceOver text is plain and says what the visible text means.

## Risks and notes

- **Contrast:** the splash caption sits on the olive background at about 3.5:1, so it must use a large, semibold style.
- **Clarity of "Shrouded in mist":** it is an unusual phrase for a missing value, and the accessibility text carries the real meaning. It is the most likely line to be reverted.
- **Text width:** "Lost in the fog, showing saved markets" is longer than the old banner. Check it at large Dynamic Type sizes on a small phone.
- **Concurrent work:** no workflow is running now, but any new change to these views should land first or be rebased onto this one.

## Testing Strategy

Unit tests (Swift Testing):
- `AppCopyTests`: the singular, plural and zero forms of `mapFilterSummary`; trimming of the query; `mapFilterAccessibility` singular and plural; the pure functions return the same output for the same input.
- A table test that no `AppCopy` string contains `NSURLErrorDomain`, `error -` or `Code=`.
- A table test that every plain accessibility string is non-empty and contains none of the spooky vocabulary words (lurk, fog, mist, haunt, summon, spooked).
- `MarketSearchTests`: remove the tests of the old `summary` text.

UI tests (XCTest):
- `testSearchFiltersList`: wait for the element with identifier `search-no-results-title` and assert its label is "No markets found" (the plain label replaces the visible text for accessibility, so the visible "Nothing lurking here" is not queryable).
- Keep the map filter tests that use the `map-filter-indicator` identifier; add an assertion on the new text for one query if the existing test reads the label.
- The splash tests keep using `splash-loading`, `splash-screen`, `splash-error` and `splash-retry`.

Manual checks: Dynamic Type, VoiceOver reading of each changed element, and the look of the splash caption.
