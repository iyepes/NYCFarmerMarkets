//
//  MarketSearch.swift
//  NYCFarmerMarkets
//

import Foundation

/// The single search rule shared by the Markets list and the map.
nonisolated enum MarketSearch {
    /// The query with surrounding whitespace and newlines removed.
    static func normalized(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// True if the query is non-empty after trimming.
    static func isActive(_ query: String) -> Bool {
        !normalized(query).isEmpty
    }

    /// Markets matching `query`, in their original order. An inactive query returns all markets.
    static func filter(_ markets: [Market], query: String) -> [Market] {
        markets.filter { MarketGrouping.matches($0, query: query) }
    }

    /// Text such as `Showing 3 results for "kale"`.
    static func summary(query: String, count: Int) -> String {
        let noun = count == 1 ? "result" : "results"
        return "Showing \(count) \(noun) for \"\(normalized(query))\""
    }
}
