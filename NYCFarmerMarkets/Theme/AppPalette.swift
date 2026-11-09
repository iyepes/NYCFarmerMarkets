//
//  AppPalette.swift
//  NYCFarmerMarkets
//
//  Single source of truth for every color in the app.
//  Change the values in `AppPalette.Base` and the whole app is recolored.
//  Views must only use the semantic tokens below (never literal colors).
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A color with a light and a dark appearance, stored as 0xRRGGBB so it can
/// also be used for contrast calculations.
nonisolated struct ColorToken: Sendable {
    let light: Int
    let dark: Int

    init(light: Int, dark: Int) {
        self.light = light
        self.dark = dark
    }

    /// Same color in both appearances.
    init(_ both: Int) {
        self.init(light: both, dark: both)
    }

    func hex(isDark: Bool) -> Int { isDark ? dark : light }

    #if canImport(UIKit)
    var platformColor: UIColor {
        let light = self.light, dark = self.dark
        return UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        }
    }
    var color: Color { Color(uiColor: platformColor) }
    #elseif canImport(AppKit)
    var platformColor: NSColor {
        let light = self.light, dark = self.dark
        return NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light)
        }
    }
    var color: Color { Color(nsColor: platformColor) }
    #endif
}

nonisolated enum AppPalette {

    // MARK: Base values (the ONLY place hex literals live)

    enum Base {
        static let primary = 0xC7D93D
        static let secondary = 0x98A62E
        static let deep = 0x525919
        static let highlight = 0xE6F28D
        static let surface = 0xF2F2F2
        /// Olive used as the app icon background.
        static let appIconOlive = 0x78872B
    }

    // MARK: Semantic tokens

    /// Screen background.
    static let background = ColorToken(light: Base.surface, dark: mix(Base.deep, 0x000000, 0.45))
    /// Row / card background.
    static let card = ColorToken(light: mix(Base.highlight, Base.surface, 0.55), dark: Base.deep)
    /// Selected row / callout background.
    static let cardSelected = ColorToken(light: Base.highlight, dark: mix(Base.deep, Base.primary, 0.12))
    /// Main text.
    static let textPrimary = ColorToken(light: Base.deep, dark: Base.surface)
    /// Secondary text.
    static let textSecondary = ColorToken(light: mix(Base.deep, Base.surface, 0.1), dark: Base.highlight)
    /// Tint for controls, links, selected tab, favorite icon.
    static let accent = ColorToken(light: Base.deep, dark: Base.primary)
    /// Filled shapes in the primary color (pins, buttons).
    static let accentFill = ColorToken(Base.primary)
    /// Content drawn on top of `accentFill`.
    static let onAccentFill = ColorToken(Base.deep)
    /// Decorative secondary color (borders, dividers, minor glyphs).
    static let accentSecondary = ColorToken(Base.secondary)
    /// Section header background.
    static let sectionHeader = ColorToken(light: Base.highlight, dark: mix(Base.deep, Base.secondary, 0.25))
    /// Hairlines and separators.
    static let separator = ColorToken(Base.secondary)
    /// App icon background.
    static let appIconBackground = ColorToken(Base.appIconOlive)

    // MARK: Helpers

    /// Linear blend of two 0xRRGGBB values. `amount` 0 = a, 1 = b.
    static func mix(_ a: Int, _ b: Int, _ amount: Double) -> Int {
        func channel(_ shift: Int) -> Int {
            let ca = Double((a >> shift) & 0xFF)
            let cb = Double((b >> shift) & 0xFF)
            return Int((ca + (cb - ca) * amount).rounded())
        }
        return (channel(16) << 16) | (channel(8) << 8) | channel(0)
    }

    /// WCAG relative luminance of a 0xRRGGBB value.
    static func luminance(_ hex: Int) -> Double {
        func linear(_ v: Int) -> Double {
            let c = Double(v) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear((hex >> 16) & 0xFF)
            + 0.7152 * linear((hex >> 8) & 0xFF)
            + 0.0722 * linear(hex & 0xFF)
    }

    /// WCAG contrast ratio between two 0xRRGGBB values (1...21).
    static func contrast(_ a: Int, _ b: Int) -> Double {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }
}

// MARK: - Platform color from hex

#if canImport(UIKit)
nonisolated extension UIColor {
    convenience init(hex: Int) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
#elseif canImport(AppKit)
nonisolated extension NSColor {
    convenience init(hex: Int) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
#endif
