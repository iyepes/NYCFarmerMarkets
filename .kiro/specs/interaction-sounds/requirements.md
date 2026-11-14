# Requirements Document

## Introduction

This feature adds interaction sounds to the NYC Farmer Markets app ("Spooky Markets"), using five sounds recorded by the owner. Footsteps loop while the user scrolls the Markets list (human steps) and the Favorites list (cat steps). A short hiss plays when a button is pressed. A sliding door that hits plays when the market detail sheet or the single-market map opens, and a sliding door plays when a tab appears. The user can turn sounds off in the app, and sounds are silent while VoiceOver runs. Sounds follow the device's silent switch and mix with other audio. The recordings are in `Sounds/` at the repository root and move to `NYCFarmerMarkets/Sounds/` with kebab-case names.

## Glossary

- **App**: The NYC Farmer Markets application.
- **Sound_Files**: The five owner-recorded files, after the move: `NYCFarmerMarkets/Sounds/human-steps.m4a` (6.7 s), `cat-steps.m4a` (1.4 s), `door.m4a` (2.9 s), `door-and-hit.m4a` (2.9 s), `short-hiss.m4a` (1.0 s). Originals: `Sounds/Human steps.m4a`, `Sounds/Cat steps.m4a`, `Sounds/Door.m4a`, `Sounds/Door and hit.m4a`, `Sounds/Short hiss.m4a`.
- **App_Sound**: The single registry type in `NYCFarmerMarkets/Theme/` that names each sound and its file. The only place sound file names may appear.
- **Sound_Controller**: The store that decides whether a sound may play and asks the player to play it.
- **Sound_Player**: The component that loads and plays Sound_Files.
- **Step_Loop**: A sound that repeats while a list scrolls: Human_Steps for the Markets list, Cat_Steps for the Favorites list.
- **Hiss**: `short-hiss.m4a`, played on a button press.
- **Door**: `door.m4a`, played when a tab appears.
- **Door_And_Hit**: `door-and-hit.m4a`, played when the Detail_Sheet or the Single_Market_Map opens.
- **Sound_Toggle**: The speaker button in the Markets_Tab toolbar that turns sounds on and off.
- **Sounds_Enabled**: The user's saved on/off choice (UserDefaults key `soundEnabled`), default on.
- **Scrolling**: The list moves because of the user, either while the finger drags it or while it coasts after release. Programmatic changes (rows added or removed, sections expanding) are not Scrolling.
- **Splash_Screen**, **Markets_Tab**, **Map_Tab**, **Favorites_Tab**, **Detail_Sheet**: As in `.kiro/specs/nyc-farmer-markets/requirements.md`.
- **Single_Market_Map**: The in-app map pushed from the Detail_Sheet by "Go to Map" (`MarketLocationMapView`).

## Assumptions

1. The owner recorded the Sound_Files and they may be published in the public repository.
2. "Button" means any tappable control that performs an action: themed buttons (Retry, More info, Go to Map, Directions), market rows in the Markets and Favorites lists, borough section headers, the Close button, the favorite toggle, the swipe-to-remove action and the Sound_Toggle. Tab bar items are not buttons for this feature; they get the Door.
3. When a button opens a view, both sounds play: the Hiss on press, then the Door_And_Hit as the view opens (owner answer).
4. Closing the Detail_Sheet or going back from the Single_Market_Map plays no door sound; only the Hiss of the pressed button, if a button was pressed.
5. Swipe-down dismissal of the Detail_Sheet presses no button, so it is silent.
6. The Door plays once when the tabs first appear after the Splash_Screen, and on every tab change by the user (owner answer).
7. Sounds are muted while VoiceOver runs, regardless of Sounds_Enabled (owner answer).
8. The Sound_Files are used as recorded. If a Step_Loop has silence at its start or end, the loop has a gap; trimming is the owner's task.

## Requirements

