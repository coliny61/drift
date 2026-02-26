import Foundation
import Supabase

@Observable
final class EventService {
    private let client: SupabaseClient

    var events: [Event] = []
    var featuredEvents: [Event] = []
    var isLoading = false
    var error: Error?

    init(client: SupabaseClient) {
        self.client = client
    }

    /// Set to `true` to use local seed data instead of Supabase.
    /// Flip to `false` once your Supabase project is configured.
    static let useSeedData = false

    func fetchEvents() async {
        isLoading = true
        error = nil

        if Self.useSeedData {
            events = SeedData.events
            featuredEvents = events.filter { $0.isCurrentlyFeatured }
            isLoading = false
            return
        }

        do {
            let response: [Event] = try await client.from("events")
                .select()
                .eq("status", value: "upcoming")
                .eq("approval_status", value: "approved")
                .order("start_time", ascending: true)
                .execute()
                .value
            events = response
            featuredEvents = response.filter { $0.isCurrentlyFeatured }
        } catch let fetchError {
            error = fetchError
            print("Error fetching events: \(fetchError)")
            // Fallback to seed data
            events = SeedData.events
            featuredEvents = events.filter { $0.isCurrentlyFeatured }
        }
        isLoading = false
    }

    func fetchEvent(id: UUID) async -> Event? {
        if Self.useSeedData {
            return SeedData.events.first { $0.id == id }
        }
        do {
            let event: Event = try await client.from("events")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value
            return event
        } catch {
            print("Error fetching event: \(error)")
            return SeedData.events.first { $0.id == id }
        }
    }

    func fetchEventsByCategory(_ category: String) async -> [Event] {
        do {
            let response: [Event] = try await client.from("events")
                .select()
                .eq("category", value: category)
                .eq("status", value: "upcoming")
                .order("start_time", ascending: true)
                .execute()
                .value
            return response
        } catch {
            print("Error fetching by category: \(error)")
            return []
        }
    }

    func fetchEventsByNeighborhood(_ neighborhood: String) async -> [Event] {
        do {
            let response: [Event] = try await client.from("events")
                .select()
                .eq("neighborhood", value: neighborhood)
                .eq("status", value: "upcoming")
                .order("start_time", ascending: true)
                .execute()
                .value
            return response
        } catch {
            print("Error fetching by neighborhood: \(error)")
            return []
        }
    }

    func searchEvents(query: String) async -> [Event] {
        if Self.useSeedData {
            let q = query.lowercased()
            return SeedData.events.filter {
                $0.title.lowercased().contains(q) ||
                $0.description.lowercased().contains(q) ||
                $0.locationName.lowercased().contains(q) ||
                $0.neighborhood.lowercased().contains(q) ||
                $0.category.lowercased().contains(q)
            }
        }
        do {
            let response: [Event] = try await client.from("events")
                .select()
                .or("title.ilike.%\(query)%,description.ilike.%\(query)%,location_name.ilike.%\(query)%")
                .eq("status", value: "upcoming")
                .order("start_time", ascending: true)
                .execute()
                .value
            return response
        } catch {
            print("Error searching events: \(error)")
            let q = query.lowercased()
            return SeedData.events.filter {
                $0.title.lowercased().contains(q) ||
                $0.description.lowercased().contains(q) ||
                $0.locationName.lowercased().contains(q)
            }
        }
    }
}
