import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @Environment(SoundController.self) private var sounds
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selection = 0
    @State private var skipSize = Layout.defaultSkipSize

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

                // The page ScrollView adds the top safe area on top of this inset, so the
                // "beside Skip" result lands about one safe area lower, below Skip. The owner
                // accepted that position (about 40 pt higher than the old safe + 48 inset).
                pager(topInset: heroTopInset(safeAreaTop: proxy.safeAreaInsets.top, width: proxy.size.width),
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
        static let skipTopPadding: CGFloat = 8
        static let skipTrailingPadding: CGFloat = 24
        /// Skip size used until the button is measured.
        static let defaultSkipSize = CGSize(width: 55, height: 34)
        static let dotDiameter: CGFloat = 12
        static let dotSpacing: CGFloat = 12
        static let indicatorMinimumSize: CGFloat = 44
        static let controlsAreaHeight: CGFloat = 166
    }

    /// All pages share one top inset, so the clearance uses the hero shape that reaches
    /// furthest toward Skip: the framed picture (small corner radius) if any page uses it,
    /// otherwise the circle (radius = half the hero size).
    private func heroTopInset(safeAreaTop: CGFloat, width: CGFloat) -> CGFloat {
        let usesFramed = pages.contains { $0.heroImage != nil && $0.heroStyle == .framed }
        let radius = usesFramed ? OnboardingPageView.framedCornerRadius : OnboardingPageView.heroSize / 2
        return OnboardingHeroLayout.topInset(
            safeAreaTop: safeAreaTop,
            containerWidth: width,
            heroWidth: OnboardingPageView.heroSize,
            heroCornerRadius: radius,
            skipSize: skipSize,
            skipTopPadding: Layout.skipTopPadding,
            skipTrailingPadding: Layout.skipTrailingPadding
        )
    }

    private var skipButton: some View {
        Button(AppCopy.onboardingSkip, action: skip)
            .appFont(.body)
            .accessibilityLabel(AppCopy.onboardingSkip)
            .accessibilityIdentifier("onboarding-skip")
            .buttonStyle(.glass)
            // Measured before padding; Skip stays laid out (opacity 0) on the last page.
            .onGeometryChange(for: CGSize.self) { $0.size } action: { skipSize = $0 }
            .padding(.top, Layout.skipTopPadding)
            .foregroundStyle(AppPalette.textPrimary.color)
            .padding(.horizontal, Layout.skipTrailingPadding)
            .opacity(isLast ? 0 : 1)
            .disabled(isLast)
            .accessibilityHidden(isLast)
    }

    private var bottomControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: Layout.dotSpacing) {
                ForEach(pages) { page in
                    Circle()
                        .fill(page.id == selection ? AppPalette.accent.color : AppPalette.textPrimary.color.opacity(0.4))
                        .frame(width: Layout.dotDiameter, height: Layout.dotDiameter)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(minWidth: Layout.indicatorMinimumSize, minHeight: Layout.indicatorMinimumSize)
            .glassEffect(.regular, in: .capsule)
            // Without this the accessibility frame shrinks to the 12 pt dots.
            .contentShape(.accessibility, .capsule)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(AppCopy.onboardingPageIndicatorLabel)
            .accessibilityValue(AppCopy.onboardingPageIndicator(page: selection + 1, count: pages.count))
            // VoiceOver swipe up/down moves one page; no sound, never sets the onboarding flag.
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: step(1)
                case .decrement: step(-1)
                @unknown default: break
                }
            }
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
                    // The whole capsule is the hit area, not only the text.
                    .contentShape(.capsule)
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
        } else {
            move(to: selection + 1)
        }
    }

    /// Moves one page for the VoiceOver adjust action; ignores moves past either end.
    private func step(_ delta: Int) {
        guard let target = OnboardingPaging.target(from: selection, delta: delta, count: pages.count) else { return }
        move(to: target)
    }

    /// `selection` holds the page id, which equals the page index (ids are 0, 1, 2 in order).
    private func move(to index: Int) {
        if reduceMotion {
            selection = index
        } else {
            withAnimation(.easeInOut) { selection = index }
        }
    }
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
        .environment(SoundController(testMuted: true, player: SilentSoundPlayer()))
}
