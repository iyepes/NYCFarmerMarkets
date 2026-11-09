//
//  SingleMarketMap.swift
//  NYCFarmerMarkets
//

import Foundation
import MapKit

/// Pure logic for the in-app map that shows only the selected market.
nonisolated enum SingleMarketMap {
    /// One annotation on the single-market map.
    nonisolated struct Pin: Identifiable, Equatable, Sendable {
        let id: String
        let name: String
        let latitude: Double
        let longitude: Double

        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }

    /// Zoom level used to frame the single market.
    static let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)

    /// One pin for the market, or none when it has no coordinate.
    static func pins(for market: Market) -> [Pin] {
        guard let latitude = market.latitude, let longitude = market.longitude else { return [] }
        return [Pin(id: market.id, name: market.name, latitude: latitude, longitude: longitude)]
    }

    /// Region centered on the market, or nil when it has no coordinate.
    static func region(for market: Market) -> MKCoordinateRegion? {
        guard let coordinate = market.coordinate else { return nil }
        return MKCoordinateRegion(center: coordinate, span: span)
    }
}
