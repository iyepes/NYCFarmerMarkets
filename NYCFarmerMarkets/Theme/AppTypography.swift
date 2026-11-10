//
//  AppTypography.swift
//  NYCFarmerMarkets
//
//  Single point for fonts: two families, semantic roles, runtime registration
//  and a safe system-font fallback. Views use `.appFont(role)` only.
//

import SwiftUI
import CoreText
import OSLog

nonisolated enum AppTypography {

    /// The two font families bundled with the app.
    nonisolated enum Family: CaseIterable, Sendable {
        /// Grim Creeper: titles.
        case display
        /// Dr. Caligari: all other text.
        case body

        var postScriptName: String {
            switch self {
            case .display: "Grim-Creeper-Regular"
            case .body: "Dr.Caligari"
            }
        }

        var fileName: String {
            switch self {
            case .display: "Grim Creeper.ttf"
            case .body: "DrCaligari.ttf"
            }
        }

        /// Multiplier applied to a role's design size. Dr. Caligari has a small x-height and
        /// thin strokes, so it needs about 15% more size to read like the system text.
        var sizeScale: CGFloat {
            switch self {
            case .display: 1
            case .body: 1.15
            }
        }

        /// Smallest point size (at the default Dynamic Type size) this family may be drawn at.
        var minimumSize: CGFloat {
            switch self {
            case .display: 0
            case .body: 14
            }
        }
    }

    /// Semantic text roles.
    nonisolated enum Role: CaseIterable, Sendable {
        // Display family (title roles)
        case splash
        case splashHint
        case tabTitle
        case tabBarLabel
        case navigationTitle
        case detailTitle
        case favoriteItemTitle
        // Body family
        case body
        case bodyEmphasis
        case subheadline
        case sectionHeader
        case caption
        case footnote

        var family: Family {
            switch self {
            case .splash, .splashHint, .tabTitle, .tabBarLabel, .navigationTitle,
                 .detailTitle, .favoriteItemTitle:
                .display
            case .body, .bodyEmphasis, .subheadline, .sectionHeader, .caption, .footnote:
                .body
            }
        }

        /// Point size at the default Dynamic Type size.
        var size: CGFloat {
            switch self {
            case .splash: 26
            case .splashHint: 22
            case .tabTitle: 34
            case .tabBarLabel: 12
            case .navigationTitle: 20
            case .detailTitle: 30
            case .favoriteItemTitle: 20
            case .body: 17
            case .bodyEmphasis: 17
            case .subheadline: 15
            case .sectionHeader: 15
            case .caption: 12
            case .footnote: 13
            }
        }

        /// Size actually used with the custom font: the design size times the family's scale,
        /// never below the family's minimum. The system-font fallback keeps `size`.
        var effectiveSize: CGFloat {
            max(size * family.sizeScale, family.minimumSize)
        }

        /// Text style the size scales with.
        var textStyle: Font.TextStyle {
            switch self {
            case .splash: .title2
            case .splashHint: .title3
            case .tabTitle: .largeTitle
            case .tabBarLabel: .caption2
            case .navigationTitle: .headline
            case .detailTitle: .title
            case .favoriteItemTitle: .headline
            case .body: .body
            case .bodyEmphasis: .headline
            case .subheadline: .subheadline
            case .sectionHeader: .subheadline
            case .caption: .caption
            case .footnote: .footnote
            }
        }

        /// Weight used only by the system-font fallback.
        var fallbackWeight: Font.Weight {
            switch self {
            case .splash, .detailTitle, .sectionHeader: .bold
            case .splashHint, .tabTitle, .tabBarLabel, .navigationTitle,
                 .favoriteItemTitle, .bodyEmphasis: .semibold
            case .footnote: .medium
            case .body, .subheadline, .caption: .regular
            }
        }

        var font: Font {
            AppTypography.font(for: self)
        }
    }

    /// What a role resolves to, independent of SwiftUI.
    nonisolated enum Resolved: Equatable, Sendable {
        case custom(name: String, size: CGFloat, relativeTo: Font.TextStyle)
        case system(Font.TextStyle, Font.Weight)
    }

    nonisolated struct Registration: Sendable {
        let availableFamilies: Set<Family>
    }

    /// Pure mapping from role to font description.
    static func resolvedFont(for role: Role, isAvailable: (Family) -> Bool) -> Resolved {
        if isAvailable(role.family) {
            return .custom(name: role.family.postScriptName, size: role.effectiveSize, relativeTo: role.textStyle)
        }
        return .system(role.textStyle, role.fallbackWeight)
    }

    /// True when CoreText resolves a font with exactly this PostScript name.
    static func isAvailable(postScriptName: String) -> Bool {
        let font = CTFontCreateWithName(postScriptName as CFString, 12, nil)
        return CTFontCopyPostScriptName(font) as String == postScriptName
    }

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "NYCFarmerMarkets",
        category: "typography"
    )

    private static let registration: Registration = register()

    /// Registers the bundled fonts for this process. Runs once; safe to call repeatedly.
    @discardableResult
    static func registerFonts() -> Registration {
        registration
    }

    private static func register() -> Registration {
        let urls = (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [])
            + (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "fonts") ?? [])
        var seen = Set<String>()
        var available = Set<Family>()

        for family in Family.allCases {
            if let url = urls.first(where: { $0.lastPathComponent == family.fileName }),
               seen.insert(family.fileName).inserted {
                var error: Unmanaged<CFError>?
                if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                    let cfError = error?.takeRetainedValue()
                    let code = cfError.map { CFErrorGetCode($0) } ?? 0
                    let alreadyRegistered = code == CTFontManagerError.alreadyRegistered.rawValue
                        || code == CTFontManagerError.duplicatedName.rawValue
                    if !alreadyRegistered {
                        logger.error("Could not register \(family.fileName, privacy: .public): error code \(code)")
                    }
                }
            } else if !seen.contains(family.fileName) {
                logger.error("Font file missing from bundle: \(family.fileName, privacy: .public)")
            }
            if isAvailable(postScriptName: family.postScriptName) {
                available.insert(family)
            } else {
                logger.error("Font not available: \(family.postScriptName, privacy: .public)")
            }
        }
        return Registration(availableFamilies: available)
    }

    fileprivate static func font(for role: Role) -> Font {
        let available = registration.availableFamilies
        switch resolvedFont(for: role, isAvailable: { available.contains($0) }) {
        case let .custom(name, size, style):
            return .custom(name, size: size, relativeTo: style)
        case let .system(style, weight):
            return .system(style, design: .default, weight: weight)
        }
    }
}

extension View {
    /// Applies a typography role. Views use this instead of `.font(...)`.
    func appFont(_ role: AppTypography.Role) -> some View {
        font(role.font)
    }
}
