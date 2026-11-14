//
//  SoundControllerTests.swift
//  NYCFarmerMarketsTests
//
import Testing
import Foundation
@testable import NYCFarmerMarkets

private enum Call: Equatable {
    case play(AppSound)
    case startLoop(AppSound)
    case stopLoop(AppSound)
    case stop(AppSound)
    case stopAll
}

private final class FakeSoundPlayer: SoundPlaying {
    var calls: [Call] = []
    func play(_ sound: AppSound) { calls.append(.play(sound)) }
    func startLoop(_ sound: AppSound) { calls.append(.startLoop(sound)) }
    func stopLoop(_ sound: AppSound) { calls.append(.stopLoop(sound)) }
    func stop(_ sound: AppSound) { calls.append(.stop(sound)) }
    func stopAll() { calls.append(.stopAll) }
}

struct SoundControllerTests {
    private let suiteName = "SoundControllerTests-\(UUID().uuidString)"

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: suiteName)!
    }

    private func cleanUp() {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    private func makeController(
        defaults: UserDefaults, muted: Bool = false, player: FakeSoundPlayer
    ) -> SoundController {
        SoundController(defaults: defaults, testMuted: muted, player: player)
    }

    @Test func defaultsToEnabled() {
        defer { cleanUp() }
        let controller = makeController(defaults: makeDefaults(), player: FakeSoundPlayer())
        #expect(controller.isEnabled == true)
    }

    @Test func setEnabledIsSavedAndReloaded() {
        defer { cleanUp() }
        let defaults = makeDefaults()
        makeController(defaults: defaults, player: FakeSoundPlayer()).setEnabled(false)
        #expect(makeController(defaults: defaults, player: FakeSoundPlayer()).isEnabled == false)
    }

    @Test func nonBooleanStoredValueGivesEnabled() {
        defer { cleanUp() }
        let defaults = makeDefaults()
        defaults.set("nope", forKey: SoundController.defaultsKey)
        #expect(makeController(defaults: defaults, player: FakeSoundPlayer()).isEnabled == true)
    }

    @Test func playIsForwardedOnlyWhenAllowed() {
        defer { cleanUp() }
        let player = FakeSoundPlayer()
        let controller = makeController(defaults: makeDefaults(), player: player)
        controller.play(.hiss)
        #expect(player.calls == [.play(.hiss)])

        controller.setVoiceOverOn(true)
        controller.play(.door)
        controller.setVoiceOverOn(false)
        controller.setEnabled(false)
        controller.play(.door)
        #expect(!player.calls.contains(.play(.door)))
    }

    @Test func disablingStopsEverything() {
        defer { cleanUp() }
        let player = FakeSoundPlayer()
        let controller = makeController(defaults: makeDefaults(), player: player)
        controller.handle(.scrolling, loop: .humanSteps)
        controller.setEnabled(false)
        #expect(player.calls.last == .stopAll)
        #expect(controller.currentLoop == nil)
    }

    @Test func voiceOverOnStopsEverything() {
        defer { cleanUp() }
        let player = FakeSoundPlayer()
        let controller = makeController(defaults: makeDefaults(), player: player)
        controller.handle(.scrolling, loop: .catSteps)
        controller.setVoiceOverOn(true)
        #expect(player.calls.last == .stopAll)
        #expect(controller.currentLoop == nil)
    }

    @Test func secondLoopHardStopsTheFirstBeforeStarting() {
        defer { cleanUp() }
        let player = FakeSoundPlayer()
        let controller = makeController(defaults: makeDefaults(), player: player)
        controller.handle(.scrolling, loop: .humanSteps)
        controller.handle(.scrolling, loop: .catSteps)
        #expect(player.calls == [.startLoop(.humanSteps), .stop(.humanSteps), .startLoop(.catSteps)])
        #expect(controller.currentLoop == .catSteps)
    }

    @Test func stoppedAndLeftFadeOutTheCurrentLoop() {
        defer { cleanUp() }
        for activity in [ScrollActivity.stopped, .left] {
            let player = FakeSoundPlayer()
            let controller = makeController(defaults: makeDefaults(), player: player)
            controller.handle(.scrolling, loop: .humanSteps)
            controller.handle(activity, loop: .humanSteps)
            #expect(player.calls == [.startLoop(.humanSteps), .stopLoop(.humanSteps)])
            #expect(controller.currentLoop == nil)
        }
    }

    @Test func stopForANonCurrentLoopIsIgnored() {
        defer { cleanUp() }
        let player = FakeSoundPlayer()
        let controller = makeController(defaults: makeDefaults(), player: player)
        controller.handle(.scrolling, loop: .humanSteps)
        controller.handle(.left, loop: .catSteps)
        #expect(player.calls == [.startLoop(.humanSteps)])
        #expect(controller.currentLoop == .humanSteps)
    }

    @Test func stopAllLoopsFadesTheLoopAndNeverCallsStopAll() {
        defer { cleanUp() }
        let player = FakeSoundPlayer()
        let controller = makeController(defaults: makeDefaults(), player: player)
        controller.handle(.scrolling, loop: .catSteps)
        controller.stopAllLoops()
        #expect(player.calls == [.startLoop(.catSteps), .stopLoop(.catSteps)])
        #expect(controller.currentLoop == nil)
    }

    @Test func testMuteBlocksPlayAndLoops() {
        defer { cleanUp() }
        let player = FakeSoundPlayer()
        let controller = makeController(defaults: makeDefaults(), muted: true, player: player)
        controller.play(.hiss)
        controller.handle(.scrolling, loop: .humanSteps)
        #expect(player.calls.isEmpty)
        #expect(controller.currentLoop == nil)
    }

    @Test func repeatedScrollingStartsOnce() {
        defer { cleanUp() }
        let player = FakeSoundPlayer()
        let controller = makeController(defaults: makeDefaults(), player: player)
        controller.handle(.scrolling, loop: .humanSteps)
        controller.handle(.scrolling, loop: .humanSteps)
        #expect(player.calls == [.startLoop(.humanSteps)])
    }
}
