//
//  NYCFarmerMarketsTests.swift
//  NYCFarmerMarketsTests
//
//  Created by Isabel Yepes on 8/11/26.
//

import CoreLocation
import Foundation
import Testing
#if canImport(UIKit)
import UIKit
#endif
@testable import NYCFarmerMarkets

// MARK: - Fixtures & helpers

enum Fixture {
    /// Two years of data: only the 2026 rows should survive parsing.
    static let json = """
    [
      {"year":"2026","marketname":"175th Street Greenmarket","borough":"manhattan","streetaddress":"W. 175th St.","community_district":"112","latitude":"40.845948","longitude":"-73.937811","daysoperation":"Thursday","hoursoperations":"8 a.m. - 4p.m.","accepts_ebt":"yes","open_year_round":"No","nyc_dept_of_health_cooking":"No"},
      {"year":"2026","marketname":"Zebra Market","borough":"Brooklyn","streetaddress":"1 Main St.","daysoperation":"Sunday"},
      {"year":"2026","marketname":"  Zebra Market ","borough":"Brooklyn","streetaddress":"1 Main St.","daysoperation":"Sunday"},
      {"year":"2026","marketname":"Alpha Market","borough":"  ","streetaddress":"2 Side St.","latitude":"0","longitude":"0"},
      {"year":"2026","marketname":"","borough":"Queens","streetaddress":"nowhere"},
      {"year":"2025","marketname":"Old Market","borough":"Bronx","streetaddress":"3 Old St.","latitude":"40.8","longitude":"-73.9"}
    ]
    """

    static func market(
        _ name: String, borough: String = "Brooklyn", address: String = "1 Main St.",
        lat: Double? = 40.7, lon: Double? = -74.0
    ) -> Market {
        let latText: String? = lat.map { String($0) }
        let lonText: String? = lon.map { String($0) }
        let raw = Market.Raw(
            year: "2026", marketname: name, borough: borough, streetaddress: address,
            community_district: nil, latitude: latText, longitude: lonText,
            daysoperation: "Saturday", hoursoperations: nil, accepts_ebt: nil,
            open_year_round: nil, nyc_dept_of_health_cooking: nil
        )
        return Market(raw: raw)!
    }
}

final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            guard let handler = Self.handler else { throw URLError(.badServerResponse) }
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
}

func mockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

func temporaryCache() -> MarketCache {
    MarketCache(fileURL: FileManager.default.temporaryDirectory
        .appendingPathComponent("cache-test-\(UUID().uuidString)/markets.json"))
}

func response(_ url: URL, status: Int = 200) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
}

// MARK: - Model & service

@Suite(.serialized)
struct ModelAndServiceTests {

    @Test func parseKeepsLatestYearDedupesAndNormalizes() throws {
        let markets = try MarketService.parse(Data(Fixture.json.utf8))
        #expect(markets.map(\.name) == ["175th Street Greenmarket", "Zebra Market", "Alpha Market"])

        let first = markets[0]
        #expect(first.borough == "Manhattan")
        #expect(first.acceptsEBT == "Yes")
        #expect(first.latitude == 40.845948)
        #expect(first.longitude == -73.937811)
        #expect(first.coordinate != nil)
        #expect(first.daysOfOperation == "Thursday")
    }

    @Test func missingOrZeroCoordinatesAreNil() throws {
        let markets = try MarketService.parse(Data(Fixture.json.utf8))
        let zebra = try #require(markets.first { $0.name == "Zebra Market" })
        let alpha = try #require(markets.first { $0.name == "Alpha Market" })
        #expect(zebra.coordinate == nil)
        #expect(alpha.coordinate == nil)
        #expect(alpha.borough == Market.unknownBorough)
    }

    @Test func idIsStableAndCaseInsensitive() {
        let a = Fixture.market("Union Square Greenmarket", address: "E. 17th St.")
        let b = Fixture.market("union square greenmarket", address: "e. 17th st.")
        #expect(a.id == b.id)
        #expect(a.id == Fixture.market("Union Square Greenmarket", address: "E. 17th St.").id)
    }

