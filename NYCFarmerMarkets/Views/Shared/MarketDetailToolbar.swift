//
//  MarketDetailToolbar.swift
//  NYCFarmerMarkets
//

import SwiftUI

/// Close and favorite items shared by the detail screen and the pushed map.
struct MarketDetailToolbar: ToolbarContent {
    let market: Market
    let onClose: () -> Void

    @Environment(FavoritesStore.self) private var favorites

    private var isFavorite: Bool { favorites.isFavorite(market) }

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                onClose()
            } label: {
                IconView(.close, size: 24)
            }
            .accessibilityLabel("Close")
            .accessibilityIdentifier("close-detail")
        }
        ToolbarItem(placement: .primaryAction) {
            Button {
                favorites.toggle(market)
            } label: {
                IconView(isFavorite ? .favoriteOn : .favoriteOff, size: 26)
                    .scaleEffect(isFavorite ? 1.1 : 1)
                    .animation(.spring(duration: 0.3), value: isFavorite)
            }
            .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
            .accessibilityIdentifier("favorite-toggle")
            .sensoryFeedback(.selection, trigger: isFavorite)
        }
    }
}
