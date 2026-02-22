import SwiftUI

enum AppConstants {
    static let appName = "Drift"
    static let tagline = "Discover your flow"

    // DFW Neighborhoods
    static let neighborhoods = [
        "Deep Ellum", "Uptown", "Bishop Arts", "Lower Greenville",
        "Oak Lawn", "Addison", "Frisco", "Fort Worth", "Knox/Henderson",
        "Design District", "Trinity Groves", "Lakewood", "Park Cities",
        "Las Colinas", "Plano", "McKinney", "Denton", "Arlington"
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

    // For You scoring weights
    enum ForYouWeights {
        static let interestMatch: Double = 1.0
        static let categoryMatch: Double = 2.0
        static let friendGoing: Double = 1.5
        static let maxFriendPoints: Double = 5.0
        static let proximityClose: Double = 3.0    // < 5mi
        static let proximityMedium: Double = 2.0   // < 10mi
        static let proximityFar: Double = 1.0      // < 20mi
        static let trendingHigh: Double = 2.0      // > 20 RSVPs
        static let trendingMedium: Double = 1.0    // > 10 RSVPs
        static let recencySoon: Double = 2.0       // < 2 days
        static let recencyWeek: Double = 1.0       // < 7 days
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
    }
}
