import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage
    /// Space to keep clear at the top (safe area + Skip button) before content rests.
    var topInset: CGFloat = 1
    /// Space to keep clear at the bottom (safe area + glass controls).
    var bottomInset: CGFloat = 150

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                hero

                Text(page.eyebrow)
                    .appFont(.footnote)
                    .tracking(2)
                    .foregroundStyle(AppPalette.textSecondary.color)

                Text(page.title)
                    .appFont(.detailTitle)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppPalette.textPrimary.color)

                Text(page.message)
                    .appFont(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppPalette.textPrimary.color)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(page.bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "moon.stars.fill")
                                .foregroundStyle(AppPalette.accentSecondary.color)
                                .accessibilityHidden(true)
                            Text(bullet)
                                .appFont(.body)
                                .foregroundStyle(AppPalette.textPrimary.color)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppPalette.card.color, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        // Leave room so content rests clear of the floating Skip and bottom controls,
        // but can still scroll underneath them.
        .contentMargins(.top, topInset, for: .scrollContent)
        .contentMargins(.bottom, bottomInset, for: .scrollContent)
        // Soft fade where content passes under the glass controls.
        .scrollEdgeEffectStyle(.soft, for: [.top, .bottom])
    }

    private var hero: some View {
        ZStack(alignment: .topTrailing) {
            if let heroImage = page.heroImage {
                switch page.heroStyle {
                case .illustration:
                    // Lavender circle keeps the dark purple parts of the art visible in both appearances.
                    Circle()
                        .fill(AppPalette.accentFill.color)
                        .frame(width: 220, height: 220)
                        .overlay {
                            Image(heroImage)
                                .resizable()
                                .scaledToFit()
                                .padding(20)
                        }
                case .framed:
                    Image(heroImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 220, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .strokeBorder(AppPalette.accentSecondary.color, lineWidth: 3)
                        }
                }
            } else {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppPalette.accentFill.color, AppPalette.accentFill.color.opacity(0.15)],
                            center: .center, startRadius: 10, endRadius: 100
                        )
                    )
                    .frame(width: 180, height: 180)
                    .overlay {
                        Image(systemName: page.symbol)
                            .font(.system(size: 72))
                            .foregroundStyle(AppPalette.onAccentFill.color)
                    }
            }

            Text(page.emoji)
                .font(.system(size: 44))
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        AppPalette.background.color.ignoresSafeArea()
        OnboardingPageView(page: OnboardingPage.all[0])
    }
}
