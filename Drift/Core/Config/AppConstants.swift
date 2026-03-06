import SwiftUI

enum AppConstants {
    static let appName = "Drift"
    static let tagline = "Discover your flow"

    // DFW Neighborhoods (kept for backward compat)
    static let neighborhoods = [
        "Deep Ellum", "Uptown", "Bishop Arts", "Lower Greenville",
        "Oak Lawn", "Addison", "Frisco", "Fort Worth", "Knox/Henderson",
        "Design District", "Trinity Groves", "Lakewood", "Park Cities",
        "Las Colinas", "Plano", "McKinney", "Denton", "Arlington"
    ]

    // DFW Cities (primary geography filter)
    static let dfwCities = [
        "Dallas", "Fort Worth", "Plano", "Frisco", "Arlington",
        "McKinney", "Denton", "Richardson", "Irving", "Garland",
        "Allen", "Flower Mound", "Southlake", "Grapevine", "Addison",
        "Carrollton", "Lewisville", "Cedar Hill", "Mesquite", "Grand Prairie"
    ]

    // Event tags
    static let availableTags = [
        "alcohol-free", "beginner-friendly", "outdoor", "free",
        "women-only", "dog-friendly", "early-morning", "evening",
        "weekend", "family-friendly", "live-music", "byob-free"
    ]

    // Map defaults (DFW center)
    static let defaultLatitude = 32.7767
    static let defaultLongitude = -96.7970
    static let defaultSpan = 0.15

    // UI
    static let cardCornerRadius: CGFloat = 16
    static let chipCornerRadius: CGFloat = 20
    static let avatarSize: CGFloat = 40
    static let smallAvatarSize: CGFloat = 28

    // For You scoring weights (deterministic, explainable)
    enum ForYouWeights {
        static let base: Double = 10.0
        static let interestMatch: Double = 25.0      // category matches onboarding interests
        static let cityMatch: Double = 20.0           // event in user's city
        static let followsOrganizer: Double = 20.0    // user follows this organizer
        static let pastRSVPOrganizer: Double = 15.0   // user has RSVP'd to this organizer before
        static let freshness: Double = 10.0           // events sooner score higher
        static let featuredBoost: Double = 30.0       // featured/sponsored events
    }

    // Colors
    enum Colors {
        static let background = Color(hex: "0A0A0A")
        static let cardBackground = Color(hex: "1A1A1A")
        static let secondaryBackground = Color(hex: "2A2A2A")
        static let accent = Color(hex: "FF6B35")
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "9CA3AF")
        static let textTertiary = Color(hex: "6B7280")
        static let divider = Color(hex: "2A2A2A")
        static let success = Color(hex: "10B981")
        static let alcoholFreeBadge = Color(hex: "34D399")
        static let freeBadge = Color(hex: "60A5FA")
        static let info = Color(hex: "60A5FA")
        static let pink = Color(hex: "EC407A")
        static let warning = Color(hex: "FBBF24")
        static let error = Color(hex: "EF5350")
        static let purple = Color(hex: "7B68EE")
        static let instagram = Color(hex: "E1306C")
        static let teal = Color(hex: "34D399")
        static let interested = Color(hex: "FFD54F")
    }
}
