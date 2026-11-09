//
//  MarketGrouping.swift
//  NYCFarmerMarkets
//

import Foundation

nonisolated struct BoroughSection: Identifiable, Equatable, Sendable {
    let borough: String
    let markets: [Market]
    var id: String { borough }
}

nonisolated enum MarketGrouping {
    static let boroughOrder = ["Manhattan", "Brooklyn", "Queens", "Bronx", "Staten Island"]

    static func matches(_ market: Market, query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return [market.name, market.address, market.borough].contains {
            $0.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    /// Filters by `query`, groups by borough (fixed order, unknown boroughs last
    /// alphabetically), sorts markets by name, and drops empty sections.
    static func sections(from markets: [Market], query: String = "") -> [BoroughSection] {
        let grouped = Dictionary(grouping: MarketSearch.filter(markets, query: query), by: \.borough)

        func rank(_ borough: String) -> Int {
            boroughOrder.firstIndex(of: borough) ?? boroughOrder.count
        }

        return grouped.keys
            .sorted { lhs, rhs in
                let (l, r) = (rank(lhs), rank(rhs))
                return l != r ? l < r : lhs.localizedStandardCompare(rhs) == .orderedAscending
            }
            .map { borough in
                BoroughSection(
                    borough: borough,
                    markets: grouped[borough, default: []].sorted {
                        $0.name.localizedStandardCompare($1.name) == .orderedAscending
                    }
                )
            }
    }
}
