import Foundation

struct CheckIn: Codable, Identifiable, Hashable {
    let id: UUID
    let eventId: UUID
    let userId: UUID
    let method: String
    let isVerified: Bool
    let checkedInAt: Date

    var isProximityVerified: Bool {
        method == "proximity" && isVerified
    }

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case userId = "user_id"
        case method
        case isVerified = "is_verified"
        case checkedInAt = "checked_in_at"
    }
}
