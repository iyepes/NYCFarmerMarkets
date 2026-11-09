//
//  SplashView.swift
//  NYCFarmerMarkets
//
//  Launch splash: app logo with a loading indicator, or an error message
//  and Retry button when the first load fails.
//

import SwiftUI

struct SplashView: View {
    let phase: SplashPhase
    /// Plain-language hint shown under a failure message.
    var hint: String? = nil
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            LogoView()
            Spacer()
            footer
            Spacer()
        }
        .foregroundStyle(AppPalette.onAppIconBackground.color)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppPalette.appIconBackground.color.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("splash-screen")
    }

    @ViewBuilder
    private var footer: some View {
        switch phase {
        case .failed(let message):
            VStack(spacing: 16) {
                Text(message)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("splash-error")
                if let hint {
                    Text(hint)
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("splash-error-hint")
                }
                Button("Retry", action: onRetry)
                    .buttonStyle(ThemedButtonStyle())
                    .accessibilityLabel("Retry loading markets")
                    .accessibilityIdentifier("splash-retry")
            }
            .padding(.horizontal, 32)
        case .loading, .dismissed:
            SplashLoadingIndicator()
        }
    }
}

/// Logo with its own accessibility label (`IconView` hides itself).
private struct LogoView: View {
    var body: some View {
        IconView(.logo, size: 160)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(AppIcon.logo.accessibilityName)
    }
}

#Preview("Loading") {
    SplashView(phase: .loading, onRetry: {})
}

#Preview("Failed") {
    SplashView(phase: .failed(message: LoadFailureMessage.offline.title), hint: LoadFailureMessage.offline.hint, onRetry: {})
}
