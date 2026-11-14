//
//  SoundPlayer.swift
//  NYCFarmerMarkets
//
//  Plays the bundled interaction sounds with AVAudioPlayer. Views never use
//  this directly; `SoundController` decides when a cue may play.
//

import AVFoundation
import OSLog

protocol SoundPlaying: AnyObject {
    func play(_ sound: AppSound)
    func startLoop(_ sound: AppSound)
    /// Fades the sound out (about 0.3 s), then stops it.
    func stopLoop(_ sound: AppSound)
    /// Stops one sound immediately.
    func stop(_ sound: AppSound)
    /// Stops every sound immediately.
    func stopAll()
}

final class SoundPlayer: SoundPlaying {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "NYCFarmerMarkets", category: "sound"
    )
    private static let fadeDuration: TimeInterval = 0.3

    private var players: [AppSound: AVAudioPlayer] = [:]
    private var fadeTasks: [AppSound: Task<Void, Never>] = [:]

    /// Loading the files and activating the audio session took about 275 ms in a Debug build on
    /// the simulator, so it runs shortly after launch instead of blocking the first frame.
    /// Cues that arrive before it finishes are ignored.
    init() {
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            self?.prepare()
        }
    }

    private func prepare() {
        #if os(iOS) || os(visionOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient)
            try session.setActive(true)
        } catch {
            Self.logger.error("Audio session setup failed: \(error.localizedDescription, privacy: .private)")
        }
        #endif

        for sound in AppSound.allCases {
            guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: sound.fileExtension) else {
                Self.logger.error("Sound file missing: \(sound.fileName, privacy: .public)")
                continue
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = sound.loops ? -1 : 0
                player.prepareToPlay()
                players[sound] = player
            } catch {
                Self.logger.error(
                    "Sound file unreadable: \(sound.fileName, privacy: .public), \(error.localizedDescription, privacy: .private)"
                )
            }
        }
    }

    func play(_ sound: AppSound) {
        guard let player = players[sound] else { return }
        cancelFade(sound)
        player.currentTime = 0
        player.setVolume(1, fadeDuration: 0)
        player.play()
    }

    func startLoop(_ sound: AppSound) {
        guard let player = players[sound] else { return }
        cancelFade(sound)
        player.setVolume(1, fadeDuration: 0)
        if !player.isPlaying { player.play() }
    }

    func stopLoop(_ sound: AppSound) {
        guard let player = players[sound], player.isPlaying else { return }
        cancelFade(sound)
        player.setVolume(0, fadeDuration: Self.fadeDuration)
        fadeTasks[sound] = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled, let self else { return }
            self.fadeTasks[sound] = nil
            self.reset(sound)
        }
    }

    func stop(_ sound: AppSound) {
        cancelFade(sound)
        reset(sound)
    }

    func stopAll() {
        for sound in AppSound.allCases { stop(sound) }
    }

    private func cancelFade(_ sound: AppSound) {
        fadeTasks[sound]?.cancel()
        fadeTasks[sound] = nil
    }

    private func reset(_ sound: AppSound) {
        guard let player = players[sound] else { return }
        player.stop()
        player.currentTime = 0
        player.setVolume(1, fadeDuration: 0)
    }
}

/// Used by UI tests (`-uiTestingMuteSounds`): no audio session, no files loaded.
final class SilentSoundPlayer: SoundPlaying {
    func play(_ sound: AppSound) {}
    func startLoop(_ sound: AppSound) {}
    func stopLoop(_ sound: AppSound) {}
    func stop(_ sound: AppSound) {}
    func stopAll() {}
}
