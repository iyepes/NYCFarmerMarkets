import CoreGraphics

/// Decides how far below the top the onboarding hero starts.
///
/// The hero is centered and rises beside the Skip button (safe-area top + `topMargin`) when it
/// cannot touch Skip, otherwise it starts just below Skip.
///
/// Rule: the hero is a rounded rectangle `heroWidth` wide with corner radius `r` (the full
/// half-width for a circle). Relative to the hero top, Skip's bottom edge is at
/// `y = skipTopPadding + skipSize.height - topMargin`. The hero half-extent at `y` is
/// - `y <= 0`: the hero does not reach Skip, so it clears;
/// - `y >= r`: `heroWidth / 2`;
/// - otherwise `heroWidth / 2 - (r - sqrt(r^2 - (r - y)^2))`.
/// The hero clears when `containerWidth / 2 + halfExtent + sideGap` is at most Skip's left edge,
/// `containerWidth - skipTrailingPadding - skipSize.width`.
nonisolated enum OnboardingHeroLayout {
    /// Hero top below the safe area when it sits beside Skip.
    static let topMargin: CGFloat = 8
    /// Space between Skip's bottom and the hero when the hero must sit below Skip.
    static let gapBelowSkip: CGFloat = 3
    /// Horizontal space kept between the hero and Skip.
    static let sideGap: CGFloat = 4

    static func topInset(
        safeAreaTop: CGFloat,
        containerWidth: CGFloat,
        heroWidth: CGFloat,
        heroCornerRadius: CGFloat,
        skipSize: CGSize,
        skipTopPadding: CGFloat,
        skipTrailingPadding: CGFloat
    ) -> CGFloat {
        let safe = sanitized(safeAreaTop)
        let width = sanitized(containerWidth)
        let hero = sanitized(heroWidth)
        let radius = min(sanitized(heroCornerRadius), hero / 2)
        let skipWidth = sanitized(skipSize.width)
        let skipHeight = sanitized(skipSize.height)
        let topPadding = sanitized(skipTopPadding)
        let trailing = sanitized(skipTrailingPadding)

        let besideSkip = safe + topMargin
        let belowSkip = max(safe + topPadding + skipHeight + gapBelowSkip, besideSkip)

        let skipBottom = topPadding + skipHeight - topMargin
        let halfExtent: CGFloat
        if skipBottom <= 0 {
            return besideSkip
        } else if skipBottom >= radius {
            halfExtent = hero / 2
        } else {
            let rise = radius - skipBottom
            halfExtent = hero / 2 - (radius - (radius * radius - rise * rise).squareRoot())
        }
        let heroRight = width / 2 + halfExtent + sideGap
        let skipLeft = width - trailing - skipWidth
        return heroRight <= skipLeft ? besideSkip : belowSkip
    }

    private static func sanitized(_ value: CGFloat) -> CGFloat {
        value.isFinite ? max(value, 0) : 0
    }
}
