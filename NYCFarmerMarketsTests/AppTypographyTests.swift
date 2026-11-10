//
//  AppTypographyTests.swift
//  NYCFarmerMarketsTests
//

import Testing
import CoreText
import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
@testable import NYCFarmerMarkets

struct AppTypographyTests {

    @Test func postScriptNames() {
        #expect(AppTypography.Family.display.postScriptName == "Grim-Creeper-Regular")
        #expect(AppTypography.Family.body.postScriptName == "N8ghtmare")
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
            #expect(resolved == .custom(name: role.family.postScriptName, size: role.size, relativeTo: role.textStyle))
        }
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
