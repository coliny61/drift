import Foundation

struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let eventId: UUID
    let senderId: UUID
    let content: String
    let createdAt: Date
    var sender: Profile?

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case senderId = "sender_id"
        case content
        case createdAt = "created_at"
        case sender
    }
}

// MARK: - Hashable

extension ChatMessage: Hashable {
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(eventId)
        hasher.combine(senderId)
        hasher.combine(content)
        hasher.combine(createdAt)
    }
}
