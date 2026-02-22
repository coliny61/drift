import Foundation
import Supabase

@Observable
final class RSVPService {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func rsvp(eventId: UUID, userId: UUID, status: RSVP.RSVPStatus) async throws {
        try await client.from("rsvps")
            .upsert([
                "event_id": eventId.uuidString,
                "user_id": userId.uuidString,
                "status": status.rawValue
            ])
            .execute()
    }

    func removeRSVP(eventId: UUID, userId: UUID) async throws {
        try await client.from("rsvps")
            .delete()
            .eq("event_id", value: eventId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func getUserRSVP(eventId: UUID, userId: UUID) async -> RSVP? {
        do {
            let rsvp: RSVP = try await client.from("rsvps")
                .select()
                .eq("event_id", value: eventId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value
            return rsvp
        } catch {
            return nil
        }
    }

    func getEventAttendees(eventId: UUID) async -> [Profile] {
        do {
            let rsvps: [RSVP] = try await client.from("rsvps")
                .select("*, profiles(*)")
                .eq("event_id", value: eventId.uuidString)
                .eq("status", value: "going")
                .execute()
                .value
            // In production, this would use a joined query
            return []
        } catch {
            return []
        }
    }

    func getUserUpcomingRSVPs(userId: UUID) async -> [RSVP] {
        do {
            let rsvps: [RSVP] = try await client.from("rsvps")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            return rsvps
        } catch {
            return []
        }
    }
}
