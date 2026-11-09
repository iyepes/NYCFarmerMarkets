//
//  SingleMarketMapTests.swift
//  NYCFarmerMarketsTests
//

import MapKit
import Testing
@testable import NYCFarmerMarkets

struct SingleMarketMapTests {
    @Test func pinMatchesMarket() {
        let market = Fixture.market("Alpha", lat: 40.7, lon: -74.0)
        let pins = SingleMarketMap.pins(for: market)
        #expect(pins.count == 1)
        #expect(pins.first?.id == market.id)
        #expect(pins.first?.name == "Alpha")
        #expect(pins.first?.latitude == 40.7)
        #expect(pins.first?.longitude == -74.0)
    }

    @Test func noPinsWithoutCoordinates() {
        #expect(SingleMarketMap.pins(for: Fixture.market("A", lat: nil, lon: nil)).isEmpty)
    }

    @Test func noPinsWithOnlyOneCoordinate() {
        #expect(SingleMarketMap.pins(for: Fixture.market("A", lat: 40.7, lon: nil)).isEmpty)
        #expect(SingleMarketMap.pins(for: Fixture.market("B", lat: nil, lon: -74.0)).isEmpty)
    }

    @Test func regionCenteredOnMarket() {
        let region = SingleMarketMap.region(for: Fixture.market("A", lat: 40.7, lon: -74.0))
        #expect(region?.center.latitude == 40.7)
        #expect(region?.center.longitude == -74.0)
        #expect(region?.span.latitudeDelta == SingleMarketMap.span.latitudeDelta)
        #expect(region?.span.longitudeDelta == SingleMarketMap.span.longitudeDelta)
    }

    @Test func noRegionWithoutCoordinate() {
        #expect(SingleMarketMap.region(for: Fixture.market("A", lat: nil, lon: nil)) == nil)
    }
}
