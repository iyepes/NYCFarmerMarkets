# Requirements: Interaction sounds (issue #14)

Branch: `feature/14-interaction-sounds`. Basis: the approved spec `.kiro/specs/interaction-sounds/requirements.md`, which the record_spec step updates in place (no new spec folder).

## Summary

Add interaction sounds to Spooky Markets using five recordings made by the owner. Footsteps loop while the Markets list (human) and the Favorites list (cat) scroll. A short hiss plays on button presses. A door-and-hit plays when the detail sheet or the single-market map opens. A door plays when the tabs first appear and on tab change. A speaker toggle in the Markets toolbar turns sounds on and off. Sounds are muted while VoiceOver runs. Only Apple frameworks (AVFoundation, SwiftUI) are used.

## Assumptions

1. The recordings are the owner's and may be public.
2. "Button" means any tappable action control: themed buttons (Retry, More info, Go to Map, Directions), Markets and Favorites rows, borough section headers, Close, the favorite toggle, swipe-to-remove, and the sound toggle. Tab bar items are not buttons; they get the door.
3. When a button opens a view, the hiss plays on press and the door-and-hit plays as the view opens (owner answer).
4. Closing the sheet, going back from the map, and swipe-down dismissal play no door sound. Only a pressed button's hiss plays.
5. The door plays on first tab appearance and on every tab change (owner answer).
6. VoiceOver mutes all sounds regardless of the toggle (owner answer).
7. Files are used as recorded. Any gap in a loop from silence in the recording is the owner's to trim.
8. "Scrolling" means user-driven movement (drag plus coasting). Programmatic changes such as expanding sections are not scrolling.

## Functional Requirements

### R1. Bundled sound files
1. The files are tracked at `NYCFarmerMarkets/Sounds/` as `human-steps.m4a`, `cat-steps.m4a`, `door.m4a`, `door-and-hit.m4a`, `short-hiss.m4a`. The originals under `Sounds/` are removed (moved).
2. The files are in the built iOS and macOS bundles, with no `project.pbxproj` edit.
3. One `AppSound` registry in `Theme/` holds all file names. No code outside `Theme/` contains a sound file name.

### R2. Step loops while scrolling
1. When the Markets list starts scrolling, human steps start looping. When Favorites starts scrolling, cat steps start looping.
2. While scrolling continues, including coasting, the loop keeps playing without restarting.
3. When scrolling stops, the loop fades out in about 0.3 s.
4. When the user leaves the screen while scrolling (tab change, sheet opens, app backgrounds), the loop stops.
5. At most one loop plays at a time.

### R3. Hiss on button presses
1. Each press of a button (Assumption 2) plays the hiss once.
2. Turning sounds on with the toggle plays the hiss. Turning sounds off plays nothing.
3. A hiss triggered while a hiss is playing restarts it and does not stack.

### R4. Door and hit on detail views
1. Opening the detail sheet from any tab (Markets row, Favorites row, Map "More info") plays door-and-hit once.
2. Pushing the single-market map from the sheet plays door-and-hit once.
3. Going back from the map to the sheet does not replay it. Closing or going back plays no door sound.

### R5. Door on tabs
1. The door plays once when the tabs first appear after the splash.
2. The door plays once on each switch to a different tab.
3. Reselecting the shown tab plays nothing.
4. A door triggered while a door is playing restarts it and does not stack.

### R6. Sound toggle
1. The Markets toolbar shows a speaker button (`AppIcon.soundOn` or `AppIcon.soundOff`) with identifier `sound-toggle`, label "Sounds", value "On" or "Off".
2. Pressing it flips the setting and saves it in UserDefaults key `soundEnabled`. The default is on.
3. Turning sounds off stops any playing sound and blocks new ones.

### R7. VoiceOver
1. No sound plays while VoiceOver runs, whatever the toggle says.
2. When VoiceOver starts, any playing sound stops. When it stops, sounds resume if the toggle is on, with no relaunch.
3. The toggle stays usable with VoiceOver and its choice is saved.

### R8. System audio behavior
1. On iOS and visionOS the app uses the ambient audio session: the silent switch silences it and other apps' audio mixes.
2. The app never pauses or ducks other apps' audio.
3. On macOS sounds play at system volume with no session setup.
4. If a file cannot be loaded, the failure is logged once with `Logger` (explicit privacy, no `print`) and the app continues silently with no user message. A playback failure continues silently without logging.

## Non-Functional Requirements

1. No third-party dependencies. Follow steering: pure logic `nonisolated` in `Models/`, stores in `Stores/`, services in `Services/`, registries in `Theme/`, icons only via `AppIcon`, colors only via `AppPalette`.
2. Sounds are preloaded so a press plays without noticeable delay. App start is not noticeably slower.
3. The UI test suite produces no sound.
4. New test hook follows `LaunchOptions` conventions: inert unless passed, no build-time switch.

## Acceptance Criteria

1. The five files exist under `NYCFarmerMarkets/Sounds/` with the names above, `Sounds/` originals are gone, and the files are in the iOS and macOS app bundles. (R1)
2. `grep` finds no `.m4a` sound file name outside `NYCFarmerMarkets/Theme/`. (R1.3)
3. Scrolling the Markets list loops human steps and scrolling Favorites loops cat steps. The loop continues through coasting without restarting. (R2.1, R2.2)
4. Stopping the scroll fades the loop out over about 0.3 s. Leaving the screen stops it. Never two loops at once. (R2.3 to R2.5)
5. Each listed button press plays one hiss. A second press during playback restarts it. (R3)
6. Opening the sheet from each of the three entry points, and pushing the map, plays door-and-hit once. Closing or going back plays no door sound. (R4)
7. The door plays on first tab appearance and on a tab change, and not on reselecting the current tab. (R5)
8. The `sound-toggle` exists in the Markets toolbar with the label, value and identifier above. Its value changes on press and survives a relaunch. Default is on. (R6)
9. With the toggle off, no sound plays and playing sounds stop. (R6.3)
10. With VoiceOver on, no sound plays. When VoiceOver turns off, sounds resume if the toggle is on. (R7)
11. iOS and visionOS use the ambient session. Other apps' audio is not paused or ducked. (R8.1, R8.2)
12. A missing file is logged once and the app does not crash or show a message. (R8.4)
13. Swift Testing unit tests cover: every `AppSound` file in the bundle; the play decision for every combination of enabled, VoiceOver and test mute; step-loop decisions for scroll event sequences (start, repeated start, stop, leave while scrolling); the store with a fake player and temporary UserDefaults (default on, saved, blocks when off, stops loops when turned off).
14. The launch argument `-uiTestingMuteSounds` silences all sounds. Every UI test passes it. A UI test checks the toggle value change and relaunch persistence.
15. Existing unit and UI tests pass. iOS and macOS builds succeed. The convention checks in `.kiro/steering/theme-conventions.md` print zero lines.
16. The PR lists what was not verified: hand listening checks, visionOS and macOS audio.

## Out of Scope

- Volume or per-sound settings.
- New, trimmed or normalized recordings.
- Haptics changes (the favorite toggle keeps `sensoryFeedback`).
- Sounds for map pan and zoom, pin taps, search typing, or pull-to-refresh beyond the step loop.
- Localization of the toggle label.
