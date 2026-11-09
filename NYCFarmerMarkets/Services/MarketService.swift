//
//  MarketService.swift
//  NYCFarmerMarkets
//

import Foundation

nonisolated enum MarketServiceError: Error, LocalizedError, Equatable {
    case badStatus(Int)

    var errorDescription: String? {
        switch self {
        case .badStatus(let code): "The server responded with status \(code)."
        }
    }
}

/// Fetches farmers markets from NYC Open Data.
nonisolated struct MarketService: Sendable {
    /// The dataset holds one row per market per year (2009...), so we request them all
    /// and keep only the most recent year.
    static let defaultURL = URL(string: "https://data.cityofnewyork.us/resource/8vwk-6iz2.json?$limit=5000")!

    var url: URL
    var session: URLSession

    init(url: URL = MarketService.defaultURL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    func fetchMarkets() async throws -> [Market] {
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw MarketServiceError.badStatus(http.statusCode)
        }
        return try Self.parse(data)
    }

    /// Decodes API rows, keeps the latest year only, and removes duplicates.
    static func parse(_ data: Data) throws -> [Market] {
        let rows = try JSONDecoder().decode([Market.Raw].self, from: data)
        let markets = rows.compactMap(Market.init(raw:))

        let latestYear = markets.compactMap { $0.year.flatMap(Int.init) }.max()
        let current = markets.filter { market in
            guard let latestYear else { return true }
            return market.year.flatMap(Int.init) == latestYear
        }

        var seen = Set<String>()
        return current.filter { seen.insert($0.id).inserted }
    }
}
