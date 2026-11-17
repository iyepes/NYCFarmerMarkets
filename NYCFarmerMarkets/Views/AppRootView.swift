//
//  AppRootView.swift
//  NYCFarmerMarkets
//
//  Shows the launch splash until data is ready (and the minimum display time
//  has elapsed), then switches to the main tabs.
//

import SwiftUI

struct AppRootView: View {
    @Environment(MarketStore.self) private var store
    @Environment(SoundController.self) private var sounds
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    var minimumDisplayTime: Duration = SplashDecision.minimumDisplayTime

    @AppStorage(OnboardingDecision.defaultsKey) private var hasSeenOnboarding = false
    @State private var minimumTimeElapsed = false
    @State private var hasDismissed = false

    /// Failure that leaves nothing to show: a failed load, or a successful load that returned no markets.
    private var errorMessage: String? {
        guard store.markets.isEmpty else { return nil }
        switch store.state {
        case .error(let message): return message
        case .loaded: return LoadFailureMessage.noMarkets.title
        case .idle, .loading: return nil
        }
    }

    /// Plain-language hint shown under the failure title.
    private var errorHint: String? {
        guard store.markets.isEmpty else { return nil }
        switch store.state {
        case .error: return store.failure?.hint
        case .loaded: return LoadFailureMessage.noMarkets.hint
        case .idle, .loading: return nil
        }
    }

    private var phase: SplashPhase {
        SplashDecision.phase(
            dataAvailable: !store.markets.isEmpty,
            minimumTimeElapsed: minimumTimeElapsed,
            errorMessage: errorMessage
        )
    }

    /// The screen to show. `hasDismissed` keeps the splash from returning after a later refresh.
    private var screen: RootScreen {
        OnboardingDecision.screen(
            phase: hasDismissed ? .dismissed : phase,
            hasSeenOnboarding: hasSeenOnboarding
        )
    }

    var body: some View {
        ZStack {
            switch screen {
            case .splash:
                SplashView(phase: phase, hint: errorHint) { Task { await store.refresh() } }
                    .transition(reduceMotion ? .identity : .opacity)
            case .onboarding:
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                    .transition(reduceMotion ? .identity : .opacity)
            case .tabs:
                RootTabView()
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: screen)
        .task { await store.load() }  // started once, from the splash phase
        .task {
            try? await Task.sleep(for: minimumDisplayTime)
            minimumTimeElapsed = true
        }
        .onChange(of: phase, initial: true) { _, newValue in
            if newValue == .dismissed { hasDismissed = true }  // latch: the splash never returns
        }
        // Sounds are muted while VoiceOver runs. This view parents both the splash and the tabs.
        .onChange(of: voiceOverEnabled, initial: true) { _, enabled in
            sounds.setVoiceOverOn(enabled)
        }
    }
}
