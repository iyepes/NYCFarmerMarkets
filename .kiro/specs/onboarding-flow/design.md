# Design Document

## Overview

This feature places the owner's `Onboarding/` views between the splash and the tabs. Onboarding shows once per install, after the first successful data load. The design changes four areas:

1. A pure `OnboardingDecision` in `Models/` chooses the screen (splash, onboarding or tabs) from the splash phase and the `hasSeenOnboarding` flag.
2. `AppRootView` owns the flag, calls the decision, and renders one of three screens. Its existing `hasDismissed` latch and single `store.load()` task stay as they are.
3. The three owner files are adjusted to the theme conventions: icons from `AppIcon`, text from `AppCopy`, fonts from `.appFont`, identifiers, an explicit hiss cue and Reduce Motion handling. Copy and the `.glass` buttons stay as written.
4. `LaunchOptions` gets two flags, and `NYCFarmerMarketsApp.init` applies a pure "flag action" to `UserDefaults` before the root view exists, so existing UI tests keep reaching the tabs.

Research: all findings come from the repo (no external research was needed). Facts that shape the design:

- `AppRootView` already latches `hasDismissed` through `.onChange(of: phase, initial: true)` and runs `store.load()` in a single `.task` on the root `ZStack`, outside any switched child. Keeping both there satisfies requirement 4.1 without new code.
- `RootTabView` plays `.door` in `.onAppear`, guarded by its own `@State hasAppeared`. If `RootTabView` is created only when the screen is `.tabs`, the door plays once after onboarding and never during it (requirements 8.2 to 8.4). No change to `RootTabView`.
- `SoundController.play(_:)` already applies `SoundPolicy` (sounds off, VoiceOver on, test muted). Views only send cues, so requirements 8.6 and 8.7 hold without new sound code.
- `AppTypography` has no emoji or hero-symbol role. Details are under Decisions.
- `LaunchOptions` parses flags with `arguments.contains(...)`. The new flags use the same pattern (requirement 9.6).
- Unit tests are hosted (they use `@testable import`), and `AppCopyTests` and `everyIconResolves` already iterate copy and `AppIcon.allCases`, so new strings and cases join existing checks.

### Design decisions

| Decision | Choice | Reason |
|---|---|---|
| Source of truth for the flag | `UserDefaults` key `hasSeenOnboarding`, read by one `@AppStorage` in `AppRootView`. `OnboardingView` receives a `Binding<Bool>` and writes through it. | One reader, one writer path. The owner's `@AppStorage` inside `OnboardingView` would be a second wrapper on the same key; passing a binding avoids it and keeps previews simple (`.constant(false)`). |
| How completion reaches the root | The binding. No callback. | Setting the flag changes `screen` in `AppRootView`, which swaps the view. A callback would duplicate this. |
| Screen choice | Pure `OnboardingDecision.screen(phase:hasSeenOnboarding:)` returning `RootScreen`. | Testable without SwiftUI (requirement 5). |
| Latch | `AppRootView` passes `hasDismissed ? .dismissed : phase` to the decision. | Same semantics as today: once the splash is dismissed it never returns, even if a later refresh changes `phase`. Using the latch in the same pass also avoids a one-frame gap between `phase` and the `onChange`. |
| Launch-flag precedence | Pure `OnboardingFlagAction` computed in `LaunchOptions`, applied by a small function that takes a `UserDefaults`. | Precedence and the write are unit tested with a throwaway suite (requirements 9.1 to 9.5, 10.2). |
| Hero symbol and emoji fonts | Emoji uses `.appFont(.splash)`, and the `splash` role grows from 40 to 44 pt. Hero symbol is drawn by `IconView(_, size: 72)`, so its size is set in `Theme/`. No new `AppTypography` role. | Requirements 7.3 and 7.8. See "Typography" below. |
| Buttons | Keep `.glass` and the tinted glass `Next` button. Send `.hiss` explicitly in the actions. | Owner decision. Plain-style buttons call `sounds.play(.hiss)` per `theme-conventions.md`. |

## Architecture

### Screen selection

```mermaid
flowchart TD
    A[AppRootView body] --> B{phase passed to decision}
    B -->|hasDismissed ? dismissed : phase| C[OnboardingDecision.screen]
    C -->|phase is loading or failed| S[SplashView]
    C -->|dismissed and flag false| O[OnboardingView]
    C -->|dismissed and flag true| T[RootTabView]
    O -->|Skip or Enter the market sets flag true| T
```

