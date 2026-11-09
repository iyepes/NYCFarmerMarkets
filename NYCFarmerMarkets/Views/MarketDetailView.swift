//
//  MarketDetailView.swift
//  NYCFarmerMarkets
//

import SwiftUI
import MapKit

/// Detail sheet shared by the Markets, Map, and Favorites tabs.
struct MarketDetailView: View {
    let market: Market

    @Environment(\.dismiss) private var dismiss
    @Environment(FavoritesStore.self) private var favorites

    private var isFavorite: Bool { favorites.isFavorite(market) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    VStack(spacing: 10) {
                        detailRow(.location, "Address", market.address.isEmpty ? nil : market.address)
                        detailRow(.district, "Community district", market.communityDistrict)
                        detailRow(.hours, "Days", market.daysOfOperation)
                        detailRow(.hours, "Hours", market.hoursOfOperation)
                        detailRow(.ebt, "Accepts EBT", market.acceptsEBT)
                        detailRow(.yearRound, "Open year round", market.openYearRound)
                        detailRow(.cooking, "Health Dept. cooking", market.healthDeptCooking)
                        detailRow(.year, "Data year", market.year)
                    }
                    if market.coordinate != nil {
                        Button {
                            openInMaps()
                        } label: {
                            Label {
                                Text("Open in Maps")
                            } icon: {
                                IconView(.openInMaps, size: 18)
                            }
                        }
                        .buttonStyle(ThemedButtonStyle())
                        .accessibilityIdentifier("open-in-maps")
                    }
                }
                .padding()
            }
            .themedBackground()
            .navigationTitle("Market details")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
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
        .tint(AppPalette.accent.color)
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 520)
        #endif
        .accessibilityIdentifier("market-detail")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(market.name)
                .font(.title.bold())
                .foregroundStyle(AppPalette.textPrimary.color)
                .accessibilityAddTraits(.isHeader)
            Text(market.borough)
                .font(.title3)
                .foregroundStyle(AppPalette.textSecondary.color)
        }
    }

    private func detailRow(_ icon: AppIcon, _ title: String, _ value: String?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            IconView(icon, size: 20)
                .foregroundStyle(AppPalette.accent.color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppPalette.textSecondary.color)
                Text(value ?? "Not listed")
                    .font(.body)
                    .foregroundStyle(AppPalette.textPrimary.color)
            }
        }
        .themedCard()
        .accessibilityElement(children: .combine)
    }

    private func openInMaps() {
        guard let coordinate = market.coordinate else { return }
        let item = MKMapItem(
            location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
            address: nil
        )
        item.name = market.name
        item.openInMaps()
    }
}
