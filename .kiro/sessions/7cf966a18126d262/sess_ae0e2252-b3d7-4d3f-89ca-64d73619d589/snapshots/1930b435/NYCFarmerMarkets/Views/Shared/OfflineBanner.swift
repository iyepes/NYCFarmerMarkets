//
//  OfflineBanner.swift
//  NYCFarmerMarkets
//

import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            IconView(.offline, size: 16)
            Text("Offline, showing saved data")
                .font(.footnote.weight(.medium))
        }
        .foregroundStyle(AppPalette.textPrimary.color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AppPalette.cardSelected.color)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("offline-banner")
    }
}

extension View {
    /// Stacks the offline banner above the content when `isVisible` is true.
    /// (A plain VStack keeps large navigation titles and search fields working.)
    func offlineBanner(_ isVisible: Bool) -> some View {
        VStack(spacing: 0) {
            if isVisible { OfflineBanner() }
            self
        }
    }
}

/// Full-screen error state with a retry button.
struct LoadErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label {
                Text("Something spooked the data")
            } icon: {
                IconView(.warning, size: 40)
            }
            .foregroundStyle(AppPalette.textPrimary.color)
        } description: {
            Text(message)
                .foregroundStyle(AppPalette.textSecondary.color)
        } actions: {
            Button("Retry", action: retry)
                .buttonStyle(ThemedButtonStyle())
                .accessibilityIdentifier("retry-button")
        }
    }
}
