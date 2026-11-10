## Plan recorded

Spec: `.kiro/specs/custom-fonts-integration/` (requirements.md, design.md, tasks.md) on branch `feature/7-custom-fonts-integration`.

### Key requirements
- Fonts ship in the app bundle and resolve by their real PostScript names on iOS and macOS (`Grim-Creeper-Regular`, `N8ghtmare`). `DrCaligari.ttf` stays tracked and bundled, unused in the UI.
- Grim Creeper on the splash, tab titles, detail title and Favorites item titles. N8ghtmare on all other text.
- One typography type in `Theme/`; no font names or `.custom(` in views. Dynamic Type keeps working, with a system-font fallback.
- Font license metadata is reported in the PR. Colors, icons, copy and accessibility labels do not change.
- Owner decision: macOS tab and navigation titles stay in the system font (listed as a deviation in the PR).

### Design approach
- New `nonisolated enum AppTypography` (families, 13 semantic roles, `appFont(_:)` modifier) with CoreText runtime registration, which works the same on every platform. `UIAppFonts` stays.
- Pure `resolvedFont(for:isAvailable:)` so the fallback and role-to-family mapping are unit tested.
- iOS tab bar, navigation bar and search field are styled in `ThemeAppearance` (minimal `UINavigationBarAppearance`, re-applied on content size changes), with screenshot checks and a SwiftUI `.principal` fallback.
- Convention gate gets three new grep patterns.

### Tasks
- [ ] 1. Baseline and bundle layout check
- [ ] 2. Create `AppTypography` with pure logic and unit tests
- [ ] 3. Register fonts at launch and set the root font
- [ ] 4. Apply roles in the views
- [ ] 5. Style system-rendered bars (iOS only)
- [ ] 6. Extend the convention gate
- [ ] 7. Licensing report
- [ ] 8. Full verification and visual evidence
- [ ] 9. Specs and PR notes
