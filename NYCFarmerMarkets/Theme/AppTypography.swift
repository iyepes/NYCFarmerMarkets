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
        /// Black Chancery (public domain): all other text.
        case body

        var postScriptName: String {
            switch self {
            case .display: "Grim-Creeper-Regular"
            case .body: "BlackChancery"
            }
        }

        var fileName: String {
            switch self {
            case .display: "Grim Creeper.ttf"
            case .body: "BLKCHCRY.TTF"
            }
        }

        /// Multiplier applied to a role's design size. The 1.15 scale and the 14 pt floor below are
        /// carried over from the previous body font; checking them on screen with Black Chancery is
        /// still open.
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
        case sectionHeader
        case favoriteItemTitle
        // Body family
        case body
        case bodyEmphasis
        case subheadline
        case caption
        case footnote

        var family: Family {
            switch self {
            case .splash, .splashHint, .tabTitle, .sectionHeader, .tabBarLabel, .navigationTitle,
                 .detailTitle, .favoriteItemTitle:
                .display
            case .body, .bodyEmphasis, .subheadline, .caption, .footnote:
                .body
            }
        }

        /// Point size at the default Dynamic Type size.
        var size: CGFloat {
            switch self {
            case .splash: 44
            case .splashHint: 22
            case .tabTitle: 34
            case .tabBarLabel: 12
            case .navigationTitle: 20
            case .detailTitle: 30
            case .favoriteItemTitle: 20
            case .body: 17
            case .bodyEmphasis: 17
            case .subheadline: 15
            case .sectionHeader: 30
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

    /// First URL whose file name equals `fileName`, ignoring case (the bundle may hold `.TTF` or `.ttf`).
    nonisolated static func fontURL(named fileName: String, in urls: [URL]) -> URL? {
        urls.first { $0.lastPathComponent.caseInsensitiveCompare(fileName) == .orderedSame }
    }

    /// Font file candidates in the bundle root and `fonts/`, for `ttf` and `TTF`, without duplicate paths.
    nonisolated static func bundledFontURLs(in bundle: Bundle) -> [URL] {
        var paths = Set<String>()
        var result: [URL] = []
        for ext in ["ttf", "TTF"] {
            for subdirectory in [nil, "fonts"] as [String?] {
                for url in bundle.urls(forResourcesWithExtension: ext, subdirectory: subdirectory) ?? []
                where paths.insert(url.standardizedFileURL.path).inserted {
                    result.append(url)
                }
            }
        }
        return result
    }

    private static func register() -> Registration {
        let urls = bundledFontURLs(in: .main)
        var seen = Set<String>()
        var available = Set<Family>()

        for family in Family.allCases {
            if let url = fontURL(named: family.fileName, in: urls),
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
