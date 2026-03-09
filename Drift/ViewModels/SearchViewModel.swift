import Foundation
import Combine

@Observable
final class SearchViewModel {
    private let eventService: EventService
    private let locationManager: LocationManager

    var query = "" {
        didSet { debouncedSearch() }
    }
    var results: [Event] = []
    var recentSearches: [String] = []
    var isSearching = false
    var isLoadingMore = false
    var hasMoreResults = true

    private let pageSize = 20
    private var currentSearchOffset = 0

    // Filters
    var selectedCategories: Set<Category> = []
    var selectedCity: String?
    var maxDistance: Double = 25 // miles
    var dateRange: DateRange = .anytime
    var timeOfDay: TimeOfDay = .anytime
    var alcoholFreeOnly = false
    var freeOnly = false
    var showFilters = false

    // Unfiltered results for re-applying filters
    private var unfilteredResults: [Event] = []

    // Debounce
    private var debounceTask: Task<Void, Never>?

    enum DateRange: String, CaseIterable {
        case anytime = "Anytime"
        case today = "Today"
        case thisWeek = "This Week"
        case thisWeekend = "This Weekend"
        case thisMonth = "This Month"
    }

    enum TimeOfDay: String, CaseIterable {
        case anytime = "Any Time"
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
    }

    init(eventService: EventService, locationManager: LocationManager) {
        self.eventService = eventService
        self.locationManager = locationManager
        loadRecentSearches()
        loadSavedFilters()
    }

    private func debouncedSearch() {
        debounceTask?.cancel()
        let q = query
        guard !q.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            unfilteredResults = []
            return
        }
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await search()
        }
    }

    func search() async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            unfilteredResults = []
            return
        }

        isSearching = true
        currentSearchOffset = 0
        hasMoreResults = true

        let page = await eventService.searchEventsPage(query: query, offset: 0, limit: pageSize)
        unfilteredResults = page
        hasMoreResults = page.count >= pageSize
        currentSearchOffset = page.count

        applyLocalFilters()
        saveRecentSearch(query)
        isSearching = false
    }

    func loadMoreResults() async {
        guard !isLoadingMore, hasMoreResults, !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoadingMore = true

        let page = await eventService.searchEventsPage(query: query, offset: currentSearchOffset, limit: pageSize)
        unfilteredResults.append(contentsOf: page)
        hasMoreResults = page.count >= pageSize
        currentSearchOffset += page.count
        applyLocalFilters()

        isLoadingMore = false
    }

    func applyLocalFilters() {
        var filtered = unfilteredResults

        if !selectedCategories.isEmpty {
            filtered = filtered.filter { event in
                selectedCategories.contains(where: { $0.slug == event.category })
            }
        }

        if let city = selectedCity {
            filtered = filtered.filter { event in
                event.city?.localizedCaseInsensitiveCompare(city) == .orderedSame
            }
        }

        if alcoholFreeOnly {
            filtered = filtered.filter { $0.isAlcoholFree }
        }

        if freeOnly {
            filtered = filtered.filter { $0.isFree }
        }

        // Distance filter — only apply if user has location and distance is not max
        if maxDistance < 25, locationManager.userLocation != nil {
            filtered = filtered.filter { event in
                guard let distance = locationManager.distanceTo(lat: event.locationLat, lng: event.locationLng) else {
                    return true
                }
                return distance <= maxDistance
            }
        }

        switch dateRange {
        case .anytime: break
        case .today:
            filtered = filtered.filter { Calendar.current.isDateInToday($0.startTime) }
        case .thisWeek:
            let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: .now)!
            filtered = filtered.filter { $0.startTime <= endOfWeek }
        case .thisWeekend:
            let calendar = Calendar.current
            filtered = filtered.filter {
                let weekday = calendar.component(.weekday, from: $0.startTime)
                return weekday == 1 || weekday == 7 // Sun or Sat
            }
        case .thisMonth:
            let endOfMonth = Calendar.current.date(byAdding: .month, value: 1, to: .now)!
            filtered = filtered.filter { $0.startTime <= endOfMonth }
        }

        switch timeOfDay {
        case .anytime: break
        case .morning:
            filtered = filtered.filter {
                let hour = Calendar.current.component(.hour, from: $0.startTime)
                return hour >= 5 && hour < 12
            }
        case .afternoon:
            filtered = filtered.filter {
                let hour = Calendar.current.component(.hour, from: $0.startTime)
                return hour >= 12 && hour < 17
            }
        case .evening:
            filtered = filtered.filter {
                let hour = Calendar.current.component(.hour, from: $0.startTime)
                return hour >= 17 || hour < 5
            }
        }

        results = filtered
    }

    func clearFilters() {
        selectedCategories = []
        selectedCity = nil
        maxDistance = 25
        dateRange = .anytime
        timeOfDay = .anytime
        alcoholFreeOnly = false
        freeOnly = false
        saveFilters()
    }

    // MARK: - Filter Persistence

    func saveFilters() {
        let defaults = UserDefaults.standard
        let categorySlugs = selectedCategories.map(\.slug)
        defaults.set(categorySlugs, forKey: "drift_filter_categories")
        defaults.set(selectedCity, forKey: "drift_filter_city")
        defaults.set(maxDistance, forKey: "drift_filter_distance")
        defaults.set(dateRange.rawValue, forKey: "drift_filter_date_range")
        defaults.set(timeOfDay.rawValue, forKey: "drift_filter_time_of_day")
        defaults.set(alcoholFreeOnly, forKey: "drift_filter_alcohol_free")
        defaults.set(freeOnly, forKey: "drift_filter_free_only")
    }

    private func loadSavedFilters() {
        let defaults = UserDefaults.standard
        if let slugs = defaults.stringArray(forKey: "drift_filter_categories") {
            selectedCategories = Set(Category.allCases.filter { slugs.contains($0.slug) })
        }
        selectedCity = defaults.string(forKey: "drift_filter_city")
        let dist = defaults.double(forKey: "drift_filter_distance")
        if dist > 0 { maxDistance = dist }
        if let raw = defaults.string(forKey: "drift_filter_date_range"),
           let dr = DateRange(rawValue: raw) {
            dateRange = dr
        }
        if let raw = defaults.string(forKey: "drift_filter_time_of_day"),
           let tod = TimeOfDay(rawValue: raw) {
            timeOfDay = tod
        }
        alcoholFreeOnly = defaults.bool(forKey: "drift_filter_alcohol_free")
        freeOnly = defaults.bool(forKey: "drift_filter_free_only")
    }

    private func saveRecentSearch(_ query: String) {
        if !recentSearches.contains(query) {
            recentSearches.insert(query, at: 0)
            if recentSearches.count > 10 { recentSearches.removeLast() }
            UserDefaults.standard.set(recentSearches, forKey: "drift_recent_searches")
        }
    }

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "drift_recent_searches") ?? []
    }

    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: "drift_recent_searches")
    }
}