### Requirement 1: Sound files are bundled
**User Story:** As the owner of the App, I want my recordings to ship inside the App, so that they play on a real install.

#### Acceptance Criteria
1. THE Sound_Files SHALL be tracked in git under `NYCFarmerMarkets/Sounds/` with the kebab-case names in the Glossary, and the original files under `Sounds/` SHALL no longer exist.
2. THE Sound_Files SHALL be present in the built iOS and macOS app bundles.
3. THE App_Sound registry SHALL define one case per Sound_File with its file name, and no code outside `Theme/` SHALL contain a sound file name.
4. THE file move SHALL need no `project.pbxproj` edits (synchronized groups).

### Requirement 2: Step loops while scrolling
**User Story:** As a user, I want to hear footsteps while I scroll, so that browsing feels like walking through the market.

#### Acceptance Criteria
1. WHEN the Markets_Tab list starts Scrolling, THE App SHALL start Human_Steps looping.
2. WHEN the Favorites_Tab list starts Scrolling, THE App SHALL start Cat_Steps looping.
3. WHILE the list keeps Scrolling, including while it coasts after the finger lifts, THE Step_Loop SHALL keep playing without restarting from the beginning.
4. WHEN the list stops Scrolling, THE App SHALL stop the Step_Loop with a short fade-out (about 0.3 s).
5. WHEN the user leaves the screen while it is Scrolling (tab change, Detail_Sheet opens, App goes to the background), THE App SHALL stop its Step_Loop.
6. THE App SHALL play at most one Step_Loop at a time.

### Requirement 3: Hiss on button presses
**User Story:** As a user, I want a hiss when I press a button, so that my taps feel spooky.

#### Acceptance Criteria
1. WHEN the user presses a button listed in Assumption 2, THE App SHALL play the Hiss once per press.
2. WHEN the user presses the Sound_Toggle to turn sounds on, THE App SHALL play the Hiss; WHEN the user turns sounds off, THE App SHALL play nothing.
3. WHEN the Hiss is triggered again before the previous Hiss ends, THE App SHALL restart it instead of stacking copies.

### Requirement 4: Door and hit when a detail view opens
**User Story:** As a user, I want a door to slide and hit when a market's details open, so that opening feels like entering a room.

#### Acceptance Criteria
1. WHEN the Detail_Sheet opens from any tab (Markets row, Favorites row, Map "More info"), THE App SHALL play the Door_And_Hit once.
2. WHEN the Single_Market_Map is pushed from the Detail_Sheet, THE App SHALL play the Door_And_Hit once.
3. WHEN a button opens one of these views, THE App SHALL play the Hiss on press and then the Door_And_Hit as the view opens.
4. WHEN the user goes back from the Single_Market_Map to the Detail_Sheet, THE App SHALL NOT play the Door_And_Hit again.
5. WHEN the Detail_Sheet closes or the user goes back from the Single_Market_Map, THE App SHALL NOT play a door sound.

### Requirement 5: Door when a tab appears
**User Story:** As a user, I want a sliding door when I change rooms (tabs), so that each tab feels like a new room.

#### Acceptance Criteria
1. WHEN the tabs first appear after the Splash_Screen, THE App SHALL play the Door once.
2. WHEN the user switches to a different tab, THE App SHALL play the Door once.
3. WHEN the user selects the tab that is already shown, THE App SHALL NOT play the Door.
4. WHEN the Door is triggered again before the previous Door ends, THE App SHALL restart it instead of stacking copies.

### Requirement 6: Sound toggle
**User Story:** As a user, I want to turn the sounds off, so that I can use the App quietly.

#### Acceptance Criteria
1. THE Markets_Tab toolbar SHALL show the Sound_Toggle with a speaker icon (`AppIcon.soundOn` when on, `AppIcon.soundOff` when off).
2. WHEN the user presses the Sound_Toggle, THE App SHALL flip Sounds_Enabled and save it in UserDefaults key `soundEnabled`.
3. WHEN the App starts, THE App SHALL read Sounds_Enabled; IF no value is saved, THEN sounds SHALL be on.
4. WHEN Sounds_Enabled turns off, THE App SHALL stop any playing sound and play no new sound.
5. THE Sound_Toggle SHALL have the accessibility label "Sounds", the value "On" or "Off", and the identifier `sound-toggle`.

