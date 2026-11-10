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
        // Fonts first: the bar appearance below needs them.
        AppTypography.registerFonts()
        ThemeAppearance.apply()

        // UI tests start from a clean slate.
        let options = LaunchOptions(arguments: ProcessInfo.processInfo.arguments)
        if options.resetFavorites {
            UserDefaults.standard.removeObject(forKey: "favoriteMarketIDs")
        }
        if options.failDownload {
            let emptyCache = MarketCache(
                fileURL: FileManager.default.temporaryDirectory
                    .appendingPathComponent("ui-testing-empty-cache-\(UUID().uuidString).json")
            )
            _marketStore = State(initialValue: MarketStore(cache: emptyCache) {
                throw URLError(.notConnectedToInternet)
            })
        } else {
            _marketStore = State(initialValue: MarketStore())
        }
        _favoritesStore = State(initialValue: FavoritesStore())
        splashMinimumDisplayTime = options.splashMinimumSeconds.map { .seconds($0) }
            ?? SplashDecision.minimumDisplayTime
    }

    private let splashMinimumDisplayTime: Duration

    var body: some Scene {
        WindowGroup {
            AppRootView(minimumDisplayTime: splashMinimumDisplayTime)
                .environment(marketStore)
                .environment(favoritesStore)
                .environment(\.font, AppTypography.Role.body.font)
        }
    }
}
