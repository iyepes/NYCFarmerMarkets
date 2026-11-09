//
//  MapFilterIndicator.swift
//  NYCFarmerMarkets
//

import SwiftUI

/// Banner on the map saying the pins are filtered by the list's search.
struct MapFilterIndicator: View {
    let query: String
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            IconView(.searchFilter, size: 16)
            Text(AppCopy.mapFilterSummary(query: query, count: count))
                .font(.footnote.weight(.medium))
        }
        .foregroundStyle(AppPalette.textPrimary.color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AppPalette.cardSelected.color)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(AppCopy.mapFilterAccessibility(query: query, count: count))
        .accessibilityIdentifier("map-filter-indicator")
    }
}
