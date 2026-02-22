import Foundation
import Supabase

@Observable
final class ActivityService {
    private let client: SupabaseClient

    var feedItems: [ActivityFeedItem] = []
    var isLoading = false

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchFeed(userId: UUID) async {
        isLoading = true
        do {
            // Fetch activity from people the user follows
            let response: [ActivityFeedItem] = try await client.from("activity_feed")
                .select()
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value
            feedItems = response
        } catch {
            print("Error fetching activity feed: \(error)")
        }
        isLoading = false
    }

    func logActivity(actorId: UUID, actionType: String, targetEventId: UUID? = nil, targetUserId: UUID? = nil) async {
        var entry: [String: String] = [
            "actor_id": actorId.uuidString,
            "action_type": actionType
        ]
        if let targetEventId {
            entry["target_event_id"] = targetEventId.uuidString
        }
        if let targetUserId {
            entry["target_user_id"] = targetUserId.uuidString
        }
        do {
            try await client.from("activity_feed")
                .insert(entry)
                .execute()
        } catch {
            print("Error logging activity: \(error)")
        }
    }
}
