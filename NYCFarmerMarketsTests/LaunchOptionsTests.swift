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
}