### Screen states

```mermaid
stateDiagram-v2
    [*] --> Splash
    Splash --> Onboarding: data ready, minimum time elapsed, flag false
    Splash --> Tabs: data ready, minimum time elapsed, flag true
    Splash --> Splash: load failed or zero markets (Retry)
    Onboarding --> Tabs: Skip or Enter the market
```

There is no edge from Onboarding or Tabs back to Splash. The market load keeps running in the root `.task` while Onboarding shows (requirements 4.1 to 4.4).

### Launch flow

```mermaid
flowchart LR
    I[NYCFarmerMarketsApp.init] --> P[LaunchOptions parses arguments]
    P --> F[onboardingFlagAction]
    F -->|reset| R[remove hasSeenOnboarding]
    F -->|markSeen| M[set hasSeenOnboarding true]
    F -->|none| N[leave unchanged]
    R --> V[AppRootView created]
    M --> V
    N --> V
```

## Components and Interfaces

### `Models/OnboardingDecision.swift` (new, Foundation only)

```swift
import Foundation

/// The top-level screen the app shows.
nonisolated enum RootScreen: Equatable, Sendable {
    case splash, onboarding, tabs
}

nonisolated enum OnboardingDecision {
    /// `UserDefaults` key for "the user has finished or skipped onboarding".
    static let defaultsKey = "hasSeenOnboarding"

    /// Splash while loading or failed; once dismissed, onboarding until the flag is true, then tabs.
    static func screen(phase: SplashPhase, hasSeenOnboarding: Bool) -> RootScreen {
        guard phase == .dismissed else { return .splash }
        return hasSeenOnboarding ? .tabs : .onboarding
    }
}
```

No stored state, no clock, no counters (requirements 2.6, 5.1, 5.6). A missing key reads as false through `@AppStorage(...) = false` and through `UserDefaults.bool(forKey:)` (requirement 2.4).

### `Models/LaunchOptions.swift` (changed)

Added to the existing struct:

```swift
/// Marks onboarding as seen at launch. Argument: `-uiTestingSkipOnboarding`.
var skipOnboarding = false
/// Removes the onboarding flag at launch, so onboarding shows. Argument: `-uiTestingResetOnboarding`.
var resetOnboarding = false

/// What launch does to the onboarding flag. `-uiTestingResetOnboarding` wins over the other two.
nonisolated enum OnboardingFlagAction: Equatable, Sendable { case none, markSeen, reset }

var onboardingFlagAction: OnboardingFlagAction {
    if resetOnboarding { return .reset }
    if skipOnboarding || resetFavorites { return .markSeen }
    return .none
}
```

`init(arguments:)` adds `skipOnboarding = arguments.contains("-uiTestingSkipOnboarding")` and `resetOnboarding = arguments.contains("-uiTestingResetOnboarding")`. `contains` on `[String]` is exact and case-sensitive, and does not consume the next argument (requirement 9.6).

The write is a second pure-ish function in the same file, so a test can run it on a throwaway `UserDefaults(suiteName:)`:

```swift
extension LaunchOptions.OnboardingFlagAction {
    func apply(to defaults: UserDefaults, key: String = OnboardingDecision.defaultsKey) {
        switch self {
        case .none: break
        case .markSeen: defaults.set(true, forKey: key)
        case .reset: defaults.removeObject(forKey: key)
        }
    }
}
```

### `NYCFarmerMarketsApp.init` (changed)

After the existing `options.resetFavorites` block, one line:

```swift
options.onboardingFlagAction.apply(to: .standard)
```

It runs inside `init`, before `body` creates `AppRootView`, so `@AppStorage` reads the final value on its first access (requirements 9.1 to 9.5). The existing favorites and sound-setting clearing under `-uiTestingReset` is untouched.

### `Views/AppRootView.swift` (changed)

