import Foundation
import Supabase

@Observable
final class DiscoverViewModel {
    private let eventService: EventService
    private let organizerService: OrganizerService
    private let rsvpService: RSVPService
    private let locationManager: LocationManager

    var events: [Event] = []
    var filteredEvents: [Event] = []
    var featuredEvents: [Event] = []
    var selectedCategory: Category?
    var feedMode: FeedMode = .all
    var isLoading = false
    var isLoadingMore = false
    var hasMoreEvents = true
    var error: Error?

    private let pageSize = 20
    private var currentOffset = 0

    // User context for scoring
    var userInterests: [String] = []
    var userCity: String?
    var followedOrganizerIds: Set<UUID> = []
    var rsvpdOrganizerIds: Set<UUID> = []

    enum FeedMode: String, CaseIterable {
        case forYou = "For You"
        case all = "All"
        case thisWeek = "This Week"
    }

    init(eventService: EventService, organizerService: OrganizerService, rsvpService: RSVPService, locationManager: LocationManager) {
        self.eventService = eventService
        self.organizerService = organizerService
        self.rsvpService = rsvpService
        self.locationManager = locationManager
    }

    func loadEvents() async {
        isLoading = true
        error = nil
        currentOffset = 0
        hasMoreEvents = true

        // Show cached data instantly while network loads
        if events.isEmpty, let cached = EventCacheService.load() {
            events = cached
            featuredEvents = cached.filter { $0.isCurrentlyFeatured }
            applyFilters()
        }

        // Featured events — small set, fetch all
        await eventService.fetchEvents()
        featuredEvents = eventService.featuredEvents

        // First page
        let page = await eventService.fetchEventsPage(offset: 0, limit: pageSize)
        events = page
        hasMoreEvents = page.count >= pageSize
        currentOffset = page.count

        if events.isEmpty && eventService.error != nil {
            error = eventService.error
        }
        applyFilters()
        isLoading = false
    }

    func loadMoreEvents() async {
        guard !isLoadingMore, hasMoreEvents else { return }
        isLoadingMore = true

        let page = await eventService.fetchEventsPage(offset: currentOffset, limit: pageSize)
        events.append(contentsOf: page)
        hasMoreEvents = page.count >= pageSize
        currentOffset += page.count
        applyFilters()

        isLoadingMore = false
    }

    /// Populate user context for For You scoring. Call after auth/onboarding is ready.
    func loadUserContext(userId: UUID) async {
        // Interests from onboarding
        if let saved = UserDefaults.standard.array(forKey: "drift_selected_interests") as? [String] {
            userInterests = saved
        }

        // City from onboarding
        userCity = UserDefaults.standard.string(forKey: "drift_selected_city")

        // Followed organizers
        followedOrganizerIds = await organizerService.getFollowedOrganizerIds(userId: userId)

        // RSVP'd organizer IDs (get user's RSVPs, then map event→organizer)
        let rsvps = await rsvpService.getUserUpcomingRSVPs(userId: userId)
        let rsvpEventIds = Set(rsvps.map(\.eventId))
        let rsvpdOrgs = events.filter { rsvpEventIds.contains($0.id) }.map(\.organizerId)
        rsvpdOrganizerIds = Set(rsvpdOrgs)

        // Re-apply filters with updated context
        applyFilters()
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
        events.sorted { a, b in
            let scoreA = calculateScore(for: a)
            let scoreB = calculateScore(for: b)
            return scoreA > scoreB
        }
    }

    /// Deterministic, explainable For You scoring
    private func calculateScore(for event: Event) -> Double {
        let W = AppConstants.ForYouWeights.self
        var score = W.base

        // Interest match: category matches user's onboarding interests
        if userInterests.contains(event.category) {
            score += W.interestMatch
        }

        // City match: event in user's selected city
        if let userCity, let eventCity = event.city, !eventCity.isEmpty,
           eventCity.localizedCaseInsensitiveCompare(userCity) == .orderedSame {
            score += W.cityMatch
        }

        // Follows organizer
        if followedOrganizerIds.contains(event.organizerId) {
            score += W.followsOrganizer
        }

        // Past RSVP to this organizer
        if rsvpdOrganizerIds.contains(event.organizerId) {
            score += W.pastRSVPOrganizer
        }

        // Freshness: events sooner score higher (linear decay over 14 days)
        let daysUntil = max(0, event.startTime.daysUntil)
        if daysUntil < 14 {
            let freshnessRatio = 1.0 - (Double(daysUntil) / 14.0)
            score += W.freshness * freshnessRatio
        }

        // Featured boost
        if event.isCurrentlyFeatured {
            score += W.featuredBoost
        }

        return score
    }
}
