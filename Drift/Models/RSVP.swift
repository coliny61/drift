import Foundation

struct RSVP: Codable, Identifiable, Hashable {
    let id: UUID
    let eventId: UUID
    let userId: UUID
    let status: String
    let createdAt: Date

    // MARK: - RSVPStatus

    enum RSVPStatus: String, Codable {
        case going
        case interested
        case checkedIn = "checked_in"
    }

    var isCheckedIn: Bool {
        status == RSVPStatus.checkedIn.rawValue
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case userId = "user_id"
        case status
        case createdAt = "created_at"
    }
}