```swift
@AppStorage(OnboardingDecision.defaultsKey) private var hasSeenOnboarding = false

private var screen: RootScreen {
    OnboardingDecision.screen(phase: hasDismissed ? .dismissed : phase,
                              hasSeenOnboarding: hasSeenOnboarding)
}

var body: some View {
    ZStack {
        switch screen {
        case .splash:
            SplashView(phase: phase, hint: errorHint) { Task { await store.refresh() } }
                .transition(reduceMotion ? .identity : .opacity)
        case .onboarding:
            OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                .transition(reduceMotion ? .identity : .opacity)
        case .tabs:
            RootTabView()
        }
    }
    .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: screen)
    .task { await store.load() }            // unchanged: one load, from the root
    .task { try? await Task.sleep(for: minimumDisplayTime); minimumTimeElapsed = true }  // unchanged
    .onChange(of: phase, initial: true) { _, newValue in
        if newValue == .dismissed { hasDismissed = true }                                // unchanged latch
    }
    .onChange(of: voiceOverEnabled, initial: true) { _, enabled in sounds.setVoiceOverOn(enabled) }  // unchanged
}
```

Why this satisfies the requirements:

- 1.2, 2.1, 8.4: `RootTabView` exists only in the `.tabs` case. With the flag true, `screen` goes from `.splash` straight to `.tabs`; `.onboarding` is never produced.
- 4.1: both `.task` modifiers sit on the `ZStack`, which is not replaced when `screen` changes. Retry still calls `store.refresh()`.
- 4.4: the `phase` computed property sees a non-empty market list, so `errorMessage` is nil and an offline refresh failure shows nothing while Onboarding is up. The tabs show the offline banner as today.
- 4.5 to 4.7: `failed` and `loading` phases map to `.splash` for both flag values. After Retry succeeds, `phase` becomes `.dismissed` once the minimum time has elapsed, and the decision applies the flag.
- `SplashView` is still passed `phase` (not the latched value), as today.

### `Onboarding/OnboardingPage.swift` (changed)

- `HeroStyle` and `OnboardingPage` become `nonisolated` (and `Sendable`) so unit tests can read `OnboardingPage.all` without `@MainActor`. Both types hold only value data.
- `symbol: String` becomes `symbol: AppIcon`. Page values: `.onboardingShipping`, `.onboardingMap`, `.onboardingPeople`.
- All copy, ids, eyebrows, emoji, `heroImage` names and `heroStyle` values stay exactly as written. The page-to-asset mapping is already correct: page 0 `pirate-ship`, page 1 `map-image` (framed), page 2 `dairy-products-pallete`.
- The file stays in `Onboarding/`; the type is data, but it imports the theme icon type, so moving it to `Models/` is optional and not part of this feature.

### `Onboarding/OnboardingPageView.swift` (changed)

| Line today | Change | Requirement |
|---|---|---|
| `Image(systemName: "moon.stars.fill")` in bullets | `AppIcon.onboardingBullet.image` (still `.accessibilityHidden(true)`, still `.foregroundStyle(AppPalette.accentSecondary.color)`). The image inherits the environment body font, so it scales like the bullet text, as today. | 7.1, 6.2 |
| `Image(systemName: page.symbol).font(.system(size: 72))` | `IconView(page.symbol, size: 72)` | 7.1, 7.3 |
| `Text(page.emoji).font(.system(size: 44))` | `Text(page.emoji).appFont(.splash)` | 7.3, 7.8 |
| Title `Text` | add `.accessibilityAddTraits(.isHeader)` | 6.5 |
| `ScrollView` | add `.accessibilityIdentifier("onboarding-page-\(page.id)")` | 7.5 |

Everything else stays: the `hero` view is `.accessibilityHidden(true)` as a whole (this covers the image, the emoji and the symbol, requirement 6.2); eyebrow, title, message and the bullets are separate `Text` views in top-to-bottom order (requirements 6.5, 6.6); the `ScrollView` with `contentMargins` and `.scrollBounceBehavior(.basedOnSize)` scrolls at every Dynamic Type size (requirement 6.3). The `#Preview` is unchanged.

### `Onboarding/OnboardingView.swift` (changed)

```swift
struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @Environment(SoundController.self) private var sounds
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selection = 0
    ...
}
```

Changes, in order:

