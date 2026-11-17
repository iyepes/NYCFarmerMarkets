//
//  LaunchOptionsTests.swift
//  NYCFarmerMarketsTests
//

import Testing
@testable import NYCFarmerMarkets

struct LaunchOptionsTests {
    private static let reset = "-uiTestingReset"
    private static let fail = "-uiTestingFailDownload"

    @Test func neitherArgumentLeavesBothFlagsFalse() {
        for args in [[], ["/path/to/app"]] as [[String]] {
            let options = LaunchOptions(arguments: args)
            #expect(options.resetFavorites == false)
            #expect(options.failDownload == false)
        }
    }

    @Test func onlyResetSetsResetFavorites() {
        let options = LaunchOptions(arguments: ["/path/to/app", Self.reset])
        #expect(options.resetFavorites == true)
        #expect(options.failDownload == false)
    }

    @Test func onlyFailDownloadSetsFailDownload() {
        let options = LaunchOptions(arguments: ["/path/to/app", Self.fail])
        #expect(options.failDownload == true)
        #expect(options.resetFavorites == false)
    }

    @Test func bothArgumentsInEitherOrderWithUnrelatedArgs() {
        let first = LaunchOptions(arguments: ["/app", Self.reset, "-foo", Self.fail])
        let second = LaunchOptions(arguments: ["-bar", Self.fail, "/app", Self.reset])
        for options in [first, second] {
            #expect(options.resetFavorites == true)
            #expect(options.failDownload == true)
        }
    }

    @Test func similarlyNamedArgumentsDoNotMatch() {
        let options = LaunchOptions(arguments: [
            "-uiTestingResetX", "uiTestingReset", "-uiTestingFailDownloadX", "uiTestingFailDownload",
        ])
        #expect(options.resetFavorites == false)
        #expect(options.failDownload == false)
    }

    @Test func muteSoundsArgumentSetsMuteSounds() {
        #expect(LaunchOptions(arguments: ["/app", "-uiTestingMuteSounds"]).muteSounds == true)
    }

    @Test func muteSoundsIsFalseWhenAbsent() {
        #expect(LaunchOptions(arguments: ["/app", Self.reset]).muteSounds == false)
    }

    @Test func similarlyNamedMuteArgumentsDoNotMatch() {
        let options = LaunchOptions(arguments: ["-uiTestingMuteSoundsX", "uiTestingMuteSounds"])
        #expect(options.muteSounds == false)
    }

    @Test func splashMinimumSecondsParsesPositiveValue() {
        let options = LaunchOptions(arguments: ["/app", "-uiTestingSplashMinimumSeconds", "4.5"])
        #expect(options.splashMinimumSeconds == 4.5)
    }

    @Test func splashMinimumSecondsIgnoresMissingOrInvalidValues() {
        let key = "-uiTestingSplashMinimumSeconds"
        for args in [["/app"], ["/app", key], ["/app", key, "abc"], ["/app", key, "0"], ["/app", key, "-2"],
                     ["/app", key, "inf"], ["/app", key, "nan"]] {
            #expect(LaunchOptions(arguments: args).splashMinimumSeconds == nil, "args: \(args)")
        }
    }

    // MARK: Onboarding flags

    private static let skip = "-uiTestingSkipOnboarding"
    private static let resetOnboarding = "-uiTestingResetOnboarding"

    /// Every subset of this pool, in pool order and in reverse order, plus the empty list.
    /// The pool holds both known flags, near misses (suffix, missing dash, different case) and unrelated strings.
    private static let argumentPool = [
        skip, resetOnboarding, "-uiTestingResetOnboardingX", "uiTestingSkipOnboarding",
        "-UITESTINGSKIPONBOARDING", "/path/to/app",
    ]

    private static let argumentLists: [[String]] = {
        var lists: [[String]] = []
        for mask in 0..<(1 << argumentPool.count) {
            let subset = argumentPool.indices.filter { mask & (1 << $0) != 0 }.map { argumentPool[$0] }
            lists.append(subset)
            if subset.count > 1 { lists.append(subset.reversed()) }
        }
        return lists
    }()

    // Feature: onboarding-flow, Property 4: Launch arguments parse by exact match
    // Exhaustive over subsets and orders of a fixed pool of known, near-miss and unrelated arguments.
    @Test(arguments: argumentLists)
    func onboardingArgumentsParseByExactMatch(arguments: [String]) {
        let options = LaunchOptions(arguments: arguments)
        #expect(options.skipOnboarding == arguments.contains { $0 == Self.skip }, "args: \(arguments)")
        #expect(options.resetOnboarding == arguments.contains { $0 == Self.resetOnboarding }, "args: \(arguments)")
        // The onboarding flags do not affect the other flags.
        #expect(options.resetFavorites == false)
        #expect(options.splashMinimumSeconds == nil)
    }

    @Test func emptyArgumentListLeavesOnboardingFlagsFalse() {
        let options = LaunchOptions(arguments: [])
        #expect(options.skipOnboarding == false)
        #expect(options.resetOnboarding == false)
    }

    struct FlagCombination: Sendable, CustomTestStringConvertible {
        let resetFavorites: Bool
        let skipOnboarding: Bool
        let resetOnboarding: Bool

        var testDescription: String {
            "resetFavorites=\(resetFavorites) skip=\(skipOnboarding) resetOnboarding=\(resetOnboarding)"
        }

        var arguments: [String] {
            var args = ["/path/to/app"]
            if resetFavorites { args.append("-uiTestingReset") }
            if skipOnboarding { args.append("-uiTestingSkipOnboarding") }
            if resetOnboarding { args.append("-uiTestingResetOnboarding") }
            return args
        }

        static let all: [FlagCombination] = [false, true].flatMap { favorites in
            [false, true].flatMap { skip in
                [false, true].map { FlagCombination(resetFavorites: favorites, skipOnboarding: skip, resetOnboarding: $0) }
            }
        }
    }

    // Feature: onboarding-flow, Property 5: Onboarding flag action precedence
    // Exhaustive over all 8 combinations, built from launch arguments.
    @Test(arguments: FlagCombination.all)
    func onboardingFlagActionPrecedence(combination: FlagCombination) {
        let options = LaunchOptions(arguments: combination.arguments)
        let expected: LaunchOptions.OnboardingFlagAction =
            combination.resetOnboarding ? .reset
            : (combination.skipOnboarding || combination.resetFavorites) ? .markSeen
            : .none
        #expect(options.onboardingFlagAction == expected)
    }

    @Test func onboardingFlagActionExamples() {
        #expect(LaunchOptions(arguments: ["/app"]).onboardingFlagAction == .none)
        #expect(LaunchOptions(arguments: ["/app", Self.skip]).onboardingFlagAction == .markSeen)
        #expect(LaunchOptions(arguments: ["/app", Self.resetOnboarding]).onboardingFlagAction == .reset)
        #expect(LaunchOptions(arguments: ["/app", Self.skip, Self.resetOnboarding]).onboardingFlagAction == .reset)
    }
}
