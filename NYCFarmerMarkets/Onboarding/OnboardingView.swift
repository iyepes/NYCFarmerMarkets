import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
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

                TabView(selection: $selection) {
                    ForEach(pages) { page in
                        OnboardingPageView(
                            page: page,
                            topInset: proxy.safeAreaInsets.top + Layout.skipAreaHeight,
                            bottomInset: proxy.safeAreaInsets.bottom + Layout.controlsAreaHeight
                        )
                        .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
            }
            .overlay(alignment: .topTrailing) { skipButton }
            .overlay(alignment: .bottom) { bottomControls }
        }
    }

    private enum Layout {
        // Skip button height (about 34 pt) plus its 8 pt top padding, with a small gap.
        static let skipAreaHeight: CGFloat = 48
        static let controlsAreaHeight: CGFloat = 150
    }

    private var skipButton: some View {
        Button("Skip") { finish() }
            .appFont(.body)
            .buttonStyle(.glass)
            .padding(.top, 8)
            .foregroundStyle(AppPalette.textPrimary.color)
            .padding(.horizontal, 24)
            .opacity(isLast ? 0 : 1)
            .disabled(isLast)
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
            .accessibilityLabel("Page \(selection + 1) of \(pages.count)")

            // Tinted, translucent glass so the page shows through (glassProminent is nearly opaque).
            Button(action: advance) {
                Text(isLast ? "Enter the market" : "Next")
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
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    private func advance() {
        if isLast {
            finish()
        } else {
            withAnimation(.easeInOut) { selection += 1 }
        }
    }

    private func finish() {
        hasSeenOnboarding = true
    }
}

#Preview {
    OnboardingView()
}
