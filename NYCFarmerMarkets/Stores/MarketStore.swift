//
//  MarketStore.swift
//  NYCFarmerMarkets
//

import Foundation
import Observation
import OSLog

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
    /// True when the network refresh failed and the list shown is saved data.
    private(set) var isShowingCachedData = false
    /// Friendly description of the last failure while there is no data to show (nil otherwise).
    private(set) var failure: LoadFailureMessage?
    /// The market shown in the shared detail sheet (nil = sheet closed).
    var selectedMarket: Market?
    /// The Markets list search text, shared so the map can show the same results.
    var searchQuery = ""

    private static let logger = Logger(subsystem: "com.hacemoscontactos.NYCFarmerMarkets", category: "MarketStore")

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
        if markets.isEmpty {
            state = .loading
            failure = nil
        }
        do {
            let fresh = try await fetch()
            markets = fresh
            state = .loaded
            failure = nil
            isShowingCachedData = false
            try? cache.save(fresh)
        } catch is CancellationError {
            restoreStateAfterCancel()
        } catch let error as URLError where error.code == .cancelled {
            restoreStateAfterCancel()
        } catch {
            // The technical error is logged, never shown to users.
            Self.logger.warning("Loading markets failed: \(error.localizedDescription, privacy: .public)")
            if markets.isEmpty {
                let message = LoadFailureMessage.make(for: error)
                failure = message
                state = .error(message.title)
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
