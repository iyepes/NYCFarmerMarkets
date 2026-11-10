//
//  AppTypography+UIKit.swift
//  NYCFarmerMarkets
//
//  UIKit fonts for system-rendered bars (tab bar, navigation bar, search field).
//

#if canImport(UIKit) && !os(visionOS)
import SwiftUI
import UIKit

extension AppTypography {
    /// Dynamic Type scaled UIFont for a role; system font if the family is unavailable.
    static func uiFont(_ role: Role) -> UIFont {
        let base = registerFonts().availableFamilies.contains(role.family)
            ? UIFont(name: role.family.postScriptName, size: role.size) : nil
        let font = base ?? UIFont.systemFont(ofSize: role.size, weight: role.uiFallbackWeight)
        return UIFontMetrics(forTextStyle: role.uiTextStyle).scaledFont(for: font)
    }
}

extension AppTypography.Role {
    nonisolated var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .splash: .title2
        case .splashHint: .title3
        case .tabTitle: .largeTitle
        case .tabBarLabel: .caption2
        case .navigationTitle: .headline
        case .detailTitle: .title1
        case .favoriteItemTitle: .headline
        case .body: .body
        case .bodyEmphasis: .headline
        case .subheadline: .subheadline
        case .sectionHeader: .subheadline
        case .caption: .caption1
        case .footnote: .footnote
        }
    }

    nonisolated fileprivate var uiFallbackWeight: UIFont.Weight {
        switch fallbackWeight {
        case .bold: .bold
        case .semibold: .semibold
        case .medium: .medium
        default: .regular
        }
    }
}
#endif
