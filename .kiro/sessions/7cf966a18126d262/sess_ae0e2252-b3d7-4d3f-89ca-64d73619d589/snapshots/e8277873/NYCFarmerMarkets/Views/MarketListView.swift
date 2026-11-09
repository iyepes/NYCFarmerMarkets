//
//  MarketListView.swift
//  NYCFarmerMarkets
//

import SwiftUI

/// Tab 1: searchable list of markets grouped by borough.
struct MarketListView: View {
    @Environment(MarketStore.self) private var store
    @State private var query = ""

    private var sections: [BoroughSection] {
        MarketGrouping.sections(from: store.markets, query: query)
    }

    var body: some View {
        NavigationStack {
            content
                .themedBackground()
                .navigationTitle("Markets")
                .searchable(text: $query, prompt: "Search name, address or borough")
                .offlineBanner(store.isShowingCachedData)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .idle, .loading where store.markets.isEmpty:
            ProgressView("Summoning markets…")
                .tint(AppPalette.accent.color)
                .foregroundStyle(AppPalette.textSecondary.color)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .error(let message) where store.markets.isEmpty:
            LoadErrorView(message: message) { Task { await store.refresh() } }
        default:
            list
        }
    }

    @ViewBuilder
    private var list: some View {
        let sections = sections
        if sections.isEmpty {
            ContentUnavailableView {
                Label {
                    Text("No markets found")
                } icon: {
                    IconView(.emptySearch, size: 40)
                }
                .foregroundStyle(AppPalette.textPrimary.color)
            } description: {
                Text("Nothing matches “\(query)”.")
                    .foregroundStyle(AppPalette.textSecondary.color)
            }
        } else {
            List {
                ForEach(sections) { section in
                    Section {
                        ForEach(section.markets) { market in
                            Button {
                                store.selectedMarket = market
                            } label: {
                                MarketRow(market: market)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(AppPalette.card.color)
                            .listRowSeparatorTint(AppPalette.separator.color)
                            .accessibilityIdentifier("market-row")
                        }
                    } header: {
                        sectionHeader(section)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .refreshable { await store.refresh() }
            .accessibilityIdentifier("market-list")
        }
    }

    private func sectionHeader(_ section: BoroughSection) -> some View {
        HStack {
            Text(section.borough)
                .font(.subheadline.weight(.bold))
            Spacer()
            Text("\(section.markets.count)")
                .font(.caption.weight(.semibold))
        }
        .textCase(nil)
        .foregroundStyle(AppPalette.textPrimary.color)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(AppPalette.sectionHeader.color)
        .listRowInsets(EdgeInsets())
        .accessibilityAddTraits(.isHeader)
    }
}
