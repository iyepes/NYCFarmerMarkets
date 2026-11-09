//
//  MarketLocationMapView.swift
//  NYCFarmerMarkets
//

import SwiftUI
import MapKit

/// Pushed from the detail screen: the in-app map showing only the selected market.
struct MarketLocationMapView: View {
    let market: Market
    let onClose: () -> Void

    @Environment(FavoritesStore.self) private var favorites
    @State private var position: MapCameraPosition

    init(market: Market, onClose: @escaping () -> Void) {
        self.market = market
        self.onClose = onClose
        _position = State(
            initialValue: SingleMarketMap.region(for: market).map { MapCameraPosition.region($0) } ?? .automatic
        )
    }

    var body: some View {
        ZStack {
            Map(position: $position) {
                ForEach(SingleMarketMap.pins(for: market)) { pin in
                    Annotation(pin.name, coordinate: pin.coordinate, anchor: .center) {
                        MarketPin(
                            name: pin.name,
                            isFavorite: favorites.isFavorite(market),
                            isSelected: false,
                            identifier: "selected-market-pin"
                        )
                    }
                }
            }
            .mapStyle(.standard)
        }
        .accessibilityIdentifier("market-location-map")
        .navigationTitle(market.name)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar { MarketDetailToolbar(market: market, onClose: onClose) }
    }
}
