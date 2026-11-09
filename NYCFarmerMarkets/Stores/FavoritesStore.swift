//
//  FavoritesStore.swift
//  NYCFarmerMarkets
//

import Foundation
import Observation

/// Favorite market IDs, persisted locally in UserDefaults.
@Observable
final class FavoritesStore {
    private(set) var ids: Set<String>

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let key: String

    init(defaults: UserDefaults = .standard, key: String = "favoriteMarketIDs") {
        self.defaults = defaults
        self.key = key
        self.ids = Set(defaults.stringArray(forKey: key) ?? [])
    }

    func isFavorite(_ market: Market) -> Bool { ids.contains(market.id) }

    func toggle(_ market: Market) {
        if ids.contains(market.id) { ids.remove(market.id) } else { ids.insert(market.id) }
        persist()
    }

    func remove(_ market: Market) {
        ids.remove(market.id)
        persist()
    }

    /// Favorited markets present in `markets`, sorted by name. Stored IDs with no
    /// matching market are skipped (but kept in storage).
    func favorites(in markets: [Market]) -> [Market] {
        markets
            .filter { ids.contains($0.id) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func persist() {
        defaults.set(Array(ids).sorted(), forKey: key)
    }
}
