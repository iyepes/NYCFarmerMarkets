//
//  MarketPin.swift
//  NYCFarmerMarkets
//

import SwiftUI

/// Map annotation used by the Map tab and the single-market map.
struct MarketPin: View {
    let name: String
    let isFavorite: Bool
    let isSelected: Bool
    var identifier: String = "market-pin"

    var body: some View {
        IconView(isFavorite ? .favoriteOn : .mapPin, size: 14)
            .foregroundStyle(AppPalette.onAccentFill.color)
            .padding(6)
            .background(Circle().fill(AppPalette.accentFill.color))
            .overlay(
                Circle().strokeBorder(
                    AppPalette.textPrimary.color,
                    lineWidth: isFavorite ? 3 : 1.5
                )
            )
            .scaleEffect(isSelected ? 1.3 : 1)
            .animation(.snappy, value: isSelected)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isFavorite ? "\(name), favorite" : name)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier(identifier)
    }
}
