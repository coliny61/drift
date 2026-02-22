import Foundation

enum SupabaseConfig {
    static let url = URL(string: "https://YOUR_PROJECT.supabase.co")!
    static let anonKey = "YOUR_ANON_KEY"

    // Table names
    static let eventsTable = "events"
    static let profilesTable = "profiles"
    static let organizersTable = "organizers"
    static let rsvpsTable = "rsvps"
    static let followsTable = "follows"
    static let organizerFollowsTable = "organizer_follows"
    static let chatMessagesTable = "chat_messages"
    static let eventPhotosTable = "event_photos"
    static let photoReactionsTable = "photo_reactions"
    static let activityFeedTable = "activity_feed"

    // Storage buckets
    static let avatarsBucket = "avatars"
    static let eventPhotosBucket = "event-photos"
    static let coverImagesBucket = "cover-images"
}
