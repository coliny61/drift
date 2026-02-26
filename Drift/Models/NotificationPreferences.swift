import Foundation

struct NotificationPreferences: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    var eventReminders: Bool
    var newEventsFromFollowed: Bool
    var rsvpConfirmations: Bool
    var checkInReminders: Bool
    var chatMessages: Bool
    var submissionUpdates: Bool

    static let defaults = NotificationPreferences(
        id: UUID(),
        userId: UUID(),
        eventReminders: true,
        newEventsFromFollowed: true,
        rsvpConfirmations: true,
        checkInReminders: true,
        chatMessages: true,
        submissionUpdates: true
    )

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case eventReminders = "event_reminders"
        case newEventsFromFollowed = "new_events_from_followed"
        case rsvpConfirmations = "rsvp_confirmations"
        case checkInReminders = "check_in_reminders"
        case chatMessages = "chat_messages"
        case submissionUpdates = "submission_updates"
    }
}
