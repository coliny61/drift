import Foundation

enum SupabaseConfig {
    static let url = URL(string: "https://xzxhnpukbeicggxxuymp.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6eGhucHVrYmVpY2dneHh1eW1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4MTAyOTUsImV4cCI6MjA4NzM4NjI5NX0.4rGykh28aOzHfmgzGpPt4NPYU5-2oNReMa1HjR9wDXI"

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

    // Phase 2 tables
    static let checkInsTable = "check_ins"
    static let boostRequestsTable = "boost_requests"
    static let deviceTokensTable = "device_tokens"
    static let notificationPreferencesTable = "notification_preferences"

    // Storage buckets
    static let avatarsBucket = "avatars"
    static let eventPhotosBucket = "event-photos"
    static let coverImagesBucket = "cover-images"
}
