## Plan for interaction sounds

Spec updated in place: `.kiro/specs/interaction-sounds/` (requirements.md, design.md, tasks.md) on branch `feature/14-interaction-sounds`.

### Key requirements
- Five owner recordings move to `NYCFarmerMarkets/Sounds/` with kebab-case names (`human-steps`, `cat-steps`, `door`, `door-and-hit`, `short-hiss`, all `.m4a`).
- Human steps loop while Markets scrolls, cat steps while Favorites scrolls. The loop fades out in about 0.3 s when scrolling stops, and only one loop plays at a time.
- Hiss on button presses. Door-and-hit when the detail sheet or single-market map opens. Door on first tab appearance and on tab change.
- Speaker toggle (`sound-toggle`) in the Markets toolbar, saved in UserDefaults `soundEnabled`, default on.
- All sounds are muted while VoiceOver runs. iOS and visionOS use the ambient audio session, so the silent switch applies and other apps' audio is not paused or ducked.

### Design
- `AppSound` registry in `Theme/` (the only place with file names), pure `SoundPolicy` in `Models/`, `SoundPlayer` (`AVAudioPlayer`) in `Services/`, `SoundController` store in `Stores/`.
- Views send cues to `SoundController`, which checks the policy (enabled, no VoiceOver, no test mute) before playing.
- Launch argument `-uiTestingMuteSounds` silences UI tests. `-uiTestingReset` also clears `soundEnabled`.
- Row, header, Close, favorite and swipe hisses play on tap. Themed capsule buttons hiss on press.

### Tasks
1. Move and rename sound files, add `AppSound` and its tests
2. `SoundPolicy` pure logic and tests
3. `LaunchOptions.muteSounds` and UI test launch arguments
4. `SoundPlayer`, `SoundController`, app wiring, tests, early `onScrollPhaseChange` check
5. VoiceOver wiring in `AppRootView`
6. Sound toggle in the Markets toolbar and its UI test
7. Hiss on button presses
8. Door sounds for tabs and detail views
9. Step loops while scrolling
10. Steering updates and full verification

Not verifiable in automated tests (to be listed in the PR): real audio, fades and loop seams, silent switch, VoiceOver on a device, visionOS and macOS audio.
