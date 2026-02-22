import Foundation
import Supabase

@Observable
final class ProfileService {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchProfile(id: UUID) async -> Profile? {
        do {
            let profile: Profile = try await client.from("profiles")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value
            return profile
        } catch {
            print("Error fetching profile: \(error)")
            return nil
        }
    }

    func followUser(followerId: UUID, followingId: UUID) async throws {
        try await client.from("follows")
            .insert(["follower_id": followerId.uuidString, "following_id": followingId.uuidString])
            .execute()
    }

    func unfollowUser(followerId: UUID, followingId: UUID) async throws {
        try await client.from("follows")
            .delete()
            .eq("follower_id", value: followerId.uuidString)
            .eq("following_id", value: followingId.uuidString)
            .execute()
    }

    func getFollowerCount(userId: UUID) async -> Int {
        do {
            let count = try await client.from("follows")
                .select("*", head: true, count: .exact)
                .eq("following_id", value: userId.uuidString)
                .execute()
                .count
            return count ?? 0
        } catch {
            return 0
        }
    }

    func getFollowingCount(userId: UUID) async -> Int {
        do {
            let count = try await client.from("follows")
                .select("*", head: true, count: .exact)
                .eq("follower_id", value: userId.uuidString)
                .execute()
                .count
            return count ?? 0
        } catch {
            return 0
        }
    }

    func isFollowing(followerId: UUID, followingId: UUID) async -> Bool {
        do {
            let count = try await client.from("follows")
                .select("*", head: true, count: .exact)
                .eq("follower_id", value: followerId.uuidString)
                .eq("following_id", value: followingId.uuidString)
                .execute()
                .count
            return (count ?? 0) > 0
        } catch {
            return false
        }
    }

    func followOrganizer(userId: UUID, organizerId: UUID) async throws {
        try await client.from("organizer_follows")
            .insert(["user_id": userId.uuidString, "organizer_id": organizerId.uuidString])
            .execute()
    }

    func unfollowOrganizer(userId: UUID, organizerId: UUID) async throws {
        try await client.from("organizer_follows")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("organizer_id", value: organizerId.uuidString)
            .execute()
    }
}
