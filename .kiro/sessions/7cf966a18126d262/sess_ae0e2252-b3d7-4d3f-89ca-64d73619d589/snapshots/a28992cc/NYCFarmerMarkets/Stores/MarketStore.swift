//
//  MarketStore.swift
//  NYCFarmerMarkets
//

import Foundation
import Observation

@Observable
final class MarketStore {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    private(set) var markets: [Market] = []
    private(set) var state: LoadState = .idle
    /// True when the list shown comes from disk because the network refresh failed.
    private(set) var isShowingCachedData = false
    /// The market shown in the shared detail sheet (nil = sheet closed).
    var selectedMarket: Market?

    @ObservationIgnored private let fetch: @Sendable () async throws -> [Market]
    @ObservationIgnored private let cache: MarketCache

    init(
        cache: MarketCache = MarketCache(),
        fetch: @escaping @Sendable () async throws -> [Market] = { try await MarketService().fetchMarkets() }
    ) {
        self.cache = cache
        self.fetch = fetch
    }

    /// Loads the cached list first (if any), then refreshes from the network.
    func load() async {
        if markets.isEmpty, let cached = cache.load(), !cached.isEmpty {
            // Show saved data immediately; the offline flag is only set if the refresh fails.
            markets = cached
            state = .loaded
        }
        await refresh()
    }

    func refresh() async {
        if markets.isEmpty { state = .loading }
        do {
            let fresh = try await fetch()
            markets = fresh
            state = .loaded
            isShowingCachedData = false
            try? cache.save(fresh)
        } catch is CancellationError {
            restoreStateAfterCancel()
        } catch let error as URLError where error.code == .cancelled {
            restoreStateAfterCancel()
        } catch {
            if markets.isEmpty {
                state = .error(error.localizedDescription)
            } else {
                state = .loaded
                isShowingCachedData = true
            }
        }
    }

    private func restoreStateAfterCancel() {
        if state == .loading { state = markets.isEmpty ? .idle : .loaded }
    }
}
