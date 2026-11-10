//
//  ThemeStyling.swift
//  NYCFarmerMarkets
//
//  Reusable styling built from AppPalette tokens, and global appearance.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension View {
    /// Screen background using the theme.
    func themedBackground() -> some View {
        background(AppPalette.background.color.ignoresSafeArea())
    }

    /// Rounded card surface.
    func themedCard(selected: Bool = false) -> some View {
        padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill((selected ? AppPalette.cardSelected : AppPalette.card).color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppPalette.separator.color.opacity(0.5), lineWidth: 1)
            )
    }
}

/// Filled button in the accent color.
struct ThemedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appFont(.bodyEmphasis)
            .foregroundStyle(AppPalette.onAccentFill.color)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(AppPalette.accentFill.color))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

enum ThemeAppearance {
    /// Applies the palette to bars. Call once at launch.
    static func apply() {
        #if canImport(UIKit) && !os(visionOS)
        let background = AppPalette.background.platformColor
        let accent = AppPalette.accent.platformColor
        let muted = AppPalette.textSecondary.platformColor

        // Navigation bars keep the system look (it follows the screen background);
        // only the tint comes from the palette.
        UINavigationBar.appearance().tintColor = accent

        let tabBarFont = AppTypography.uiFont(.tabBarLabel)
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = background
        for item in [tab.stackedLayoutAppearance, tab.inlineLayoutAppearance, tab.compactInlineLayoutAppearance] {
            item.selected.iconColor = accent
            item.selected.titleTextAttributes = [.foregroundColor: accent, .font: tabBarFont]
            item.normal.iconColor = muted
            item.normal.titleTextAttributes = [.foregroundColor: muted, .font: tabBarFont]
        }
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        applyFonts()
        observeContentSizeChanges()
        #endif
    }

    #if canImport(UIKit) && !os(visionOS)
    /// Fonts of the navigation bar and search field. Re-run when the text size changes.
    private static func applyFonts() {
        // No configureWith...: only the fonts are set, so the system bar look is unchanged.
        let nav = UINavigationBarAppearance()
        nav.largeTitleTextAttributes = [.font: AppTypography.uiFont(.tabTitle)]
        nav.titleTextAttributes = [.font: AppTypography.uiFont(.navigationTitle)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav

        UISearchTextField.appearance().font = AppTypography.uiFont(.body)
    }

    private static var contentSizeObserver: NSObjectProtocol?

    private static func observeContentSizeChanges() {
        guard contentSizeObserver == nil else { return }
        contentSizeObserver = NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { applyFonts() }
        }
    }
    #endif
}
