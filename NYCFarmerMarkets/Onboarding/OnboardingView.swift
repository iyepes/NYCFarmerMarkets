import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @Environment(SoundController.self) private var sounds
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selection = 0

    private let pages = OnboardingPage.all
    private var isLast: Bool { selection == pages.count - 1 }

    var body: some View {
        // Read the safe area here, then let the pages ignore it so they run edge to edge.
        // Each page adds the insets back as scroll margins, so text rests clear of the
        // status bar and controls but scrolls underneath them.
        GeometryReader { proxy in
            ZStack {
                AppPalette.background.color
                    .ignoresSafeArea()

                pager(topInset: proxy.safeAreaInsets.top + Layout.skipAreaHeight,
                      bottomInset: proxy.safeAreaInsets.bottom + Layout.controlsAreaHeight)
                    .ignoresSafeArea()
            }
            .overlay(alignment: .topTrailing) { skipButton }
            .overlay(alignment: .bottom) { bottomControls }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding-screen")
    }

    @ViewBuilder
    private func pager(topInset: CGFloat, bottomInset: CGFloat) -> some View {
        #if os(macOS)
        // The paged TabView style does not exist on macOS, so show only the current page.
        // Next and Skip drive `selection` the same way.
        if pages.indices.contains(selection) {
            OnboardingPageView(page: pages[selection], topInset: topInset, bottomInset: bottomInset)
                .id(pages[selection].id)
        }
        #else
        TabView(selection: $selection) {
            ForEach(pages) { page in
                OnboardingPageView(page: page, topInset: topInset, bottomInset: bottomInset)
                    .tag(page.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        #endif
    }

    private enum Layout {
        // Skip button height (about 34 pt) plus its 8 pt top padding, with a small gap.
        static let skipAreaHeight: CGFloat = 48
        static let controlsAreaHeight: CGFloat = 150
    }

    private var skipButton: some View {
        Button(AppCopy.onboardingSkip, action: skip)
            .appFont(.body)
            .accessibilityLabel(AppCopy.onboardingSkip)
            .accessibilityIdentifier("onboarding-skip")
            .buttonStyle(.glass)
            .padding(.top, 8)
            .foregroundStyle(AppPalette.textPrimary.color)
            .padding(.horizontal, 24)
            .opacity(isLast ? 0 : 1)
            .disabled(isLast)
            .accessibilityHidden(isLast)
    }

    private var bottomControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(pages) { page in
                    Circle()
                        .fill(page.id == selection ? AppPalette.accent.color : AppPalette.textPrimary.color.opacity(0.4))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: .capsule)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(AppCopy.onboardingPageIndicator(page: selection + 1, count: pages.count))
            .accessibilityIdentifier("onboarding-page-indicator")

            // Tinted, translucent glass so the page shows through (glassProminent is nearly opaque).
            Button(action: advance) {
                Text(AppCopy.onboardingPrimaryLabel(isLast: isLast))
                    .appFont(.bodyEmphasis)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(AppPalette.onAccentFill.color)
                    .glassEffect(
                        .regular.tint(AppPalette.accentFill.color.opacity(0.75)).interactive(),
                        in: .capsule
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppCopy.onboardingPrimaryLabel(isLast: isLast))
            .accessibilityIdentifier("onboarding-next")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    private func skip() {
        guard !hasSeenOnboarding else { return }
        sounds.play(.hiss)
        hasSeenOnboarding = true
    }

    private func advance() {
        guard !hasSeenOnboarding else { return }
        sounds.play(.hiss)
        if isLast {
            hasSeenOnboarding = true
        } else if reduceMotion {
            selection += 1
        } else {
            withAnimation(.easeInOut) { selection += 1 }
        }
    }
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
        .environment(SoundController(testMuted: true, player: SilentSoundPlayer()))
}
