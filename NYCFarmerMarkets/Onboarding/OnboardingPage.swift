import Foundation

/// How a page's hero image is presented.
nonisolated enum HeroStyle: Sendable {
    case illustration   // transparent PNG, shown on a light circle
    case framed         // opaque picture such as a map, shown in a rounded frame
}

/// Content for one onboarding screen.
nonisolated struct OnboardingPage: Identifiable, Sendable {
    let id: Int
    let eyebrow: String      // small label above the title
    let emoji: String        // Halloween accent shown with the symbol
    let symbol: AppIcon      // themed icon
    var heroImage: String? = nil   // image name; replaces the symbol when set
    var heroStyle: HeroStyle = .illustration
    let title: String
    let message: String
    let bullets: [String]

    static let all: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            eyebrow: "THE HAUNTING",
            emoji: "🦇",
            symbol: .onboardingShipping,
            heroImage: "pirate-ship",
            title: "Your dinner has traveled farther than you have",
            message: "Big cities lean on big stores, and much of that food crosses coast to coast or travel an ocean before it reaches you. Meanwhile, small farms and family food makers lurk just around the corner, with no way to reach you.",
            bullets: [
                "Your groceries rack up frequent-flyer miles",
                "Local growers are locked out of the big channels",
                "Neighbors never meet the people who feed them"
            ]
        ),
        OnboardingPage(
            id: 1,
            eyebrow: "THE SPELL",
            emoji: "🎃",
            symbol: .onboardingMap,
            heroImage: "map-image",
            heroStyle: .framed,
            title: "We conjured up your nearest market",
            message: "New York City quietly publishes Open Data about its farmers markets, a secret scroll that few people ever read. Spooky Markets turns it into a map, so the closest market is one tap away.",
            bullets: [
                "Market locations straight from NYC Open Data",
                "Find markets lurking near you",
                "A friendly new way for local producers to be found"
            ]
        ),
        OnboardingPage(
            id: 2,
            eyebrow: "THE GUEST LIST",
            emoji: "👻",
            symbol: .onboardingPeople,
            heroImage: "dairy-products-pallete",
            title: "Neighbors and growers, come on in",
            message: "Hungry for fresher food close to home? Or existent farmers who bring their products? Spooky Markets brings you together, no scary middlemen required.",
            bullets: [
                "New Yorkers who crave fresh, local food",
                "Farmers and family food businesses",
                "Anyone curious what their city has been hiding"
            ]
        )
    ]
}
