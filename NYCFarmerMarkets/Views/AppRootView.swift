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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var minimumDisplayTime: Duration = SplashDecision.minimumDisplayTime

    @State private var minimumTimeElapsed = false
    @State private var hasDismissed = false

    /// Failure that leaves nothing to show: a failed load, or a successful load that returned no markets.
    private var errorMessage: String? {
        guard store.markets.isEmpty else { return nil }
        switch store.state {
        case .error(let message): return message
        case .loaded: return "No markets are available right now."
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

    var body: some View {
        ZStack {
            if hasDismissed {
                RootTabView()
            } else {
                SplashView(phase: phase) { Task { await store.refresh() } }
                    .transition(reduceMotion ? .identity : .opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: hasDismissed)
        .task { await store.load() }  // started once, from the splash phase
        .task {
            try? await Task.sleep(for: minimumDisplayTime)
            minimumTimeElapsed = true
        }
        .onChange(of: phase, initial: true) { _, newValue in
            if newValue == .dismissed { hasDismissed = true }  // latch: the splash never returns
        }
    }
}
