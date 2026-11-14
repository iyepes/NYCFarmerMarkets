//
//  SoundController.swift
//  NYCFarmerMarkets
//

import Foundation
import Observation

/// Single entry point for interaction sounds. Views send cues here; the policy
/// decides whether they play (toggle on, VoiceOver off, not test-muted).
@Observable
final class SoundController {
    static let defaultsKey = "soundEnabled"

    private(set) var isEnabled: Bool
    private(set) var voiceOverOn = false
    private(set) var currentLoop: AppSound?

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let key: String
    @ObservationIgnored private let testMuted: Bool
    @ObservationIgnored private let player: any SoundPlaying

    init(
        defaults: UserDefaults = .standard,
        key: String = SoundController.defaultsKey,
        testMuted: Bool = false,
        player: any SoundPlaying
    ) {
        self.defaults = defaults
        self.key = key
        self.testMuted = testMuted
        self.player = player
        self.isEnabled = defaults.object(forKey: key) as? Bool ?? true
    }

    private var canPlay: Bool {
        SoundPolicy.shouldPlay(enabled: isEnabled, voiceOverOn: voiceOverOn, testMuted: testMuted)
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        defaults.set(enabled, forKey: key)
        if !enabled { silenceEverything() }
    }

    func setVoiceOverOn(_ on: Bool) {
        voiceOverOn = on
        if on { silenceEverything() }
    }

    func play(_ sound: AppSound) {
        guard canPlay else { return }
        player.play(sound)
    }

    func handle(_ activity: ScrollActivity, loop sound: AppSound) {
        guard canPlay else { return }
        switch SoundPolicy.loopAction(isLooping: currentLoop == sound, activity: activity) {
        case .start:
            if let previous = currentLoop { player.stop(previous) }
            player.startLoop(sound)
            currentLoop = sound
        case .stop:
            player.stopLoop(sound)
            currentLoop = nil
        case .none:
            break
        }
    }

    /// Fades out the current loop only. Never touches one-shot sounds.
    func stopAllLoops() {
        guard let loop = currentLoop else { return }
        player.stopLoop(loop)
        currentLoop = nil
    }

    private func silenceEverything() {
        player.stopAll()
        currentLoop = nil
    }
}
