//
//  AppIcon.swift
//  NYCFarmerMarkets
//
//  Registry of every icon used in the UI. Swap an icon here and it changes
//  everywhere. Views must not use raw SF Symbol names.
//

import SwiftUI

nonisolated enum AppIcon: String, CaseIterable, Sendable {
    case tabMarkets
    case tabMap
    case tabFavorites
    case favoriteOn
    case favoriteOff
    case mapPin
    case ebt
    case yearRound
    case hours
    case location
    case district
    case cooking
    case year
    case close
    case remove
    case openInMaps
    case offline
    case warning
    case emptySearch

    enum Source: Equatable, Sendable {
        case symbol(String)
        case asset(String)
    }

    var source: Source {
        switch self {
        case .tabMarkets: .asset("icon-pumpkin")
        case .tabMap: .symbol("moon.stars.fill")
        case .tabFavorites: .asset("icon-ghost-filled")
        case .favoriteOn: .asset("icon-ghost-filled")
        case .favoriteOff: .asset("icon-ghost-outline")
        case .mapPin: .asset("icon-bat")
        case .ebt: .symbol("sparkles")
        case .yearRound: .symbol("moon.fill")
        case .hours: .symbol("hourglass")
        case .location: .symbol("mappin.circle.fill")
        case .district: .symbol("eye.fill")
        case .cooking: .symbol("flame.fill")
        case .year: .symbol("calendar")
        case .close: .symbol("xmark.circle.fill")
        case .remove: .symbol("trash.fill")
        case .openInMaps: .symbol("map.fill")
        case .offline: .symbol("cloud.fog.fill")
        case .warning: .symbol("exclamationmark.triangle.fill")
        case .emptySearch: .symbol("eyes")
        }
    }

    /// Template image at its natural size (used by tab bars and labels).
    var image: Image {
        switch source {
        case .symbol(let name): Image(systemName: name)
        case .asset(let name): Image(name).renderingMode(.template)
        }
    }

    /// Plain-language name for accessibility.
    var accessibilityName: String {
        switch self {
        case .tabMarkets: "Markets"
        case .tabMap: "Map"
        case .tabFavorites: "Favorites"
        case .favoriteOn: "Favorite"
        case .favoriteOff: "Not a favorite"
        case .mapPin: "Market"
        case .ebt: "EBT"
        case .yearRound: "Open year round"
        case .hours: "Hours"
        case .location: "Address"
        case .district: "Community district"
        case .cooking: "Cooking permitted"
        case .year: "Year"
        case .close: "Close"
        case .openInMaps: "Open in Maps"
        case .offline: "Offline"
        case .warning: "Warning"
        case .emptySearch: "No results"
        }
    }
}

/// Renders an `AppIcon` at a fixed point size, tinted by the foreground style.
struct IconView: View {
    let icon: AppIcon
    var size: CGFloat = 18

    init(_ icon: AppIcon, size: CGFloat = 18) {
        self.icon = icon
        self.size = size
    }

    var body: some View {
        Group {
            switch icon.source {
            case .symbol(let name):
                Image(systemName: name)
                    .font(.system(size: size))
            case .asset(let name):
                Image(name)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            }
        }
        .accessibilityHidden(true)
    }
}