1. Replace `@AppStorage("hasSeenOnboarding")` with `@Binding var hasSeenOnboarding: Bool`. `#Preview` becomes `OnboardingView(hasSeenOnboarding: .constant(false)).environment(SoundController(testMuted: true, player: SilentSoundPlayer()))`.
2. Root: put `.accessibilityElement(children: .contain)` and `.accessibilityIdentifier("onboarding-screen")` on the `GeometryReader` content, as `SplashView` does for `splash-screen`. Without `.contain` the identifier would be copied onto every child.
3. Skip button: `Button(AppCopy.onboardingSkip, action: skip)`, `.accessibilityLabel(AppCopy.onboardingSkip)`, `.accessibilityIdentifier("onboarding-skip")`, `.opacity(isLast ? 0 : 1)`, `.disabled(isLast)` and new `.accessibilityHidden(isLast)` (requirements 3.5, 3.7, 6.1).
4. Page indicator: the label becomes `AppCopy.onboardingPageIndicator(page: selection + 1, count: pages.count)`, plus `.accessibilityIdentifier("onboarding-page-indicator")`. It keeps `.accessibilityElement(children: .ignore)`, so it stays one element with no value (requirements 3.9, 6.8, 7.4).
5. Next button: `Text(AppCopy.onboardingPrimaryLabel(isLast: isLast))`; `.accessibilityLabel` with the same string; `.accessibilityIdentifier("onboarding-next")`. The button keeps `.buttonStyle(.plain)` and the tinted `.glassEffect(... .interactive())` (requirements 3.2, 3.3, 6.1, 7.5).
6. Actions:

```swift
private func skip() {
    guard !hasSeenOnboarding else { return }   // repeated taps while the view is leaving
    sounds.play(.hiss)
    hasSeenOnboarding = true
}

private func advance() {
    guard !hasSeenOnboarding else { return }
    sounds.play(.hiss)
    if isLast {
        hasSeenOnboarding = true
    } else if reduceMotion {
        selection += 1
    } else {
        withAnimation(.easeInOut) { selection += 1 }
    }
}
```

   - `advance` only runs `selection += 1` when `!isLast`, so the page never exceeds the last index. `selection` never goes below 0 because no code decrements it (swipes are clamped by the page `TabView`).
   - The guard makes the flag write happen at most once and the hiss play at most once per effective tap; once the flag is true the root swaps the view (requirement 3.10).
   - The flag is written through the binding, which is `UserDefaults` itself, before the root re-evaluates `screen` (requirement 2.2).
   - A swipe changes only `selection`, so labels and the Skip state follow `isLast` with no extra code, and no cue is sent (requirements 3.8, 8.5).
   - Reduce Motion: no `withAnimation` for the programmatic change (requirement 6.4). Whether the paged `TabView` still slides without a transaction is verified manually (see Testing Strategy).

### `Theme/AppIcon.swift` (changed)

New cases, each with a `source` and an `accessibilityName` (the exhaustive switches force both):

| Case | Source | Accessibility name |
|---|---|---|
| `onboardingBullet` | `.symbol("moon.stars.fill")` | "Bullet" |
| `onboardingShipping` | `.symbol("shippingbox.fill")` | "Shipping" |
| `onboardingMap` | `.symbol("map.fill")` | "Map" |
| `onboardingPeople` | `.symbol("person.2.fill")` | "Neighbors and growers" |

`.openInMaps` already uses `map.fill`, but it is named "Go to Map" and may change independently, so onboarding gets its own case. The names are used only if an icon is ever exposed; the onboarding views hide these icons.

### `Theme/AppCopy.swift` (changed)

```swift
// MARK: Onboarding
static let onboardingSkip = "Skip"
static let onboardingNext = "Next"
static let onboardingEnter = "Enter the market"

static func onboardingPrimaryLabel(isLast: Bool) -> String { isLast ? onboardingEnter : onboardingNext }
static func onboardingPageIndicator(page: Int, count: Int) -> String { "Page \(page) of \(count)" }
```

These strings are visible text and also the accessibility labels, because the requirements ask for labels equal to the visible text (6.1, 7.4). The page copy itself stays in `OnboardingPage.all`, unchanged. `AppCopyTests.allVisibleStrings` gets the three labels and one indicator string so the existing tone checks cover them.

### Typography

The roles are `splash` (44), `splashHint`, `tabTitle`, `tabBarLabel`, `navigationTitle`, `detailTitle`, `sectionHeader`, `favoriteItemTitle`, `body`, `bodyEmphasis`, `subheadline`, `caption`, `footnote`. The onboarding files already use `.footnote`, `.detailTitle`, `.body` and `.bodyEmphasis`, which exist.

