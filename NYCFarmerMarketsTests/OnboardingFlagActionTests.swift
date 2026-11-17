//
//  OnboardingFlagActionTests.swift
//  NYCFarmerMarketsTests
//

import Foundation
import Testing
@testable import NYCFarmerMarkets

struct OnboardingFlagActionTests {
    private static let key = OnboardingDecision.defaultsKey

    /// Starting states: flag absent (nil), true, false.
    private static let startingStates: [Bool?] = [nil, true, false]

    private static let actions: [LaunchOptions.OnboardingFlagAction] = [.none, .markSeen, .reset]

    private struct Case: Sendable, CustomTestStringConvertible {
        let start: Bool?
        let action: LaunchOptions.OnboardingFlagAction
        var testDescription: String { "start \(String(describing: start)), action \(action)" }
    }

    private static let cases: [Case] = startingStates.flatMap { start in
        actions.map { Case(start: start, action: $0) }
    }

    /// The value the flag should hold after the action, with absent as nil.
    private static func expected(start: Bool?, action: LaunchOptions.OnboardingFlagAction) -> Bool? {
        switch action {
        case .none: return start
        case .markSeen: return true
        case .reset: return nil
        }
    }

    // Feature: onboarding-flow, Property 6: Applying a flag action writes the right value
    // **Validates: Requirements 2.4, 9.1, 9.2, 9.3, 9.5**
    @Test("Applying a flag action writes the right value", arguments: cases)
    private func appliesActionAndIsIdempotent(_ testCase: Case) throws {
        let suiteName = "OnboardingFlagActionTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        if let start = testCase.start {
            defaults.set(start, forKey: Self.key)
        }

        let expected = Self.expected(start: testCase.start, action: testCase.action)

        testCase.action.apply(to: defaults, key: Self.key)
        #expect(defaults.object(forKey: Self.key) as? Bool == expected)

        // Applying again leaves the same state.
        testCase.action.apply(to: defaults, key: Self.key)
        #expect(defaults.object(forKey: Self.key) as? Bool == expected)

        // The decision for the stored value (absent read as false) matches Property 1.
        let stored = defaults.bool(forKey: Self.key)
        let screen = OnboardingDecision.screen(phase: .dismissed, hasSeenOnboarding: stored)
        #expect(screen == (expected == true ? .tabs : .onboarding))
    }
}
