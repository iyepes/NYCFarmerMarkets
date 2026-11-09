//
//  RootTabView.swift
//  NYCFarmerMarkets
//

import SwiftUI

struct RootTabView: View {
    @Environment(MarketStore.self) private var store

    var body: some View {
        @Bindable var store = store

        TabView {
            MarketListView()
                .tabItem {
                    Label { Text("Markets") } icon: { AppIcon.tabMarkets.image }
                }
            MarketMapView()
                .tabItem {
                    Label { Text("Map") } icon: { AppIcon.tabMap.image }
                }
            FavoritesView()
                .tabItem {
                    Label { Text("Favorites") } icon: { AppIcon.tabFavorites.image }
                }
        }
        .tint(AppPalette.accent.color)
        .sheet(item: $store.selectedMarket) { market in
            MarketDetailView(market: market)
        }
        .task { await store.load() }
    }
}
