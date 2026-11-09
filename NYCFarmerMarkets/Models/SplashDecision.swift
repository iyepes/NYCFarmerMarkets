//
//  SplashDecision.swift
//  NYCFarmerMarkets
//

import Foundation

/// The state of the launch splash screen.
nonisolated enum SplashPhase: Equatable, Sendable {
    /// The splash is visible and the app is still loading data (or waiting
    /// for the minimum display time to elapse).
    case loading
    /// Loading failed with no data available; the splash shows `message`
    /// along with a retry affordance.
    case failed(message: String)
    /// The splash is gone and the main content is shown.
    case dismissed
}

/// Pure decision logic for which `SplashPhase` the app should be in.
nonisolated enum SplashDecision {
    /// Minimum time the splash stays visible when data loads successfully.
    static let minimumDisplayTime: Duration = .seconds(1)

    /// Computes the splash phase from the current loading state.
    ///
    /// - Data wins over error: if `dataAvailable`, the splash is dismissed once
    ///   `minimumTimeElapsed` is true, otherwise it keeps loading.
    /// - With no data and an error, the failure is shown immediately, without
    ///   waiting for the minimum display time.
    /// - With no data and no error, the splash keeps loading.
    static func phase(
        dataAvailable: Bool,
        minimumTimeElapsed: Bool,
        errorMessage: String?
    ) -> SplashPhase {
        if dataAvailable {
            return minimumTimeElapsed ? .dismissed : .loading
        }
        if let errorMessage {
            return .failed(message: errorMessage)
        }
        return .loading
    }
}
