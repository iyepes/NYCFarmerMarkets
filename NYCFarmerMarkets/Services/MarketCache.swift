//
//  MarketCache.swift
//  NYCFarmerMarkets
//

import Foundation

/// Stores the last successful fetch as a JSON file.
nonisolated struct MarketCache: Sendable {
    let fileURL: URL

    init(fileURL: URL = MarketCache.defaultFileURL) {
        self.fileURL = fileURL
    }

    static var defaultFileURL: URL {
        let base = (try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        )) ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("markets-cache.json")
    }

    func load() -> [Market]? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode([Market].self, from: data)
    }

    func save(_ markets: [Market]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(markets)
        try data.write(to: fileURL, options: .atomic)
    }
}
