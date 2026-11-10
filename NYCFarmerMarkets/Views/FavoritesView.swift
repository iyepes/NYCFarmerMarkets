//
//  FavoritesView.swift
//  NYCFarmerMarkets
//

import SwiftUI

/// Tab 3: favorited markets. Tap for details, swipe to remove.
struct FavoritesView: View {
    @Environment(MarketStore.self) private var store
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        NavigationStack {
            content
                .offlineBanner(store.isShowingCachedData)
                .themedBackground()
                .navigationTitle("Favorites")
        }
    }

    @ViewBuilder
    private var content: some View {
        let items = favorites.favorites(in: store.markets)
        if items.isEmpty {
            ContentUnavailableView {
                Label {
                    Text("No haunts yet")
                        .appFont(.bodyEmphasis)
                } icon: {
                    IconView(.favoriteOff, size: 48)
                }
                .foregroundStyle(AppPalette.textPrimary.color)
            } description: {
                Text("Favorite a market to summon it here.")
                    .appFont(.body)
                    .foregroundStyle(AppPalette.textSecondary.color)
            }
            .accessibilityIdentifier("favorites-empty")
        } else {
            List {
                ForEach(items) { market in
                    Button {
                        store.selectedMarket = market
                    } label: {
                        MarketRow(market: market, showsBorough: true, titleRole: .favoriteItemTitle)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(AppPalette.card.color)
                    .listRowSeparatorTint(AppPalette.separator.color)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            favorites.remove(market)
                        } label: {
                            Label {
                                Text("Remove").appFont(.bodyEmphasis)
                            } icon: {
                                AppIcon.remove.image
                            }
                        }
                    }
                    .accessibilityAction(named: "Remove from favorites") {
                        favorites.remove(market)
                    }
                    .accessibilityIdentifier("favorite-row")
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .accessibilityIdentifier("favorites-list")
        }
    }
}
