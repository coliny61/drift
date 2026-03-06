import Foundation

@Observable
final class ActivityFeedViewModel {
    private let activityService: ActivityService
    private var pollingTask: Task<Void, Never>?

    var feedItems: [ActivityFeedItem] { activityService.feedItems }
    var isLoading: Bool { activityService.isLoading }

    private static let lastViewedKey = "drift_activity_last_viewed"

    var unreadCount: Int {
        let lastViewed = UserDefaults.standard.object(forKey: Self.lastViewedKey) as? Date ?? .distantPast
        return feedItems.filter { $0.createdAt > lastViewed }.count
    }

    func markAsRead() {
        UserDefaults.standard.set(Date(), forKey: Self.lastViewedKey)
    }

    init(activityService: ActivityService) {
        self.activityService = activityService
    }

    func loadFeed(userId: UUID) async {
        await activityService.fetchFeed(userId: userId)
    }

    func refresh(userId: UUID) async {
        await activityService.fetchFeed(userId: userId)
    }

    func startPolling(userId: UUID) {
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled else { break }
                await activityService.fetchFeed(userId: userId)
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func logRSVP(userId: UUID, eventId: UUID) async {
        await activityService.logActivity(actorId: userId, actionType: "rsvp", targetEventId: eventId)
    }

    func logFollow(userId: UUID, targetUserId: UUID) async {
        await activityService.logActivity(actorId: userId, actionType: "follow", targetUserId: targetUserId)
    }
}
