import Foundation

struct Organizer: Codable, Identifiable, Hashable {
    let id: UUID
    let profileId: UUID?
    let name: String
    let slug: String
    let description: String
    let logoUrl: String?
    let instagramHandle: String?
    let isVerified: Bool

    // Phase 2 fields
    var verificationStatus: String? = nil
    var isFeatured: Bool? = nil
    var featuredUntil: Date? = nil
    var website: String? = nil
    var contactEmail: String? = nil
    var city: String? = nil

    // MARK: - Computed Properties

    var isVerifiedOrganizer: Bool {
        verificationStatus == "verified" || (verificationStatus == nil && isVerified)
    }

    var isPendingVerification: Bool {
        verificationStatus == "pending"
    }

    var isCurrentlyFeatured: Bool {
        guard isFeatured == true else { return false }
        if let until = featuredUntil {
            return until > Date()
        }
        return true
    }

    var displayUrl: String? {
        if let website, !website.isEmpty {
            return website
        }
        if let handle = instagramHandle, !handle.isEmpty {
            return "https://instagram.com/\(handle)"
        }
        return nil
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case name
        case slug
        case description
        case logoUrl = "logo_url"
        case instagramHandle = "instagram_handle"
        case isVerified = "is_verified"
        case verificationStatus = "verification_status"
        case isFeatured = "is_featured"
        case featuredUntil = "featured_until"
        case website
        case contactEmail = "contact_email"
        case city
    }
}
