import Foundation

struct Profile: Codable, Identifiable, Hashable {
    let id: UUID
    let username: String
    let displayName: String
    let bio: String?
    let avatarUrl: String?
    let interests: [String]
    let locationLat: Double?
    let locationLng: Double?
    let neighborhood: String?
    let streakCount: Int
    let eventsAttended: Int
    let createdAt: Date

    // Phase 2 fields
    var city: String? = nil

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case bio
        case avatarUrl = "avatar_url"
        case interests
        case locationLat = "location_lat"
        case locationLng = "location_lng"
        case neighborhood
        case streakCount = "streak_count"
        case eventsAttended = "events_attended"
        case createdAt = "created_at"
        case city
    }
}