- Emoji (44 pt today): the emoji uses `.appFont(.splash)`. The `splash` role changes from 40 to 44 pt (requirement 7.8) so the emoji keeps its current 44 pt size. The role stays in the display family and scales with Dynamic Type. Grim Creeper has no emoji glyphs, so the system draws them from its fallback font at the requested size. No new role is added.
- The change is one line in `Theme/AppTypography.swift`: `case .splash: 40` becomes `case .splash: 44`. Display roles are not scaled (`effectiveSize == size`), so `effectiveSize` also becomes 44.
- Other `.splash` users: only `SplashView` uses `.appFont(.splash)` besides onboarding, for the failure message (`splash-error`). That message grows from 40 to 44 pt. The loading caption in `SplashLoadingIndicator` uses `.splashHint` (22 pt) and does not change. The failure message already wraps (`fixedSize(horizontal: false, vertical: true)`, centered), so the extra 4 pt needs no layout change; check it at large Dynamic Type sizes during the manual pass.
- `AppTypographyTests` pins no splash size or derived value today. `displayRolesKeepTheirDesignSize` asserts `effectiveSize == size` for every display role and passes unchanged. One example test is added to pin `splash` at 44 (requirements 7.8, 10.13).
- Hero symbol (72 pt): a text role cannot express this size (the largest, `splash`, is 44). `IconView` draws the symbol at 72 pt, and the size is set inside `Theme/AppIcon.swift`, which already calls `.font(.system(size:))` in the Theme folder and hides itself from VoiceOver. This satisfies requirement 7.3 as worded: `Onboarding/` contains no `.font(` call, `Font.system` or `Font.custom`, and every text font, including the emoji, goes through `.appFont`. No requirement amendment is needed.

### Docs (changed)

- `tech.md`, "Launch arguments": add `-uiTestingSkipOnboarding` (writes `hasSeenOnboarding = true` at launch) and `-uiTestingResetOnboarding` (removes the flag so onboarding shows; wins over `-uiTestingSkipOnboarding` and `-uiTestingReset`). State that `-uiTestingReset` also writes `true` unless the reset argument is present. Add `OnboardingDecision` and `Onboarding/` to the Layout list.
- `theme-conventions.md`: in the Fonts role list, change `splash` (40) to `splash` (44). Add `AppIcon` cases `onboardingBullet`, `onboardingShipping`, `onboardingMap`, `onboardingPeople`; add the onboarding strings to the Copy section; note that onboarding buttons use `.glass` and call `sounds.play(.hiss)` explicitly; note that the onboarding emoji uses `.splash` and the hero symbol size is set by `IconView`; list the identifiers.
- `product.md`: add the onboarding screen to the Screens list between Splash and Tabs, and the flag `hasSeenOnboarding` under Data.
- Per `git-and-workflow.md`, no change to the workflow files is needed.

## Data Models

| Name | Kind | Where | Notes |
|---|---|---|---|
| `RootScreen` | `nonisolated enum` (`splash`, `onboarding`, `tabs`) | `Models/OnboardingDecision.swift` | Output of the decision. |
| `OnboardingDecision` | `nonisolated enum` (namespace) | same | `defaultsKey`, `screen(phase:hasSeenOnboarding:)`. |
| `LaunchOptions.OnboardingFlagAction` | `nonisolated enum` (`none`, `markSeen`, `reset`) | `Models/LaunchOptions.swift` | `apply(to:key:)` performs the write. |
| `LaunchOptions.skipOnboarding`, `.resetOnboarding` | `Bool` | same | Default false. |
| `OnboardingPage`, `HeroStyle` | `nonisolated struct` / `enum`, `Sendable` | `Onboarding/OnboardingPage.swift` | `symbol` becomes `AppIcon`. |
| `hasSeenOnboarding` | `Bool` in `UserDefaults`, absent means false | `OnboardingDecision.defaultsKey` | Read by `AppRootView` only; written by `OnboardingView` through a binding and by launch arguments. |

### Accessibility identifiers

| Identifier | Element |
|---|---|
| `onboarding-screen` | Root view (container) |
| `onboarding-skip` | Skip button |
| `onboarding-next` | Next / "Enter the market" button |
| `onboarding-page-indicator` | Page dots |
| `onboarding-page-0`, `-1`, `-2` | Scroll view of each page |

