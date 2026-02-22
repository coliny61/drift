import Foundation

@Observable
final class ActivityFeedViewModel {
    private let activityService: ActivityService

    var feedItems: [ActivityFeedItem] { activityService.feedItems }
    var isLoading: Bool { activityService.isLoading }

    init(activityService: ActivityService) {
        self.activityService = activityService
    }

    func loadFeed(userId: UUID) async {
        await activityService.fetchFeed(userId: userId)
    }

    func refresh(userId: UUID) async {
        await activityService.fetchFeed(userId: userId)
    }
}
