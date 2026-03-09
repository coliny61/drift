import Foundation

@Observable
final class BookmarkViewModel {
    private static let storageKey = "drift_bookmarked_events"

    var bookmarkedIds: Set<UUID> = []

    init() {
        load()
    }

    func isBookmarked(_ eventId: UUID) -> Bool {
        bookmarkedIds.contains(eventId)
    }

    func toggle(_ eventId: UUID) {
        if bookmarkedIds.contains(eventId) {
            bookmarkedIds.remove(eventId)
        } else {
            bookmarkedIds.insert(eventId)
        }
        save()
        HapticManager.selection()
    }

    private func save() {
        let strings = bookmarkedIds.map(\.uuidString)
        UserDefaults.standard.set(Array(strings), forKey: Self.storageKey)
    }

    private func load() {
        guard let strings = UserDefaults.standard.stringArray(forKey: Self.storageKey) else { return }
        bookmarkedIds = Set(strings.compactMap { UUID(uuidString: $0) })
    }
}