Existing identifiers are not renamed.

### Sound behavior summary

| Moment | Cue | Where |
|---|---|---|
| Tap Skip | `.hiss` once | `OnboardingView.skip()` |
| Tap Next (any page, including "Enter the market") | `.hiss` once | `OnboardingView.advance()` |
| Swipe between pages | none | no code |
| Tabs appear after onboarding | `.door` once | `RootTabView.onAppear`, created only after the flag is true |
| VoiceOver on, sounds off, `-uiTestingMuteSounds` | nothing plays | `SoundController` / `SoundPolicy` (unchanged) |

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

Reflection: the prework found these testable pure behaviors. Merged: the four decision-table cases, the "failed or loading" cases and the statelessness checks are separate enough to keep as three properties (table, message independence, history independence). The launch precedence rules for requirements 9.1 to 9.5 are one mapping, so they are one property, and the write effect is a second. The label helpers for 3.2, 3.3, 3.9 and 7.4 merge into one property over page indices. The page-content rules (5.7, 10.3) and the asset check (7.7, 10.12) merge into two properties (content shape, asset resolution). UI-only criteria (swipe, tab absence, VoiceOver, Reduce Motion, sounds in the views) are covered by example tests or manual checks in the Testing Strategy.

### Property 1: Decision table

For any splash phase and any flag value, `OnboardingDecision.screen` returns `.splash` when the phase is `.loading` or `.failed`, `.onboarding` when the phase is `.dismissed` and the flag is false, and `.tabs` when the phase is `.dismissed` and the flag is true.

**Validates: Requirements 1.1, 2.1, 5.2, 5.3, 5.4**

### Property 2: Failure message does not matter

For any message string (empty, whitespace only, long, non-ASCII) and any flag value, `OnboardingDecision.screen(phase: .failed(message:), ...)` returns `.splash`. It never returns `.onboarding` or `.tabs`.

**Validates: Requirements 4.5, 4.7, 5.2**

### Property 3: Decision has no memory

For any sequence of (phase, flag) inputs, the result for each input equals the result of evaluating that input alone. In particular, evaluating `(.dismissed, false)` and then `(.dismissed, true)` returns `.onboarding` then `.tabs`, and evaluating the same input twice returns the same screen.

**Validates: Requirements 2.6, 5.5, 5.6**

### Property 4: Launch arguments parse by exact match

For any list of arguments made from the known flags, near-miss strings (for example `-uiTestingResetOnboardingX`, `uiTestingSkipOnboarding`, different case) and unrelated strings, in any order, `skipOnboarding` is true exactly when `"-uiTestingSkipOnboarding"` is an element, `resetOnboarding` is true exactly when `"-uiTestingResetOnboarding"` is an element, and both are false for an empty list. The next element of the list is never read as a value.

**Validates: Requirements 9.1, 9.2, 9.5, 9.6, 10.2**

### Property 5: Onboarding flag action precedence

For any combination of `resetFavorites`, `skipOnboarding` and `resetOnboarding` (all 8), `onboardingFlagAction` is `.reset` when `resetOnboarding` is true, otherwise `.markSeen` when `skipOnboarding` or `resetFavorites` is true, otherwise `.none`.

**Validates: Requirements 9.1, 9.2, 9.3, 9.4, 9.5, 10.2**

### Property 6: Applying a flag action writes the right value

For any starting stored state (absent, true, false) and any `OnboardingFlagAction`, applying the action to a fresh `UserDefaults` suite leaves the flag true for `.markSeen`, absent for `.reset`, and unchanged for `.none`. Applying the same action a second time leaves the same state. The decision for the stored value (absent read as false) matches the table in Property 1.

**Validates: Requirements 2.4, 9.1, 9.2, 9.3, 9.5**

### Property 7: Button and indicator labels follow the page

For any page index `i` in `0..<M` and any page count `M >= 1`, `AppCopy.onboardingPrimaryLabel(isLast: i == M - 1)` is "Enter the market" when `i == M - 1` and "Next" otherwise, and `AppCopy.onboardingPageIndicator(page: i + 1, count: M)` equals "Page \(i + 1) of \(M)".

**Validates: Requirements 3.2, 3.3, 3.9, 6.1, 6.8, 7.4**

### Property 8: Page content shape

