//
//  LoadFailureMessageTests.swift
//  NYCFarmerMarketsTests
//

import Foundation
import Testing
@testable import NYCFarmerMarkets

struct LoadFailureMessageTests {

    @Test(arguments: [
        URLError.Code.notConnectedToInternet, .dataNotAllowed, .networkConnectionLost, .internationalRoamingOff,
    ])
    func offlineCodesMapToOffline(code: URLError.Code) {
        #expect(LoadFailureMessage.make(for: URLError(code)) == .offline)
    }

    @Test(arguments: [
        URLError.Code.timedOut, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed,
    ])
    func unreachableCodesMapToUnreachable(code: URLError.Code) {
        #expect(LoadFailureMessage.make(for: URLError(code)) == .unreachable)
    }

    @Test func badStatusMapsToServerProblem() {
        #expect(LoadFailureMessage.make(for: MarketServiceError.badStatus(503)) == .serverProblem)
    }

    @Test func otherErrorsMapToUnknown() {
        struct Odd: Error {}
        #expect(LoadFailureMessage.make(for: Odd()) == .unknown)
        #expect(LoadFailureMessage.make(for: URLError(.badURL)) == .unknown)
        let decoding = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "bad"))
        #expect(LoadFailureMessage.make(for: decoding) == .unknown)
    }

    @Test func messagesAreFriendlyAndNeverTechnical() {
        let all: [LoadFailureMessage] = [.offline, .unreachable, .serverProblem, .unknown, .noMarkets]
        let banned = ["NSURLErrorDomain", "operation couldn", "error -", "Error Domain", "Code="]
        for message in all {
            #expect(!message.title.isEmpty && !message.hint.isEmpty)
            for text in [message.title, message.hint] {
                for fragment in banned {
                    #expect(!text.localizedCaseInsensitiveContains(fragment), "\(text) contains \(fragment)")
                }
            }
        }
        #expect(Set(all.map(\.title)).count == all.count, "Each cause should have its own title")
    }

    @MainActor
    @Test func storeExposesFriendlyFailureWhenOfflineWithoutCache() async {
        let store = MarketStore(cache: temporaryCache()) { throw URLError(.notConnectedToInternet) }
        await store.load()
        #expect(store.failure == .offline)
        #expect(store.state == .error(LoadFailureMessage.offline.title))
    }

    @MainActor
    @Test func storeClearsFailureAfterSuccessfulRetry() async {
        nonisolated(unsafe) var attempts = 0
        let store = MarketStore(cache: temporaryCache()) {
            attempts += 1
            if attempts == 1 { throw MarketServiceError.badStatus(500) }
            return [Fixture.market("Fresh")]
        }
        await store.load()
        #expect(store.failure == .serverProblem)
        await store.refresh()
        #expect(store.failure == nil)
        #expect(store.state == .loaded)
    }

    @MainActor
    @Test func storeHasNoFailureWhenCachedDataExists() async throws {
        let cache = temporaryCache()
        try cache.save([Fixture.market("Cached")])
        let store = MarketStore(cache: cache) { throw URLError(.timedOut) }
        await store.load()
        #expect(store.failure == nil)
        #expect(store.isShowingCachedData)
    }
}
