//
//  NYCFarmerMarketsApp.swift
//  NYCFarmerMarkets
//
//  Created by Isabel Yepes on 8/11/26.
//

import SwiftUI

@main
struct NYCFarmerMarketsApp: App {
    @State private var marketStore: MarketStore
    @State private var favoritesStore: FavoritesStore

    init() {
        ThemeAppearance.apply()

        // UI tests start from a clean slate.
        if ProcessInfo.processInfo.arguments.contains("-uiTestingReset") {
            UserDefaults.standard.removeObject(forKey: "favoriteMarketIDs")
        }
        _marketStore = State(initialValue: MarketStore())
        _favoritesStore = State(initialValue: FavoritesStore())
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(marketStore)
                .environment(favoritesStore)
        }
    }
}
