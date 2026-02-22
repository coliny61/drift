import Foundation
import Supabase

@Observable
final class DiscoverViewModel {
    private let eventService: EventService
    private let locationManager: LocationManager

    var events: [Event] = []
    var filteredEvents: [Event] = []
    var featuredEvents: [Event] = []
    var selectedCategory: Category?
    var feedMode: FeedMode = .all
    var isLoading = false
    var error: Error?

    enum FeedMode: String, CaseIterable {
        case forYou = "For You"
        case all = "All"
        case thisWeek = "This Week"
    }

    init(eventService: EventService, locationManager: LocationManager) {
        self.eventService = eventService
        self.locationManager = locationManager
    }

    func loadEvents() async {
        isLoading = true
        await eventService.fetchEvents()
        events = eventService.events
        featuredEvents = eventService.featuredEvents
        applyFilters()
        isLoading = false
    }

    func selectCategory(_ category: Category?) {
        selectedCategory = category
        applyFilters()
    }

    func setFeedMode(_ mode: FeedMode) {
        feedMode = mode
        applyFilters()
    }

    private func applyFilters() {
        var result = events

        // Category filter
        if let category = selectedCategory {
            result = result.filter { $0.category == category.slug }
        }

        // Feed mode filter
        switch feedMode {
        case .forYou:
            result = sortByForYouScore(result)
        case .all:
            break // Already sorted by startTime from API
        case .thisWeek:
            let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
            result = result.filter { $0.startTime <= endOfWeek }
        }

        filteredEvents = result
    }

    private func sortByForYouScore(_ events: [Event]) -> [Event] {
        // Simple scoring without user profile for now
        events.sorted { a, b in
            let scoreA = calculateScore(for: a)
            let scoreB = calculateScore(for: b)
            return scoreA > scoreB
        }
    }

    private func calculateScore(for event: Event) -> Double {
        var score: Double = 0

        // Proximity scoring
        if let distance = locationManager.distanceTo(lat: event.locationLat, lng: event.locationLng) {
            if distance < 5 { score += AppConstants.ForYouWeights.proximityClose }
            else if distance < 10 { score += AppConstants.ForYouWeights.proximityMedium }
            else if distance < 20 { score += AppConstants.ForYouWeights.proximityFar }
        }

        // Trending
        if event.rsvpCount > 20 { score += AppConstants.ForYouWeights.trendingHigh }
        else if event.rsvpCount > 10 { score += AppConstants.ForYouWeights.trendingMedium }

        // Recency
        let daysUntil = event.startTime.daysUntil
        if daysUntil < 2 { score += AppConstants.ForYouWeights.recencySoon }
        else if daysUntil < 7 { score += AppConstants.ForYouWeights.recencyWeek }

        // Featured boost
        if event.isFeatured { score += 3.0 }

        return score
    }
}