    @Test func serviceFetchesAndParses() async throws {
        MockURLProtocol.handler = { request in
            (response(request.url!), Data(Fixture.json.utf8))
        }
        let service = MarketService(url: URL(string: "https://example.com/markets.json")!, session: mockSession())
        let markets = try await service.fetchMarkets()
        #expect(markets.count == 3)
    }

    @Test func serviceThrowsOnBadStatus() async {
        MockURLProtocol.handler = { request in (response(request.url!, status: 500), Data()) }
        let service = MarketService(url: URL(string: "https://example.com/markets.json")!, session: mockSession())
        await #expect(throws: MarketServiceError.badStatus(500)) {
            _ = try await service.fetchMarkets()
        }
    }
}

// MARK: - Cache & store

@MainActor
struct CacheAndStoreTests {

    @Test func cacheRoundTrip() throws {
        let cache = temporaryCache()
        #expect(cache.load() == nil)
        let markets = [Fixture.market("A"), Fixture.market("B", borough: "Queens")]
        try cache.save(markets)
        #expect(cache.load() == markets)
    }

    @Test func successUpdatesStateAndCache() async {
        let cache = temporaryCache()
        let markets = [Fixture.market("A")]
        let store = MarketStore(cache: cache) { markets }
        await store.load()
        #expect(store.markets == markets)
        #expect(store.state == .loaded)
        #expect(store.isShowingCachedData == false)
        #expect(cache.load() == markets)
    }

    @Test func failureFallsBackToCache() async throws {
        let cache = temporaryCache()
        let cached = [Fixture.market("Cached")]
        try cache.save(cached)
        let store = MarketStore(cache: cache) { throw URLError(.notConnectedToInternet) }
        await store.load()
        #expect(store.markets == cached)
        #expect(store.state == .loaded)
        #expect(store.isShowingCachedData)
    }

    @Test func failureWithoutCacheIsError() async {
        let store = MarketStore(cache: temporaryCache()) { throw URLError(.notConnectedToInternet) }
        await store.load()
        #expect(store.markets.isEmpty)
        guard case .error = store.state else {
            Issue.record("Expected error state, got \(store.state)")
            return
        }
    }

    @Test func refreshAfterOfflineRecovers() async throws {
        let cache = temporaryCache()
        try cache.save([Fixture.market("Old")])
        let fresh = [Fixture.market("New")]
        nonisolated(unsafe) var shouldFail = true
        let store = MarketStore(cache: cache) {
            if shouldFail { throw URLError(.timedOut) }
            return fresh
        }
        await store.load()
        #expect(store.isShowingCachedData)
        shouldFail = false
        await store.refresh()
        #expect(store.markets == fresh)
        #expect(store.isShowingCachedData == false)
    }
}

// MARK: - Grouping

struct GroupingTests {
    let markets = [
        Fixture.market("Zeta", borough: "Staten Island", address: "9 Harbor Rd."),
        Fixture.market("Beta", borough: "Brooklyn", address: "2 Atlantic Ave."),
        Fixture.market("Alpha", borough: "Brooklyn", address: "1 Atlantic Ave."),
        Fixture.market("Gamma", borough: "Manhattan", address: "5th Ave."),
        Fixture.market("Mystery", borough: "Unknown", address: "?"),
    ]

    @Test func fixedBoroughOrderAndSortedMarkets() {
        let sections = MarketGrouping.sections(from: markets)
        #expect(sections.map(\.borough) == ["Manhattan", "Brooklyn", "Staten Island", "Unknown"])
        #expect(sections[1].markets.map(\.name) == ["Alpha", "Beta"])
    }

