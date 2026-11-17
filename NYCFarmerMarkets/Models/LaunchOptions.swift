//
//  LaunchOptions.swift
//  NYCFarmerMarkets
//

import Foundation

/// UI-test hooks parsed from the process launch arguments.
///
/// These flags exist only so UI tests can put the app into a known state.
/// They are inert unless the corresponding argument is passed at launch.
nonisolated struct LaunchOptions: Equatable, Sendable {
    /// Clears persisted favorites and the sound setting at launch. Argument: `-uiTestingReset`.
    var resetFavorites = false

    /// Silences all interaction sounds and skips audio setup. Argument: `-uiTestingMuteSounds`.
    var muteSounds = false

    /// Forces the market download to fail. Argument: `-uiTestingFailDownload`.
    var failDownload = false

    /// Overrides the splash minimum display time, so UI tests can observe the splash
    /// even though `XCUIApplication.launch()` returns only after the app is idle.
    /// Argument: `-uiTestingSplashMinimumSeconds <seconds>` (positive, finite).
    var splashMinimumSeconds: Double?

    /// Marks onboarding as seen at launch. Argument: `-uiTestingSkipOnboarding`.
    var skipOnboarding = false

    /// Removes the onboarding flag at launch, so onboarding shows. Argument: `-uiTestingResetOnboarding`.
    var resetOnboarding = false

    /// What launch does to the onboarding flag. `-uiTestingResetOnboarding` wins over the other two.
    nonisolated enum OnboardingFlagAction: Equatable, Sendable { case none, markSeen, reset }

    var onboardingFlagAction: OnboardingFlagAction {
        if resetOnboarding { return .reset }
        if skipOnboarding || resetFavorites { return .markSeen }
        return .none
    }

    /// Builds options from launch arguments (e.g. `ProcessInfo.processInfo.arguments`).
    /// Each flag is true when its argument is contained in `arguments`.
    init(arguments: [String]) {
        skipOnboarding = arguments.contains("-uiTestingSkipOnboarding")
        resetOnboarding = arguments.contains("-uiTestingResetOnboarding")
        resetFavorites = arguments.contains("-uiTestingReset")
        failDownload = arguments.contains("-uiTestingFailDownload")
        muteSounds = arguments.contains("-uiTestingMuteSounds")
        if let index = arguments.firstIndex(of: "-uiTestingSplashMinimumSeconds"),
           arguments.indices.contains(index + 1),
           let seconds = Double(arguments[index + 1]), seconds.isFinite, seconds > 0 {
            splashMinimumSeconds = seconds
        }
    }
}

extension LaunchOptions.OnboardingFlagAction {
    /// Performs the write: sets `true`, removes the key, or does nothing.
    func apply(to defaults: UserDefaults, key: String = OnboardingDecision.defaultsKey) {
        switch self {
        case .none: break
        case .markSeen: defaults.set(true, forKey: key)
        case .reset: defaults.removeObject(forKey: key)
        }
    }
}