### Requirement 7: Silent while VoiceOver runs
**User Story:** As a VoiceOver user, I want no sound effects over speech, so that I can hear VoiceOver clearly.

#### Acceptance Criteria
1. WHILE VoiceOver is running, THE App SHALL play no sound, regardless of Sounds_Enabled.
2. WHEN VoiceOver starts while a sound plays, THE App SHALL stop it.
3. WHEN VoiceOver stops, THE App SHALL play sounds again if Sounds_Enabled is on, without restarting the App.
4. THE Sound_Toggle SHALL stay usable with VoiceOver and SHALL save the choice for when VoiceOver is off.

### Requirement 8: Audio behavior with the system
**User Story:** As a user, I want the sounds to respect my device, so that they never interrupt my music or ignore my silent switch.

#### Acceptance Criteria
1. ON iOS and visionOS, THE App SHALL use the ambient audio session category, so that sounds are silenced by the silent switch and mix with audio from other apps.
2. THE App SHALL NOT pause or duck audio from other apps.
3. ON macOS, THE App SHALL play sounds at the system volume with no session setup.
4. IF a Sound_File cannot be loaded, THEN THE App SHALL log the failure with `Logger` once and continue silently, with no crash and no message to the user. IF playback fails, THEN THE App SHALL continue silently without logging.

### Requirement 9: Tests and verification
**User Story:** As the owner of the App, I want automated checks, so that the sound rules do not regress and test runs stay quiet.

#### Acceptance Criteria
1. THE unit tests (Swift Testing) SHALL verify that every App_Sound file is in the app bundle.
2. THE unit tests SHALL verify the play decision for every combination of Sounds_Enabled, VoiceOver and the test mute.
3. THE unit tests SHALL verify the Step_Loop decisions for sequences of scroll events (start, repeated start, stop, leaving the screen while scrolling).
4. THE unit tests SHALL verify, with a fake player and a temporary UserDefaults, that Sounds_Enabled defaults to on, is saved, blocks playback when off, and stops loops when turned off.
5. THE App SHALL accept the launch argument `-uiTestingMuteSounds`, which silences all sounds; every UI test SHALL pass it.
6. A UI test SHALL verify that the Sound_Toggle value changes and survives a relaunch.
7. THE existing unit and UI tests SHALL pass, and the iOS and macOS builds SHALL succeed.
8. THE convention checks in `.kiro/steering/theme-conventions.md` SHALL print zero lines.
9. THE pull request SHALL state what was not verified, expected to include the listening checks done by hand, visionOS and macOS audio.

## Non-Functional Requirements

1. THE feature SHALL use only Apple frameworks (AVFoundation, SwiftUI); no third-party dependencies.
2. THE feature SHALL follow the steering conventions: pure logic `nonisolated` in `Models/`, stores in `Stores/`, services in `Services/`, registries in `Theme/`, icons only through `AppIcon`, no `project.pbxproj` edits.
3. Sounds SHALL be preloaded so that a press plays without a noticeable delay, and loading SHALL NOT noticeably slow down app start.
4. Running the UI test suite SHALL produce no sound.
5. Specs for this feature live in `.kiro/specs/interaction-sounds/` as `requirements.md`, `design.md` and `tasks.md`.

## Out of Scope

- A volume setting or per-sound settings.
- New or edited recordings (trimming, normalizing).
- Changes to haptics (the favorite toggle keeps its `sensoryFeedback`).
- Sounds for the Map tab's pan and zoom, pin taps, search typing or pull-to-refresh beyond the Step_Loop.
- Localization of the toggle label.
