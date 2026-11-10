//
//  AppTypographyTests.swift
//  NYCFarmerMarketsTests
//

import Testing
import CoreText
import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
@testable import NYCFarmerMarkets

struct AppTypographyTests {

    @Test func postScriptNames() {
        #expect(AppTypography.Family.display.postScriptName == "Grim-Creeper-Regular")
        #expect(AppTypography.Family.body.postScriptName == "Breath-of-the-House")
    }

    @Test func bothFamiliesResolveAfterRegistration() {
        let registration = AppTypography.registerFonts()
        #expect(registration.availableFamilies == Set(AppTypography.Family.allCases))
        for family in AppTypography.Family.allCases {
            #expect(AppTypography.isAvailable(postScriptName: family.postScriptName))
            #if canImport(UIKit)
            #expect(UIFont(name: family.postScriptName, size: 12) != nil)
            #elseif canImport(AppKit)
            #expect(NSFont(name: family.postScriptName, size: 12) != nil)
            #endif
        }
    }

    @Test func unknownFontIsNotAvailable() {
        #expect(!AppTypography.isAvailable(postScriptName: "Not-A-Real-Font"))
    }

    @Test func rolesMapToIntendedFamily() {
        for role in AppTypography.Role.allCases {
            let expected: AppTypography.Family
            switch role {
            case .splash, .splashHint, .tabTitle, .tabBarLabel, .navigationTitle,
                 .detailTitle, .favoriteItemTitle:
                expected = .display
            case .body, .bodyEmphasis, .subheadline, .sectionHeader, .caption, .footnote:
                expected = .body
            }
            #expect(role.family == expected)
        }
    }

    @Test func availableFontResolvesToCustom() {
        for role in AppTypography.Role.allCases {
            let resolved = AppTypography.resolvedFont(for: role, isAvailable: { _ in true })
            #expect(resolved == .custom(name: role.family.postScriptName, size: role.effectiveSize, relativeTo: role.textStyle))
        }
    }

    @Test func bodyRolesAreScaledAndNeverBelowTheMinimum() {
        for role in AppTypography.Role.allCases where role.family == .body {
            #expect(role.effectiveSize >= AppTypography.Family.body.minimumSize)
            #expect(role.effectiveSize >= role.size * AppTypography.Family.body.sizeScale)
        }
        // Spot checks that document the intended numbers: 17 pt body becomes 19.55 pt,
        // and the 12 pt caption is lifted to the 14 pt floor.
        #expect(abs(AppTypography.Role.body.effectiveSize - 19.55) < 0.001)
        #expect(AppTypography.Role.caption.effectiveSize == 14)
    }

    @Test func displayRolesKeepTheirDesignSize() {
        for role in AppTypography.Role.allCases where role.family == .display {
            #expect(role.effectiveSize == role.size)
        }
    }

    @Test func systemFallbackKeepsTheDesignSizeStyle() {
        // The fallback is described by text style and weight only, so the body scale never applies to it.
        let resolved = AppTypography.resolvedFont(for: .body, isAvailable: { _ in false })
        #expect(resolved == .system(.body, .regular))
    }

    @Test func unavailableFontFallsBackToSystem() {
        for role in AppTypography.Role.allCases {
            let resolved = AppTypography.resolvedFont(for: role, isAvailable: { _ in false })
            #expect(resolved == .system(role.textStyle, role.fallbackWeight))
        }
    }

    @Test func fontFilesAreInTheAppBundle() {
        let urls = (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [])
            + (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "fonts") ?? [])
        let names = Set(urls.map(\.lastPathComponent))
        for family in AppTypography.Family.allCases {
            #expect(names.contains(family.fileName))
        }
    }
}
