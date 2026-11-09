//
//  MarketSearchTests.swift
//  NYCFarmerMarketsTests
//

import Foundation
import Testing
@testable import NYCFarmerMarkets

struct MarketSearchTests {
    private func markets() throws -> [Market] {
        try MarketService.parse(Data(Fixture.json.utf8)) + [Fixture.market("Café Verde", borough: "Queens", address: "7 Elm Rd.")]
    }

    @Test func emptyAndWhitespaceReturnAllInOrder() throws {
        let all = try markets()
        for query in ["", "   ", "\n\t "] {
            #expect(MarketSearch.filter(all, query: query) == all)
            #expect(MarketSearch.isActive(query) == false)
        }
    }

    @Test func matchesNameAddressAndBorough() throws {
        let all = try markets()
        #expect(MarketSearch.filter(all, query: "Zebra").map(\.name) == ["Zebra Market"])
        #expect(MarketSearch.filter(all, query: "W. 175th").map(\.name) == ["175th Street Greenmarket"])
        #expect(MarketSearch.filter(all, query: "Queens").map(\.name) == ["Café Verde"])
    }

    @Test func caseAndDiacriticInsensitive() throws {
        let all = try markets()
        #expect(MarketSearch.filter(all, query: "ZEBRA").map(\.name) == ["Zebra Market"])
        #expect(MarketSearch.filter(all, query: "cafe").map(\.name) == ["Café Verde"])
        #expect(MarketSearch.filter(all, query: "CAFÉ").map(\.name) == ["Café Verde"])
    }

    @Test func queryIsTrimmed() throws {
        let all = try markets()
        #expect(MarketSearch.filter(all, query: "  zebra \n") == MarketSearch.filter(all, query: "zebra"))
        #expect(MarketSearch.isActive("  zebra "))
        #expect(MarketSearch.normalized("  zebra \n") == "zebra")
    }

    @Test func noResults() throws {
        #expect(try MarketSearch.filter(markets(), query: "zzzz-no-match").isEmpty)
    }

    @Test func filterMatchesListGroupingResults() throws {
        let all = try markets()
        for query in ["", "market", "a", "queens", "cafe", " st ", "zzzz"] {
            let fromGrouping = Set(MarketGrouping.sections(from: all, query: query).flatMap(\.markets).map(\.id))
            let fromFilter = Set(MarketSearch.filter(all, query: query).map(\.id))
            #expect(fromFilter == fromGrouping, "query: \(query)")
        }
    }

    @Test func summaryText() {
        #expect(MarketSearch.summary(query: "kale", count: 0) == "Showing 0 results for \"kale\"")
        #expect(MarketSearch.summary(query: "kale", count: 1) == "Showing 1 result for \"kale\"")
        #expect(MarketSearch.summary(query: "kale", count: 5) == "Showing 5 results for \"kale\"")
        #expect(MarketSearch.summary(query: "  kale ", count: 2) == "Showing 2 results for \"kale\"")
    }

    @Test func expansionStateAgreesWithSharedRule() {
        for query in ["", " ", "\n", "a", " a ", "market"] {
            #expect(SectionExpansionState.isSearching(query) == MarketSearch.isActive(query))
        }
    }
}
