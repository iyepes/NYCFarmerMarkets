feat: add interaction sounds (footsteps, hiss, doors) with a sound toggle

## Description

Add interaction sounds to Spooky Markets using five recordings made by the owner (published in the public repo). Full requirements, design and tasks are in `.kiro/specs/interaction-sounds/`.

- Looping footsteps while scrolling: human steps in the Markets list, cat steps in Favorites.
- A short hiss when a button is pressed.
- A sliding door with a hit when the market detail sheet or the single-market map opens.
- A sliding door when the tabs first appear and on every tab change.
- A sound on/off toggle (speaker icon) in the Markets toolbar, saved in UserDefaults (`soundEnabled`, default on).
- Silent while VoiceOver is running.
- Ambient audio session on iOS/visionOS: respects the silent switch, mixes with other apps' audio.

The recordings move from `Sounds/` to `NYCFarmerMarkets/Sounds/` with kebab-case names: `human-steps.m4a`, `cat-steps.m4a`, `door.m4a`, `door-and-hit.m4a`, `short-hiss.m4a`. Only Apple frameworks (AVFoundation, SwiftUI); no `project.pbxproj` edits.

## Acceptance criteria

- [ ] The five sound files are tracked under `NYCFarmerMarkets/Sounds/` with the kebab-case names, the originals under `Sounds/` are gone, and the files are in the iOS and macOS app bundles.
- [ ] One `AppSound` registry in `Theme/` holds all sound file names; no code outside `Theme/` contains a file name.
- [ ] Markets list scrolling (including coasting) loops human steps; Favorites scrolling loops cat steps; the loop fades out (~0.3 s) when scrolling stops, and stops when leaving the screen. At most one loop plays at a time.
- [ ] Pressing a button (themed buttons, list rows, section headers, Close, favorite toggle, swipe-to-remove, sound toggle when turning sound on) plays the hiss once per press, restarting if retriggered.
- [ ] Opening the detail sheet (from any tab) or the single-market map plays door-and-hit once; closing or going back plays no door sound.
- [ ] The door plays once when the tabs first appear and on each tab change, but not when reselecting the current tab.
- [ ] The Markets toolbar has a sound toggle (`sound-toggle`, label "Sounds", value "On"/"Off") that persists in `soundEnabled`, defaults to on, and stops playing sounds when turned off.
- [ ] No sound plays while VoiceOver runs; sounds resume when it stops if the toggle is on.
- [ ] iOS/visionOS use the ambient audio session and never pause or duck other apps' audio.
- [ ] A missing or unloadable sound file is logged once with `Logger` and the app continues silently.
- [ ] Unit tests (Swift Testing) cover bundle presence, play decisions (enabled / VoiceOver / test mute), step-loop decisions, and the store with a fake player and temporary UserDefaults.
- [ ] Launch argument `-uiTestingMuteSounds` silences all sounds, every UI test passes it, and a UI test checks that the toggle value changes and survives relaunch.
- [ ] Existing unit and UI tests pass, iOS and macOS builds succeed, and the convention checks in `.kiro/steering/theme-conventions.md` print zero lines.
- [ ] The PR states what was not verified (hand listening checks, visionOS and macOS audio).

## Out of scope

Volume or per-sound settings, new or trimmed recordings, haptics changes, sounds for map pan/zoom, pin taps, search typing or pull-to-refresh, localization of the toggle label.
