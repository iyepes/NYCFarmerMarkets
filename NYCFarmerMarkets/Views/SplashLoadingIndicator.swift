//
//  SplashLoadingIndicator.swift
//  NYCFarmerMarkets
//
//  Three pulsing dots shown on the splash screen while markets load.
//  Static when Reduce Motion is on. Exposed as a single accessibility element.
//

import SwiftUI

struct SplashLoadingIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    private let dotCount = 3
    private let dotSize: CGFloat = 12
    private let spacing: CGFloat = 10

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<dotCount, id: \.self) { index in
                dot(at: index)
            }
        }
        .onAppear {
            if !reduceMotion {
                isPulsing = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading farmers markets")
        .accessibilityIdentifier("splash-loading")
    }

    @ViewBuilder
    private func dot(at index: Int) -> some View {
        let circle = Circle()
            .fill(AppPalette.onAppIconBackground.color)
            .frame(width: dotSize, height: dotSize)

        if reduceMotion {
            circle
        } else {
            circle
                .opacity(isPulsing ? 1 : 0.3)
                .scaleEffect(isPulsing ? 1 : 0.7)
                .animation(
                    .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(0.2 * Double(index)),
                    value: isPulsing
                )
        }
    }
}

#Preview {
    ZStack {
        AppPalette.appIconBackground.color.ignoresSafeArea()
        SplashLoadingIndicator()
    }
}
