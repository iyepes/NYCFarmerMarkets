//
//  LoadFailureMessage.swift
//  NYCFarmerMarkets
//

import Foundation

/// A friendly, non-technical description of why the markets could not be loaded.
///
/// The title has a light spooky flavor; the hint is plain and says what to do.
/// The raw error text is never shown to users.
nonisolated struct LoadFailureMessage: Equatable, Sendable {
    let title: String
    let hint: String

    /// The device has no usable connection.
    static let offline = LoadFailureMessage(
        title: "You're off the grid",
        hint: "Check your connection, then try again."
    )
    /// The request timed out or the server could not be reached.
    static let unreachable = LoadFailureMessage(
        title: "The markets are hiding",
        hint: "We couldn't reach NYC Open Data. Try again in a moment."
    )
    /// The server answered with an error status.
    static let serverProblem = LoadFailureMessage(
        title: "NYC Open Data is sleeping",
        hint: "The server had a problem. Try again in a moment."
    )
    /// Unreadable data, or any error we don't recognize.
    static let unknown = LoadFailureMessage(
        title: "Something spooked the data",
        hint: "We couldn't read the markets. Try again."
    )
    /// The download worked but returned no markets.
    static let noMarkets = LoadFailureMessage(
        title: "The market stalls are empty",
        hint: "No markets are available right now. Try again soon."
    )

    /// Maps any error from loading markets to a friendly message.
    static func make(for error: Error) -> LoadFailureMessage {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .dataNotAllowed, .networkConnectionLost, .internationalRoamingOff:
                return .offline
            case .timedOut, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
                return .unreachable
            default:
                return .unknown
            }
        }
        if error is MarketServiceError { return .serverProblem }
        return .unknown
    }
}
