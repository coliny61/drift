import Foundation

struct DirectMessage: Codable, Identifiable, Hashable {
    let id: UUID
    let senderId: UUID
    let recipientId: UUID
    let content: String
    let createdAt: Date
    var readAt: Date?
    var sender: Profile?
}

struct DMConversation: Identifiable {
    let id: UUID // other user's ID
    let otherUser: Profile?
    let lastMessage: DirectMessage
    let unreadCount: Int
}
