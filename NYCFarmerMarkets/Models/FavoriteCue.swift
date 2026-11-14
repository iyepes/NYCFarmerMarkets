//
//  FavoriteCue.swift
//  NYCFarmerMarkets
//
import Foundation

/// Chooses the sound cue for favorite changes, so the rule lives in one
/// testable place and views never name a sound.
nonisolated enum FavoriteCue {
    /// Played when a market is removed from favorites, on every removal path.
    static let removal: AppSound = .ay

    /// Cue for the detail favorite toggle: removal plays `removal`,
    /// adding keeps the hiss.
    static func toggle(wasFavorite: Bool) -> AppSound {
        wasFavorite ? removal : .hiss
    }
}