For any page in `OnboardingPage.all`, the title, eyebrow and message contain a non-whitespace character and the page has exactly three bullets, each with a non-whitespace character. The array has exactly three pages and their ids are pairwise distinct.

**Validates: Requirements 1.4, 5.7, 10.3**

### Property 9: Hero images exist

For any page in `OnboardingPage.all` with a non-nil `heroImage`, an image with that name resolves in the app bundle's asset catalog. Each of `dairy-products-pallete`, `map-image` and `pirate-ship` is used by exactly one page, and no other image name appears.

**Validates: Requirements 7.7, 10.12**

## Error Handling

- No new technical errors exist: onboarding does no I/O of its own. Market load failures still follow the existing path (`LoadFailureMessage`, logged by `MarketStore`/`MarketService`); nothing is added to `print` or user-visible text.
- Failure with no data keeps the splash (failure message and Retry) for both flag values, and onboarding is never shown on top of a failure (Property 2, requirements 4.5, 4.7).
- Failure with cached data while onboarding is shown: no message, no interruption; the offline banner appears on the tabs (requirement 4.4).
- Cancellation: unchanged. `store.load()` cancellation (for example when the root view goes away) restores the previous state, as today.
- Missing or corrupt flag: `UserDefaults` returns false for an absent key or a non-boolean value, so the user sees onboarding once more. This is the safe direction.
- Missing hero image at runtime: `Image(name)` would draw nothing. Property 9 catches this in tests, so no runtime fallback is added.
- A double tap on Skip or Next while the view is leaving is ignored by the `hasSeenOnboarding` guard, so the flag is written once and the hiss plays once.
- `-uiTestingResetOnboarding` combined with `-uiTestingSkipOnboarding` or `-uiTestingReset` removes the flag (precedence in Property 5). Test authors who want tabs must not pass it.

## Testing Strategy

### Approach

Property-based testing applies to the pure logic: `OnboardingDecision`, `LaunchOptions` parsing and precedence, the flag write, the label helpers and the page data. The domains here are small and finite (3 phases × 2 flags, 3 booleans, a few page indices), so each property is tested by exhaustive enumeration with Swift Testing parameterized `@Test(arguments:)` instead of random generation. That covers more than 100 random iterations would. The project allows no third-party dependencies and the workflow forbids writing a property-test library from scratch, so no generator library is added. Properties over open-ended inputs (Property 2 message strings, Property 4 argument lists) use a fixed list of edge values plus combinations built from the known flags; this is stated in each test's comment.

Each property test carries a comment: `// Feature: onboarding-flow, Property N: <title>`. Each property is one `@Test` (parameterized where the domain is enumerated).

UI rendering, the swipe gesture, VoiceOver order and Reduce Motion are not suited to property tests; they use XCTest UI tests and a manual checklist.

### Unit tests (Swift Testing, `NYCFarmerMarketsTests/`)

| File | Tests | Properties | Requirements |
|---|---|---|---|
| `OnboardingDecisionTests.swift` (new) | Table over `[.loading, .failed("x"), .dismissed] × [false, true]`; failed with varied messages; interleaved calls and same-input-twice | 1, 2, 3 | 1.1, 2.1, 2.6, 4.5, 4.7, 5.2 to 5.6, 10.1 |
| `LaunchOptionsTests.swift` (changed) | Neither argument gives both false; only skip; only reset; both gives `.reset`; near-miss strings do not match; 8-combination precedence table | 4, 5 | 9.1 to 9.6, 10.2 |
| `OnboardingFlagActionTests.swift` (new) | `.markSeen`, `.reset`, `.none` on a fresh `UserDefaults(suiteName:)` from absent, true and false; apply twice; decision for the stored value. The suite is removed in `defer`. | 6 | 2.4, 9.1 to 9.5 |
| `OnboardingPageTests.swift` (new) | Three pages; unique ids; non-blank eyebrow, title, message; three non-blank bullets each; every `heroImage` resolves via `UIImage(named:in:with:)` (or `NSImage` on macOS) with `Bundle(for: MarketStore.self)`; the three asset names are each used once | 8, 9 | 1.4, 5.7, 7.7, 10.3, 10.12 |
| `AppCopyTests.swift` (changed) | Labels "Skip", "Next", "Enter the market"; indicator text for N in 1...M; the new strings join `allVisibleStrings` | 7 | 3.2, 3.3, 3.9, 7.4 |
| `AppTypographyTests.swift` (changed) | New example test `splashRoleIsFortyFourPoints`: `AppTypography.Role.splash.size == 44` and `effectiveSize == 44`. Existing tests pass unchanged. | none (example) | 7.8, 10.13 |
| `NYCFarmerMarketsTests.swift` (existing `everyIconResolves`) | Covers the four new `AppIcon` cases without edits | none | 7.1 |

