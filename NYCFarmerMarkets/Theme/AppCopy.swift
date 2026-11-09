//
//  AppCopy.swift
//  NYCFarmerMarkets
//
//  User-facing text with a light spooky tone. Accessibility strings stay plain.
//
import Foundation

nonisolated enum AppCopy {
    // MARK: Splash
    static let splashLoadingCaption = "Summoning markets…"
    static let splashLoadingAccessibility = "Loading farmers markets"

    // MARK: Offline banner
    static let offlineBanner = "Lost in the fog, showing saved markets"
    static let offlineBannerAccessibility = "Offline, showing saved data"

    // MARK: Search
    static let searchPrompt = "Hunt by name, address or borough"
    static let noResultsTitle = "Nothing lurking here"
    static let noResultsTitleAccessibility = "No markets found"

    static func noResultsHint(query: String) -> String {
        "No markets match “\(query)”. Try another search."
    }

    // MARK: Map filter indicator
    static func mapFilterSummary(query: String, count: Int) -> String {
        let q = MarketSearch.normalized(query)
        switch count {
        case 0: return "No markets lurking for “\(q)”"
        case 1: return "1 market lurking for “\(q)”"
        default: return "\(count) markets lurking for “\(q)”"
        }
    }

    static func mapFilterAccessibility(query: String, count: Int) -> String {
        let noun = count == 1 ? "result" : "results"
        return "Showing \(count) \(noun) for \(MarketSearch.normalized(query))"
    }

    // MARK: Detail view
    static let missingValue = "Shrouded in mist"
    static let missingValueAccessibility = "Not listed"
}
