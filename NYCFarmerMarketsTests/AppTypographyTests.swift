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
        #expect(AppTypography.Family.body.postScriptName == "BlackChancery")
    }

    @Test func bodyRolesResolveToBlackChancery() {
        for role in AppTypography.Role.allCases where role.family == .body {
            let resolved = AppTypography.resolvedFont(for: role, isAvailable: { _ in true })
            #expect(resolved == .custom(name: "BlackChancery", size: role.effectiveSize, relativeTo: role.textStyle))
        }
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
            case .splash, .splashHint, .tabTitle, .sectionHeader, .tabBarLabel, .navigationTitle,
                 .detailTitle, .favoriteItemTitle:
                expected = .display
            case .body, .bodyEmphasis, .subheadline, .caption, .footnote:
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

    @Test func splashRoleIsFortyFourPoints() {
        #expect(AppTypography.Role.splash.size == 44)
        #expect(AppTypography.Role.splash.effectiveSize == 44)
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

    // MARK: - Preservation (Property 2): behavior outside the font lookup

    @Test func displayFontIsFoundAndRegistered() {
        let urls = (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [])
            + (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "fonts") ?? [])
        #expect(urls.contains { $0.lastPathComponent == "Grim Creeper.ttf" })
        #expect(AppTypography.Family.display.fileName == "Grim Creeper.ttf")
        #expect(AppTypography.registerFonts().availableFamilies.contains(.display))
        #expect(AppTypography.isAvailable(postScriptName: "Grim-Creeper-Regular"))
    }

    @Test(arguments: AppTypography.Role.allCases)
    func roleKeepsItsDesignValues(role: AppTypography.Role) {
        let expected: (AppTypography.Family, CGFloat, Font.TextStyle, Font.Weight)
        switch role {
        case .splash: expected = (.display, 44, .title2, .bold)
        case .splashHint: expected = (.display, 22, .title3, .semibold)
        case .tabTitle: expected = (.display, 34, .largeTitle, .semibold)
        case .tabBarLabel: expected = (.display, 12, .caption2, .semibold)
        case .navigationTitle: expected = (.display, 20, .headline, .semibold)
        case .detailTitle: expected = (.display, 30, .title, .bold)
        case .sectionHeader: expected = (.display, 30, .subheadline, .bold)
        case .favoriteItemTitle: expected = (.display, 20, .headline, .semibold)
        case .body: expected = (.body, 17, .body, .regular)
        case .bodyEmphasis: expected = (.body, 17, .headline, .semibold)
        case .subheadline: expected = (.body, 15, .subheadline, .regular)
        case .caption: expected = (.body, 12, .caption, .regular)
        case .footnote: expected = (.body, 13, .footnote, .medium)
        }
        #expect(role.family == expected.0)
        #expect(role.size == expected.1)
        #expect(role.textStyle == expected.2)
        #expect(role.fallbackWeight == expected.3)
    }

    @Test(arguments: AppTypography.Role.allCases)
    func effectiveSizeAppliesFamilyScaleAndFloor(role: AppTypography.Role) {
        switch role.family {
        case .display:
            #expect(role.effectiveSize == role.size)
        case .body:
            #expect(role.effectiveSize == max(role.size * 1.15, 14))
        }
    }

    @Test func familyScaleAndFloorValues() {
        #expect(AppTypography.Family.display.sizeScale == 1)
        #expect(AppTypography.Family.display.minimumSize == 0)
        #expect(AppTypography.Family.body.sizeScale == 1.15)
        #expect(AppTypography.Family.body.minimumSize == 14)
        #expect(AppTypography.Family.body.fileName == "BLKCHCRY.TTF")
    }

    @Test(arguments: AppTypography.Role.allCases, [true, false])
    func resolvedFontFollowsAvailability(role: AppTypography.Role, available: Bool) {
        let resolved = AppTypography.resolvedFont(for: role, isAvailable: { _ in available })
        if available {
            #expect(resolved == .custom(name: role.family.postScriptName, size: role.effectiveSize, relativeTo: role.textStyle))
        } else {
            #expect(resolved == .system(role.textStyle, role.fallbackWeight))
        }
    }

    @Test(arguments: AppTypography.Family.allCases)
    func onlyTheUnavailableFamilyFallsBack(unavailable: AppTypography.Family) {
        for role in AppTypography.Role.allCases {
            let resolved = AppTypography.resolvedFont(for: role, isAvailable: { $0 != unavailable })
            if role.family == unavailable {
                #expect(resolved == .system(role.textStyle, role.fallbackWeight))
            } else {
                #expect(resolved == .custom(name: role.family.postScriptName, size: role.effectiveSize, relativeTo: role.textStyle))
            }
        }
    }

    @Test func fontFilesAreInTheAppBundle() {
        let urls = AppTypography.bundledFontURLs(in: .main)
        for family in AppTypography.Family.allCases {
            #expect(AppTypography.fontURL(named: family.fileName, in: urls) != nil)
        }
    }

    // MARK: - fontURL(named:in:)

    @Test func fontURLFindsUpperCaseExtension() {
        let url = URL(fileURLWithPath: "/x/BLKCHCRY.TTF")
        #expect(AppTypography.fontURL(named: "BLKCHCRY.TTF", in: [url]) == url)
    }

    @Test func fontURLIgnoresCase() {
        let lower = URL(fileURLWithPath: "/x/blkchcry.ttf")
        #expect(AppTypography.fontURL(named: "BLKCHCRY.TTF", in: [lower]) == lower)
        let grim = URL(fileURLWithPath: "/x/Grim Creeper.ttf")
        #expect(AppTypography.fontURL(named: "Grim Creeper.ttf", in: [grim]) == grim)
    }

    @Test func fontURLReturnsNilWhenMissing() {
        #expect(AppTypography.fontURL(named: "BLKCHCRY.TTF", in: []) == nil)
        #expect(AppTypography.fontURL(named: "BLKCHCRY.TTF", in: [URL(fileURLWithPath: "/x/Other.ttf")]) == nil)
    }

    @Test func fontURLPicksTheRightFileFromAMixedList() {
        let other = URL(fileURLWithPath: "/x/Other.ttf")
        let grim = URL(fileURLWithPath: "/x/fonts/Grim Creeper.ttf")
        let chancery = URL(fileURLWithPath: "/x/BLKCHCRY.TTF")
        let urls = [other, grim, chancery]
        #expect(AppTypography.fontURL(named: AppTypography.Family.display.fileName, in: urls) == grim)
        #expect(AppTypography.fontURL(named: AppTypography.Family.body.fileName, in: urls) == chancery)
    }

    @Test(arguments: AppTypography.Family.allCases, [true, false])
    func fontURLFindsEachFamilyInAnyCase(family: AppTypography.Family, upper: Bool) {
        let name = upper ? family.fileName.uppercased() : family.fileName.lowercased()
        let url = URL(fileURLWithPath: "/x/\(name)")
        #expect(AppTypography.fontURL(named: family.fileName, in: [url]) == url)
    }
}
