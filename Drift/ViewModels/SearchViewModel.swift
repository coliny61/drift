import Foundation

@Observable
final class SearchViewModel {
    private let eventService: EventService

    var query = ""
    var results: [Event] = []
    var recentSearches: [String] = []
    var isSearching = false

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

    init(eventService: EventService) {
        self.eventService = eventService
        loadRecentSearches()
    }

    func search() async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            unfilteredResults = []
            return
        }

        isSearching = true
        unfilteredResults = await eventService.searchEvents(query: query)
        applyLocalFilters()
        saveRecentSearch(query)
        isSearching = false
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
