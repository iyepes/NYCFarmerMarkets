//
//  OnboardingDecisionTests.swift
//  NYCFarmerMarketsTests
//

import Testing
@testable import NYCFarmerMarkets

struct OnboardingDecisionTests {
    /// One row of the decision table.
    struct Case: Sendable, CustomTestStringConvertible {
        let phase: SplashPhase
        let hasSeen: Bool
        let expected: RootScreen
        var testDescription: String { "\(phase), seen=\(hasSeen) -> \(expected)" }
    }

    static let table: [Case] = [
        Case(phase: .loading, hasSeen: false, expected: .splash),
        Case(phase: .loading, hasSeen: true, expected: .splash),
        Case(phase: .failed(message: "x"), hasSeen: false, expected: .splash),
        Case(phase: .failed(message: "x"), hasSeen: true, expected: .splash),
        Case(phase: .dismissed, hasSeen: false, expected: .onboarding),
        Case(phase: .dismissed, hasSeen: true, expected: .tabs),
    ]

    // Feature: onboarding-flow, Property 1: Decision table
    // Validates: Requirements 1.1, 2.1, 5.2, 5.3, 5.4, 10.1
    @Test(arguments: table)
    func decisionTable(_ row: Case) {
        #expect(OnboardingDecision.screen(phase: row.phase, hasSeenOnboarding: row.hasSeen) == row.expected)
    }

    @Test func defaultsKeyIsStable() {
        #expect(OnboardingDecision.defaultsKey == "hasSeenOnboarding")
    }

    // Edge values: empty, whitespace only, long, non-ASCII, multi-line.
    static let messages: [String] = [
        "",
        " ",
        "   \n\t  ",
        String(repeating: "spooky ", count: 500),
        "Los mercados se esconden 👻 — 市場 — سوق",
        "line one\nline two",
    ]

    // Feature: onboarding-flow, Property 2: Failure message does not matter
    // Validates: Requirements 4.5, 4.7, 5.2
    @Test(arguments: messages, [false, true])
    func failureMessageNeverChangesTheScreen(message: String, hasSeen: Bool) {
        #expect(OnboardingDecision.screen(phase: .failed(message: message), hasSeenOnboarding: hasSeen) == .splash)
    }

    // Feature: onboarding-flow, Property 3: Decision has no memory
    // Validates: Requirements 2.6, 5.5, 5.6
    @Test func interleavedInputsAreIndependent() {
        #expect(OnboardingDecision.screen(phase: .dismissed, hasSeenOnboarding: false) == .onboarding)
        #expect(OnboardingDecision.screen(phase: .dismissed, hasSeenOnboarding: true) == .tabs)
        #expect(OnboardingDecision.screen(phase: .dismissed, hasSeenOnboarding: false) == .onboarding)
    }

    // Feature: onboarding-flow, Property 3: Decision has no memory
    // Validates: Requirements 2.6, 5.5, 5.6
    @Test(arguments: table)
    func sameInputTwiceGivesSameScreen(_ row: Case) {
        let first = OnboardingDecision.screen(phase: row.phase, hasSeenOnboarding: row.hasSeen)
        let second = OnboardingDecision.screen(phase: row.phase, hasSeenOnboarding: row.hasSeen)
        #expect(first == second)
    }

    // Feature: onboarding-flow, Property 3: Decision has no memory
    // Validates: Requirements 2.6, 5.5, 5.6
    @Test func sequenceMatchesEachInputEvaluatedAlone() {
        // Run the whole table in a shuffled-looking fixed order, twice, and compare with a fresh call.
        let order = [4, 0, 5, 2, 4, 1, 3, 5, 5, 4, 0]
        for index in order {
            let row = Self.table[index]
            let result = OnboardingDecision.screen(phase: row.phase, hasSeenOnboarding: row.hasSeen)
            #expect(result == row.expected)
        }
    }
}
