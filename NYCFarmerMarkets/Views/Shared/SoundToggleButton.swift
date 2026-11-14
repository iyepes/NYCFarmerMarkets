//
//  SoundToggleButton.swift
//  NYCFarmerMarkets
//

import SwiftUI

/// Turns interaction sounds on or off. The choice is saved by `SoundController`.
struct SoundToggleButton: View {
    @Environment(SoundController.self) private var sounds

    var body: some View {
        Button {
            sounds.setEnabled(!sounds.isEnabled)
            sounds.play(.hiss)  // the policy blocks it when sounds were just turned off
        } label: {
            IconView(sounds.isEnabled ? .soundOn : .soundOff, size: 22)
        }
        .accessibilityLabel("Sounds")
        .accessibilityValue(sounds.isEnabled ? "On" : "Off")
        .accessibilityIdentifier("sound-toggle")
    }
}