`Bundle(for: MarketStore.self)` is used instead of `Bundle.main` so the asset lookup targets the app bundle even if the tests are not hosted.

### UI tests (XCTest, `NYCFarmerMarketsUITests/OnboardingUITests.swift`, new)

The new class launches in each test (no `setUp` launch) with `["-uiTestingReset", "-uiTestingResetOnboarding", "-uiTestingMuteSounds"]`. It waits up to 30 seconds for data, like the existing suite (these tests use the live API or the cache).

| Test | Steps | Requirements |
|---|---|---|
| `testOnboardingShowsAfterSplashWithoutTabs` | `onboarding-screen` exists within 30 s; the Markets, Map and Favorites tab items do not exist | 1.1 to 1.3, 1.2, 10.4 |
| `testNextTwiceThenEnterTheMarket` | Tap `onboarding-next` twice; label is "Enter the market"; `onboarding-skip` is not hittable; tap `onboarding-next`; tab items exist within 30 s; `onboarding-screen` is gone | 3.1 to 3.4, 3.7, 10.5 |
| `testSkipLeavesOnboarding` | Tap `onboarding-skip` on page 1; tab items exist within 30 s; `onboarding-screen` is gone | 3.5, 3.6, 10.6 |
| `testOnboardingShowsOnlyOnce` | Finish with Skip; terminate; relaunch with `["-uiTestingMuteSounds"]`; tab items exist within 30 s and `onboarding-screen` never exists in that window | 2.2, 2.3, 2.5, 10.7 |
| `testSwipeMovesToSecondPage` | Swipe left on `onboarding-screen`; `onboarding-page-indicator` label is "Page 2 of 3" | 1.5, 3.9, 10.8 |

Existing UI tests keep their arguments (`-uiTestingReset`, `-uiTestingMuteSounds`) and identifiers. `-uiTestingReset` now also writes the flag, so they land on the tabs after the splash (requirements 9.3, 10.10). No change is needed in `NYCFarmerMarketsUITests.swift`; every launch there, including the relaunch in `testSoundToggleIsSaved`, already passes `-uiTestingMuteSounds` (requirement 10.9). The relaunch in that test passes no onboarding argument and the flag stays true from the first launch.

If the elements inside `onboarding-screen` do not remain individually addressable (for example `onboarding-next` hidden by `.contain`), the identifiers go on the elements themselves and the root keeps only `onboarding-screen`; the UI tests above reveal this.

### Manual checks (not automated)

- VoiceOver on a device or simulator: reading order eyebrow, title (heading), message, three bullets; Skip and Next announce their labels; Next works without swiping; the indicator reads the new page; no stop on hero, emoji or bullet icons (requirements 6.1, 6.2, 6.5 to 6.8).
- Dynamic Type from `xSmall` to `accessibility5` (use `xcrun simctl ui booted content_size`): text is not truncated and scrolls clear of Skip and the controls (requirement 6.3).
- Reduce Motion on: tapping Next shows the next page without a slide. If the paged `TabView` still animates, the fix is a `Transaction` with `disablesAnimations`; decide after the check (requirement 6.4).
- Sounds with sound on and VoiceOver off: hiss on Skip and Next, door once when the tabs appear (requirements 8.1 to 8.3). Tests run muted, so audio is not covered by automation (see `known-limits.md`).
- Convention check from `theme-conventions.md`: zero lines for `NYCFarmerMarkets/Onboarding/` (requirement 7.6).
- Splash failure message (`-uiTestingFailDownload`) at the default and the largest Dynamic Type sizes: the 44 pt text wraps and stays readable (requirement 7.8).
- Build iOS and macOS with the commands in `tech.md`; zero new warnings (requirement 10.11).

### What this design does not verify

visionOS at runtime, macOS visual layout, and the two-source-of-truth risk of `@AppStorage` observation across views (avoided by design, with one `@AppStorage` in `AppRootView`).
