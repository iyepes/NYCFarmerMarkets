//
//  OnboardingDecision.swift
//  NYCFarmerMarkets
//

import Foundation

/// The top-level screen the app shows.
nonisolated enum RootScreen: Equatable, Sendable {
    case splash, onboarding, tabs
}

/// Pure decision logic for which `RootScreen` the app shows.
nonisolated enum OnboardingDecision {
    /// `UserDefaults` key for "the user has finished or skipped onboarding".
    static let defaultsKey = "hasSeenOnboarding"

    /// Splash while loading or failed; once dismissed, onboarding until the flag is true, then tabs.
    static func screen(phase: SplashPhase, hasSeenOnboarding: Bool) -> RootScreen {
        guard phase == .dismissed else { return .splash }
        return hasSeenOnboarding ? .tabs : .onboarding
    }
}
