Play the Ay sound when a market is removed from favorites

## Description

The app already plays spooky sound cues (see the `interaction-sounds` spec). Removing a market from favorites currently plays the hiss. This issue replaces that sound with the owner's recording `Ay` (`NYCFarmerMarkets/Sounds/ay.m4a`, 1.0 s, stereo AAC), so removing a favorite is recognizable by ear.

## Behavior

- Ay replaces the hiss on every removal path, so exactly one sound plays per removal:
  - the swipe "Remove" action in `FavoritesView`,
  - the "Remove from favorites" accessibility action in `FavoritesView`,
  - the favorite toggle in `MarketDetailToolbar` when it turns a favorite off.
- Adding a favorite with the toggle keeps the hiss.
- Sounds stay muted while VoiceOver runs (unchanged). Ay is therefore silent under VoiceOver, but can still play when the accessibility action is triggered by Switch Control or Voice Control.
- No other behavior changes.

## Implementation notes

- Add an `ay` case to the `AppSound` registry in `Theme/` (file name `ay`), cover it in `AppSoundTests` (bundled, not a loop).
- Play it through `SoundController` like the other cues.
- Update `.kiro/steering/theme-conventions.md` if it lists the sounds.
- Add a dated "Amendment: Ay on favorite removal" to the existing `.kiro/specs/interaction-sounds/` spec (requirements, design, tasks).

## Acceptance criteria

- [ ] `AppSound` has an `ay` case that resolves to the bundled `ay.m4a` and is not a loop.
- [ ] `AppSoundTests` covers `ay` (file is bundled, not a loop).
- [ ] Swipe "Remove" in `FavoritesView` plays Ay and not the hiss.
- [ ] The "Remove from favorites" accessibility action in `FavoritesView` plays Ay and not the hiss.
- [ ] Turning a favorite off with the `MarketDetailToolbar` toggle plays Ay and not the hiss.
- [ ] Turning a favorite on with the toggle still plays the hiss.
- [ ] Exactly one sound plays per removal.
- [ ] Sounds remain muted while VoiceOver runs, and when sound is off in settings.
- [ ] `theme-conventions.md` lists the new sound if it lists the others.
- [ ] The `interaction-sounds` spec has a dated "Amendment: Ay on favorite removal" in requirements, design and tasks.
- [ ] iOS and macOS builds succeed and unit tests pass.

## Slug

`ay-sound-on-favorite-removal`
