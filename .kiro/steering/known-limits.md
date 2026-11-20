---
inclusion: manual
---

# Known limitations and open points

Reference this file with `#known-limits` when working on typography, theming or a release.

## Accepted (owner decisions)

- macOS tab and navigation titles stay in the system font.
- Market names in the Markets list use the body font; only Favorites item titles use the display font.
- Onboarding hero (#23, 2026-11-14): 190 pt, emoji on the left, about 40 pt higher than before but below Skip, not beside it. The page `ScrollView` adds the top safe area on top of `OnboardingHeroLayout`'s inset; the owner kept this position.

## Known bugs

- Map tab: the tab-bar labels render in the system font, not Grim Creeper. Two fixes failed and were removed (a second font on `UITabBarItem` appearance; `.toolbarBackground(.visible, for: .tabBar)` on the Map). Cause not confirmed. Do not retry those two.

## Not verified

- visionOS at runtime; macOS visually.
- Sounds: audio on macOS and visionOS; the device silent switch; mixing with other apps' audio; VoiceOver on a device; the real fade and the loop seams (`cat-steps` 1.37 s, `human-steps` 6.74 s; trimming is the owner's task). Tests run muted, so only the logic is covered.
- `SoundPlayer` loads files and the audio session about 300 ms after launch (about 545 ms in a Debug build on the simulator); cues before that are ignored.
- Black Chancery on screen (owner review, spec `body-font-black-chancery-fix` task 5): the inherited body `sizeScale` 1.15 and 14 pt floor (tuned for earlier fonts); x-height and legibility at small sizes; glyph coverage for digits and punctuation used in addresses; Dynamic Type at the largest sizes. Black Chancery has no "·" (rows use ", ").
- Borough headers (30 pt text and chevron) at `.xxxLarge`; `sectionHeader` scales with `.subheadline`.
- Onboarding on a device: VoiceOver reading order and labels, changing pages by swiping up/down on the page dots (XCUITest cannot drive the adjustable action; only `OnboardingPagingTests` cover it), Skip being skipped on the last page, and Reduce Motion paging.
- Onboarding hero jump: `skipSize` starts at a default and is re-measured with `onGeometryChange`, so at large text sizes the hero inset may change after the first frame. Not checked on screen.

## Licensing

License notices live in the root `fonts-licensing/` folder (not bundled into the app).

- Black Chancery (`BLKCHCRY.TTF`): public domain; the embedded copyright says so. Notice: `fonts-licensing/BLACKCHA.txt`.
- Grim Creeper: free for personal and commercial use. The author asks that the read me be included wherever the font is offered for download; it is `fonts-licensing/Grim Creeper Font Info and Read Me - Sinister Fonts.txt`.

## Loose ends

- `Design/AppIcon.svg` no longer matches the app icon PNGs (gradient icon).
- Simplify `OnboardingHeroLayout` (follow-up from #23 / PR #24): its shape-aware "beside Skip" branch no longer matches the real layout because of the doubled top safe area. Either replace it with a fixed inset below Skip (same result as today, less code and tests) or remove the doubled safe area and re-check the hero beside Skip with screenshots.
- Done (2026-11-20): the workflow's convention gate font-name pattern and the steering check both use `grep -rniE 'Grim|Chancery|BLKCHCRY|\.ttf'`.
- Merged branches (`feature/1-…`, `3-…`, `5-…`, `7-…`, `chore/archive-run-traces`, `fix/archive-review-fixes`, `docs/fonts-spec-amendment-2`) still exist locally and on the remote.
