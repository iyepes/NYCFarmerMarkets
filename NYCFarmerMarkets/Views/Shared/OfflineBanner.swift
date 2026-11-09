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