    @Test func searchIsCaseInsensitiveAndHidesEmptySections() {
        let byName = MarketGrouping.sections(from: markets, query: "gAmMa")
        #expect(byName.map(\.borough) == ["Manhattan"])

        let byAddress = MarketGrouping.sections(from: markets, query: "atlantic")
        #expect(byAddress.map(\.borough) == ["Brooklyn"])
        #expect(byAddress[0].markets.count == 2)

        let byBorough = MarketGrouping.sections(from: markets, query: "staten")
        #expect(byBorough.map(\.borough) == ["Staten Island"])
    }

    @Test func noMatchGivesNoSections() {
        #expect(MarketGrouping.sections(from: markets, query: "zzz").isEmpty)
    }
}

// MARK: - Favorites

@MainActor
struct FavoritesTests {
    private func makeDefaults() -> UserDefaults {
        let name = "favorites-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func toggleOnAndOff() {
        let store = FavoritesStore(defaults: makeDefaults())
        let market = Fixture.market("A")
        #expect(store.isFavorite(market) == false)
        store.toggle(market)
        #expect(store.isFavorite(market))
        store.toggle(market)
        #expect(store.isFavorite(market) == false)
    }

    @Test func persistsAcrossInstances() {
        let defaults = makeDefaults()
        let market = Fixture.market("A")
        FavoritesStore(defaults: defaults).toggle(market)
        #expect(FavoritesStore(defaults: defaults).isFavorite(market))
        let again = FavoritesStore(defaults: defaults)
        again.remove(market)
        #expect(FavoritesStore(defaults: defaults).isFavorite(market) == false)
    }

    @Test func resolvedListIsSortedAndSkipsUnknownIDs() {
        let defaults = makeDefaults()
        let store = FavoritesStore(defaults: defaults)
        let b = Fixture.market("Beta"), a = Fixture.market("Alpha"), gone = Fixture.market("Gone")
        [b, a, gone].forEach(store.toggle)

        let resolved = store.favorites(in: [a, b, Fixture.market("Other")])
        #expect(resolved.map(\.name) == ["Alpha", "Beta"])
        // The missing market's ID is still stored.
        #expect(store.isFavorite(gone))
    }
}

// MARK: - Theme

struct ThemeTests {
    @Test func textContrastMeetsAA() {
        let pairs: [(String, ColorToken, ColorToken)] = [
            ("text/background", AppPalette.textPrimary, AppPalette.background),
            ("text/card", AppPalette.textPrimary, AppPalette.card),
            ("text/cardSelected", AppPalette.textPrimary, AppPalette.cardSelected),
            ("text/sectionHeader", AppPalette.textPrimary, AppPalette.sectionHeader),
            ("secondaryText/background", AppPalette.textSecondary, AppPalette.background),
            ("secondaryText/card", AppPalette.textSecondary, AppPalette.card),
            ("accent/background", AppPalette.accent, AppPalette.background),
            ("accent/card", AppPalette.accent, AppPalette.card),
            ("onAccentFill/accentFill", AppPalette.onAccentFill, AppPalette.accentFill),
        ]
        for (name, foreground, background) in pairs {
            for isDark in [false, true] {
                let ratio = AppPalette.contrast(foreground.hex(isDark: isDark), background.hex(isDark: isDark))
                #expect(ratio >= 4.5, "\(name) \(isDark ? "dark" : "light") contrast \(ratio)")
            }
        }
    }

    @Test func basePaletteMatchesDesign() {
        #expect(AppPalette.Base.primary == 0xC7D93D)
        #expect(AppPalette.Base.secondary == 0x98A62E)
        #expect(AppPalette.Base.deep == 0x525919)
        #expect(AppPalette.Base.highlight == 0xE6F28D)
        #expect(AppPalette.Base.surface == 0xF2F2F2)
    }

    #if canImport(UIKit)
    @MainActor
    @Test func everyIconResolves() {
        for icon in AppIcon.allCases {
            switch icon.source {
            case .symbol(let name):
                #expect(UIImage(systemName: name) != nil, "Missing SF Symbol \(name) for \(icon)")
            case .asset(let name):
                #expect(UIImage(named: name) != nil, "Missing asset \(name) for \(icon)")
            }
        }
    }
    #endif
}
