//
//  AppSoundTests.swift
//  NYCFarmerMarketsTests
//
import Testing
import Foundation
@testable import NYCFarmerMarkets

struct AppSoundTests {
    @Test func everySoundFileIsBundled() {
        for sound in AppSound.allCases {
            let url = Bundle.main.url(forResource: sound.fileName, withExtension: sound.fileExtension)
            #expect(url != nil, "Missing \(sound.fileName).\(sound.fileExtension)")
        }
    }

    @Test func fileNamesAreUnique() {
        let names = AppSound.allCases.map(\.fileName)
        #expect(Set(names).count == names.count)
    }

    @Test func onlyStepSoundsLoop() {
        let looping = Set(AppSound.allCases.filter(\.loops))
        #expect(looping == [.humanSteps, .catSteps])
    }
}
