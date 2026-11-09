//
//  MarketMapView.swift
//  NYCFarmerMarkets
//

import SwiftUI
import MapKit

/// Tab 2: map with a pin per market. Selecting a pin shows a card with a
/// "More info" button that opens the shared detail sheet.
struct MarketMapView: View {
    @Environment(MarketStore.self) private var store
    @Environment(FavoritesStore.self) private var favorites

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
        )
    )
    @State private var selectedID: String?

    private var mappable: [Market] { store.markets.filter { $0.coordinate != nil } }

    private var selectedMarket: Market? {
        guard let selectedID else { return nil }
        return store.markets.first { $0.id == selectedID }
    }

    var body: some View {
        Map(position: $position, selection: $selectedID) {
            ForEach(mappable) { market in
                if let coordinate = market.coordinate {
                    Annotation(market.name, coordinate: coordinate, anchor: .bottom) {
                        MarketPin(
                            name: market.name,
                            isFavorite: favorites.isFavorite(market),
                            isSelected: market.id == selectedID
                        )
                    }
                    .tag(market.id)
                }
            }
        }
        .mapStyle(.standard)
        .safeAreaInset(edge: .bottom) {
            if let market = selectedMarket {
                MarketCard(market: market) { store.selectedMarket = market }
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: selectedID)
        .overlay(alignment: .top) {
            if store.isShowingCachedData { OfflineBanner() }
        }
        .overlay {
            if store.state == .loading && store.markets.isEmpty {
                ProgressView()
                    .tint(AppPalette.accent.color)
            }
        }
        .accessibilityIdentifier("market-map")
    }
}

private struct MarketCard: View {
    let market: Market
    let onMoreInfo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(market.name)
                    .font(.headline)
                    .foregroundStyle(AppPalette.textPrimary.color)
                Text(market.borough)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.textSecondary.color)
            }
            Spacer(minLength: 8)
            Button("More info", action: onMoreInfo)
                .buttonStyle(ThemedButtonStyle())
                .accessibilityIdentifier("more-info")
        }
        .themedCard(selected: true)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("map-card")
    }
}
