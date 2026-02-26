import Foundation

struct BoostRequest: Codable, Identifiable, Hashable {
    let id: UUID
    let eventId: UUID
    let organizerId: UUID
    let contactEmail: String
    let message: String?
    let status: String
    let createdAt: Date

    var isPending: Bool { status == "pending" }
    var isApproved: Bool { status == "approved" }

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case organizerId = "organizer_id"
        case contactEmail = "contact_email"
        case message
        case status
        case createdAt = "created_at"
    }
}
