//
//  SoundPolicyTests.swift
//  NYCFarmerMarketsTests
//
import Testing
import SwiftUI
@testable import NYCFarmerMarkets

struct SoundPolicyTests {
    @Test func shouldPlayOnlyWhenEnabledAndNotMuted() {
        for enabled in [true, false] {
            for voiceOver in [true, false] {
                for muted in [true, false] {
                    let expected = enabled && !voiceOver && !muted
                    #expect(SoundPolicy.shouldPlay(enabled: enabled, voiceOverOn: voiceOver, testMuted: muted) == expected)
                }
            }
        }
    }

    @Test func scrollPhasesMapToActivities() {
        #expect(SoundPolicy.activity(for: .interacting) == .scrolling)
        #expect(SoundPolicy.activity(for: .decelerating) == .scrolling)
        #expect(SoundPolicy.activity(for: .idle) == .stopped)
        #expect(SoundPolicy.activity(for: .tracking) == nil)
        #expect(SoundPolicy.activity(for: .animating) == nil)
    }

    @Test func loopStartsOnceThenStops() {
        #expect(SoundPolicy.loopAction(isLooping: false, activity: .scrolling) == .start)
        #expect(SoundPolicy.loopAction(isLooping: true, activity: .scrolling) == LoopAction.none)
        #expect(SoundPolicy.loopAction(isLooping: true, activity: .stopped) == .stop)
    }

    @Test func stopWhenNotLoopingDoesNothing() {
        #expect(SoundPolicy.loopAction(isLooping: false, activity: .stopped) == LoopAction.none)
        #expect(SoundPolicy.loopAction(isLooping: false, activity: .left) == LoopAction.none)
    }

    @Test func leavingWhileLoopingStops() {
        #expect(SoundPolicy.loopAction(isLooping: true, activity: .left) == .stop)
    }
}
