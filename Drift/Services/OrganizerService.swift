import Foundation
import Supabase

@Observable
final class OrganizerService {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchOrganizer(id: UUID) async -> Organizer? {
        if EventService.useSeedData {
            return SeedData.organizers.first { $0.id == id }
        }
        do {
            let organizer: Organizer = try await client.from("organizers")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value
            return organizer
        } catch {
            print("Error fetching organizer: \(error)")
            return SeedData.organizers.first { $0.id == id }
        }
    }

    func fetchOrganizerEvents(organizerId: UUID) async -> [Event] {
        if EventService.useSeedData {
            return SeedData.events.filter { $0.organizerId == organizerId }
        }
        do {
            let events: [Event] = try await client.from("events")
                .select()
                .eq("organizer_id", value: organizerId.uuidString)
                .eq("status", value: "upcoming")
                .order("start_time", ascending: true)
                .execute()
                .value
            return events
        } catch {
            print("Error fetching organizer events: \(error)")
            return SeedData.events.filter { $0.organizerId == organizerId }
        }
    }

    func getFollowerCount(organizerId: UUID) async -> Int {
        do {
            let count = try await client.from("organizer_follows")
                .select("*", head: true, count: .exact)
                .eq("organizer_id", value: organizerId.uuidString)
                .execute()
                .count
            return count ?? 0
        } catch {
            return 0
        }
    }

    func isFollowing(userId: UUID, organizerId: UUID) async -> Bool {
        do {
            let count = try await client.from("organizer_follows")
                .select("*", head: true, count: .exact)
                .eq("user_id", value: userId.uuidString)
                .eq("organizer_id", value: organizerId.uuidString)
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

    func createOrganizer(_ organizer: Organizer) async throws {
        try await client.from("organizers")
            .insert(organizer)
            .execute()
    }

    func updateOrganizer(_ organizer: Organizer) async throws {
        try await client.from("organizers")
            .update(organizer)
            .eq("id", value: organizer.id.uuidString)
            .execute()
    }

    func fetchMyOrganizers(profileId: UUID) async -> [Organizer] {
        do {
            let orgs: [Organizer] = try await client.from("organizers")
                .select()
                .eq("profile_id", value: profileId.uuidString)
                .order("name", ascending: true)
                .execute()
                .value
            return orgs
        } catch {
            print("Error fetching my organizers: \(error)")
            return []
        }
    }

    func getFollowedOrganizerIds(userId: UUID) async -> Set<UUID> {
        do {
            struct FollowRow: Decodable {
                let organizerId: UUID
                enum CodingKeys: String, CodingKey {
                    case organizerId = "organizer_id"
                }
            }
            let rows: [FollowRow] = try await client.from("organizer_follows")
                .select("organizer_id")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            return Set(rows.map(\.organizerId))
        } catch {
            return []
        }
    }
}
