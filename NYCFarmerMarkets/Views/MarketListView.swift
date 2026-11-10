//
//  MarketListView.swift
//  NYCFarmerMarkets
//

import SwiftUI

/// Tab 1: searchable list of markets grouped by borough.
struct MarketListView: View {
    @Environment(MarketStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var expansion = SectionExpansionState()

    private var query: String { store.searchQuery }

    private var sections: [BoroughSection] {
        MarketGrouping.sections(from: store.markets, query: query)
    }

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            content
                .offlineBanner(store.isShowingCachedData)
                .themedBackground()
                .navigationTitle("Markets")
                .searchable(text: $store.searchQuery, prompt: AppCopy.searchPrompt)
                .onChange(of: SectionExpansionState.isSearching(query)) { _, searching in
                    if !searching { expansion.endSearch() }
                }
        }
        // The system search field keeps its old height when the text size changes while the app
        // is running (its icon and prompt get clipped). Rebuilding the navigation container on a
        // size change gives it a fresh search field. The query lives in the store and the
        // expanded sections in this view's state, so both are kept.
        .id(dynamicTypeSize)
    }

    @ViewBuilder
    private var content: some View {
        let sections = sections
        if sections.isEmpty {
            ContentUnavailableView {
                Label {
                    Text(AppCopy.noResultsTitle)
                        .appFont(.bodyEmphasis)
                        .accessibilityLabel(AppCopy.noResultsTitleAccessibility)
                        .accessibilityIdentifier("search-no-results-title")
                } icon: {
                    IconView(.emptySearch, size: 40)
                }
                .foregroundStyle(AppPalette.textPrimary.color)
            } description: {
                Text(AppCopy.noResultsHint(query: query))
                    .appFont(.body)
                    .foregroundStyle(AppPalette.textSecondary.color)
            }
        } else {
            List {
                ForEach(sections) { section in
                    Section {
                        if expansion.isExpanded(section.borough, query: query) {
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
        let isExpanded = expansion.isExpanded(section.borough, query: query)
        let count = section.markets.count
        return Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                expansion.toggle(section.borough, query: query)
            }
        } label: {
            HStack {
                Text(section.borough)
                    .appFont(.sectionHeader)
                Spacer()
                Text("\(count)")
                    .appFont(.caption)
                IconView(.sectionChevron, size: 12)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .textCase(nil)
            .foregroundStyle(AppPalette.textPrimary.color)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(AppPalette.sectionHeader.color)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(SectionHeaderAccessibility.label(borough: section.borough, count: count))
        .accessibilityValue(SectionHeaderAccessibility.value(isExpanded: isExpanded))
        .accessibilityHint(SectionHeaderAccessibility.hint(isExpanded: isExpanded))
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier(SectionHeaderAccessibility.identifier(borough: section.borough))
    }
}
