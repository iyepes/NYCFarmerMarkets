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
    @State private var showsMap = false

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
                        VStack(spacing: 10) {
                            Button {
                                showsMap = true
                            } label: {
                                Label {
                                    Text("Open in Maps")
                                } icon: {
                                    IconView(.openInMaps, size: 18)
                                }
                            }
                            .buttonStyle(ThemedButtonStyle())
                            .accessibilityIdentifier("open-in-maps")

                            Button {
                                openInExternalMaps()
                            } label: {
                                Label {
                                    Text("Directions")
                                } icon: {
                                    IconView(.directions, size: 18)
                                }
                            }
                            .buttonStyle(ThemedButtonStyle())
                            .accessibilityIdentifier("look-for-directions")
                        }
                    }
                }
                .padding()
            }
            .themedBackground()
            .navigationDestination(isPresented: $showsMap) {
                MarketLocationMapView(market: market, onClose: { dismiss() })
            }
            .navigationTitle("Market details")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { MarketDetailToolbar(market: market, onClose: { dismiss() }) }
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

    private func openInExternalMaps() {
        guard let coordinate = market.coordinate else { return }
        let item = MKMapItem(
            location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
            address: nil
        )
        item.name = market.name
        item.openInMaps()
    }
}
