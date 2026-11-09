//
//  SplashDecisionTests.swift
//  NYCFarmerMarketsTests
//

import Testing
@testable import NYCFarmerMarkets

struct SplashDecisionTests {

    private static let messages: [String?] = [
        nil,
        "",
        "Network error",
        "No connection 🌧️",
        "ошибка загрузки — 失败",
        String(repeating: "x", count: 500),
    ]

    private static let bools = [false, true]

    // Feature: splash-screen-collapsible-boroughs, Property 1: Splash is dismissed exactly when data is available and the minimum time has elapsed
    // Validates: Requirements 1.4, 2.1, 2.2, 3.1, 3.4
    @Test func property1_dismissedIffDataAndMinimumTime() {
        for data in Self.bools {
            for elapsed in Self.bools {
                for message in Self.messages {
                    let result = SplashDecision.phase(
                        dataAvailable: data,
                        minimumTimeElapsed: elapsed,
                        errorMessage: message
                    )
                    #expect((result == .dismissed) == (data && elapsed))
                    if data && !elapsed {
                        #expect(result == .loading)
                    }
                }
            }
        }
    }

    // Feature: splash-screen-collapsible-boroughs, Property 2: Failure without data shows the error, retry hides it
    // Validates: Requirements 3.5, 3.6
    @Test func property2_failureWithoutDataShowsErrorAndRetryHidesIt() {
        var generator = SystemRandomNumberGenerator()
        for elapsed in Self.bools {
            for message in Self.messages {
                if let message {
                    #expect(SplashDecision.phase(dataAvailable: false, minimumTimeElapsed: elapsed, errorMessage: message) == .failed(message: message))
                } else {
                    #expect(SplashDecision.phase(dataAvailable: false, minimumTimeElapsed: elapsed, errorMessage: nil) == .loading)
                }
            }
        }
        // Random messages, 200 iterations.
        for _ in 0..<200 {
            let length = Int.random(in: 0...40, using: &generator)
            let message = String((0..<length).map { _ in
                Character(UnicodeScalar(UInt32.random(in: 0x20...0x2FF, using: &generator)) ?? "a")
            })
            let elapsed = Bool.random(using: &generator)
            #expect(SplashDecision.phase(dataAvailable: false, minimumTimeElapsed: elapsed, errorMessage: message) == .failed(message: message))
            #expect(SplashDecision.phase(dataAvailable: false, minimumTimeElapsed: elapsed, errorMessage: nil) == .loading)
        }
    }

    // Validates: Requirements 1.4, 2.1, 2.2, 3.1, 3.4, 3.5, 3.6
    @Test func truthTableExamples() {
        #expect(SplashDecision.phase(dataAvailable: true, minimumTimeElapsed: true, errorMessage: nil) == .dismissed)
        #expect(SplashDecision.phase(dataAvailable: true, minimumTimeElapsed: false, errorMessage: nil) == .loading)
        #expect(SplashDecision.phase(dataAvailable: false, minimumTimeElapsed: false, errorMessage: "Offline") == .failed(message: "Offline"))
        #expect(SplashDecision.phase(dataAvailable: false, minimumTimeElapsed: false, errorMessage: nil) == .loading)
    }

    // Validates: Requirements 9.3
    @Test func minimumDisplayTimeIsOneSecond() {
        #expect(SplashDecision.minimumDisplayTime == .seconds(1))
    }
}
