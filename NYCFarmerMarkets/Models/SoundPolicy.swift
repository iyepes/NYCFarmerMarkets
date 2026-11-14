//
//  SoundPolicy.swift
//  NYCFarmerMarkets
//
//  Pure rules for when sounds play. This is the one Models/ file that imports
//  SwiftUI, because `ScrollPhase` is a plain enum that tests can construct.
//

import SwiftUI

/// What a scrolling list reports to the sound controller.
nonisolated enum ScrollActivity: Sendable {
    case scrolling
    case stopped
    /// The list went away (tab change, backgrounding).
    case left
}

nonisolated enum LoopAction: Equatable, Sendable {
    case start
    case stop
    case none
}

nonisolated enum SoundPolicy {
    static func shouldPlay(enabled: Bool, voiceOverOn: Bool, testMuted: Bool) -> Bool {
        enabled && !voiceOverOn && !testMuted
    }

    /// `nil` means "no change" (a finger resting or an animated expand must not start or stop a loop).
    static func activity(for phase: ScrollPhase) -> ScrollActivity? {
        switch phase {
        case .interacting, .decelerating: .scrolling
        case .idle: .stopped
        case .tracking, .animating: nil
        @unknown default: nil
        }
    }

    static func loopAction(isLooping: Bool, activity: ScrollActivity) -> LoopAction {
        switch activity {
        case .scrolling: isLooping ? .none : .start
        case .stopped, .left: isLooping ? .stop : .none
        }
    }
}
