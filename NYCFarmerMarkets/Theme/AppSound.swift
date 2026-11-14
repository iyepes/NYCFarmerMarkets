//
//  AppSound.swift
//  NYCFarmerMarkets
//
//  Registry of every sound used in the UI. Views never name sound files;
//  they send cues to `SoundController`.
//

import Foundation

nonisolated enum AppSound: String, CaseIterable, Sendable {
    case humanSteps
    case catSteps
    case door
    case doorAndHit
    case hiss

    var fileName: String {
        switch self {
        case .humanSteps: "human-steps"
        case .catSteps: "cat-steps"
        case .door: "door"
        case .doorAndHit: "door-and-hit"
        case .hiss: "short-hiss"
        }
    }

    var fileExtension: String { "m4a" }

    /// Step sounds loop while the list scrolls.
    var loops: Bool {
        switch self {
        case .humanSteps, .catSteps: true
        case .door, .doorAndHit, .hiss: false
        }
    }
}
