import Foundation

struct ActivityFeedItem: Codable, Identifiable {
    let id: UUID
    let actorId: UUID
    let actionType: String
    let targetEventId: UUID?
    let targetUserId: UUID?
    let metadata: [String: String]?
    let createdAt: Date
    var actor: Profile?
    var targetEvent: Event?

    // MARK: - ActionType

    enum ActionType: String, Codable {
        case rsvp
        case follow
        case photoUpload = "photo_upload"
        case newEvent = "new_event"
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case actorId = "actor_id"
        case actionType = "action_type"
        case targetEventId = "target_event_id"
        case targetUserId = "target_user_id"
        case metadata
        case createdAt = "created_at"
        case actor
        case targetEvent = "target_event"
    }
}

// MARK: - Hashable

extension ActivityFeedItem: Hashable {
    static func == (lhs: ActivityFeedItem, rhs: ActivityFeedItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(actorId)
        hasher.combine(actionType)
        hasher.combine(targetEventId)
        hasher.combine(targetUserId)
        hasher.combine(createdAt)
    }
}
