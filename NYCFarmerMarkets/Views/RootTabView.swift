//
//  RootTabView.swift
//  NYCFarmerMarkets
//

import SwiftUI

struct RootTabView: View {
    @Environment(MarketStore.self) private var store
    @Environment(SoundController.self) private var sounds

    private enum Tab: Hashable {
        case markets, map, favorites
    }

    @State private var selection: Tab = .markets
    @State private var hasAppeared = false

    var body: some View {
        @Bindable var store = store

        TabView(selection: $selection) {
            MarketListView()
                .tabItem {
                    Label { Text("Markets").appFont(.tabBarLabel) } icon: { AppIcon.tabMarkets.image }
                }
                .tag(Tab.markets)
            MarketMapView()
                .tabItem {
                    Label { Text("Map").appFont(.tabBarLabel) } icon: { AppIcon.tabMap.image }
                }
                .tag(Tab.map)
            FavoritesView()
                .tabItem {
                    Label { Text("Favorites").appFont(.tabBarLabel) } icon: { AppIcon.tabFavorites.image }
                }
                .tag(Tab.favorites)
        }
        .tint(AppPalette.accent.color)
        .sheet(item: $store.selectedMarket) { market in
            MarketDetailView(market: market)
        }
        .onAppear {
            // Once per launch: the tabs appear after the splash.
            guard !hasAppeared else { return }
            hasAppeared = true
            sounds.play(.door)
        }
        .onChange(of: selection) {
            // Reselecting the shown tab does not change `selection`, so it plays nothing.
            sounds.stopAllLoops()
            sounds.play(.door)
        }
        .onChange(of: store.selectedMarket?.id) { old, new in
            // A sheet does not trigger onDisappear of the tab behind it, so stop the loop here.
            guard old == nil, new != nil else { return }
            sounds.stopAllLoops()
            sounds.play(.doorAndHit)
        }
    }
}
