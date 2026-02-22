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
    }
}
