import Foundation

struct EventPhoto: Codable, Identifiable, Hashable {
    let id: UUID
    let eventId: UUID
    let uploadedBy: UUID
    let photoUrl: String
    let caption: String?
    let createdAt: Date

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case uploadedBy = "uploaded_by"
        case photoUrl = "photo_url"
        case caption
        case createdAt = "created_at"
    }
}
