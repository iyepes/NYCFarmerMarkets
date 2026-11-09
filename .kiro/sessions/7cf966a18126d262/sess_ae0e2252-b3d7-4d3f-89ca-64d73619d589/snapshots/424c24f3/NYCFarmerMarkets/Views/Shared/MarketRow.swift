//
//  MarketRow.swift
//  NYCFarmerMarkets
//

import SwiftUI

/// Row used by the Markets and Favorites lists.
struct MarketRow: View {
    let market: Market
    var showsBorough = false

    @Environment(FavoritesStore.self) private var favorites

    private var isFavorite: Bool { favorites.isFavorite(market) }

    private var subtitle: String {
        [showsBorough ? market.borough : nil, market.address.isEmpty ? nil : market.address]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            IconView(.tabMarkets, size: 28)
                .foregroundStyle(AppPalette.accent.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(market.name)
                    .font(.headline)
                    .foregroundStyle(AppPalette.textPrimary.color)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.textSecondary.color)
                }
                if let days = market.daysOfOperation {
                    Text(days)
                        .font(.caption)
                        .foregroundStyle(AppPalette.textSecondary.color)
                }
            }

            Spacer(minLength: 8)

            if isFavorite {
                IconView(.favoriteOn, size: 20)
                    .foregroundStyle(AppPalette.accent.color)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityText: String {
        var parts = [market.name]
        if !subtitle.isEmpty { parts.append(subtitle) }
        if let days = market.daysOfOperation { parts.append(days) }
        if isFavorite { parts.append("Favorite") }
        return parts.joined(separator: ", ")
    }
}
