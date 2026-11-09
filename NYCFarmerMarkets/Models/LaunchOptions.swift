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
    /// Clears persisted favorites at launch. Argument: `-uiTestingReset`.
    var resetFavorites = false

    /// Forces the market download to fail. Argument: `-uiTestingFailDownload`.
    var failDownload = false

    /// Overrides the splash minimum display time, so UI tests can observe the splash
    /// even though `XCUIApplication.launch()` returns only after the app is idle.
    /// Argument: `-uiTestingSplashMinimumSeconds <seconds>` (positive, finite).
    var splashMinimumSeconds: Double?

    /// Builds options from launch arguments (e.g. `ProcessInfo.processInfo.arguments`).
    /// Each flag is true when its argument is contained in `arguments`.
    init(arguments: [String]) {
        resetFavorites = arguments.contains("-uiTestingReset")
        failDownload = arguments.contains("-uiTestingFailDownload")
        if let index = arguments.firstIndex(of: "-uiTestingSplashMinimumSeconds"),
           arguments.indices.contains(index + 1),
           let seconds = Double(arguments[index + 1]), seconds.isFinite, seconds > 0 {
            splashMinimumSeconds = seconds
        }
    }
}
