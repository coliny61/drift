import Foundation

@Observable
final class ProfileViewModel {
    private let profileService: ProfileService
    private let rsvpService: RSVPService
    private let eventService: EventService

    var profile: Profile?
    var upcomingRSVPs: [RSVP] = []
    var upcomingEvents: [Event] = []
    var followerCount = 0
    var followingCount = 0
    var isFollowing = false
    var isLoading = false
    var isOwnProfile = false

    init(profileService: ProfileService, rsvpService: RSVPService, eventService: EventService) {
        self.profileService = profileService
        self.rsvpService = rsvpService
        self.eventService = eventService
    }

    func loadProfile(userId: UUID, currentUserId: UUID?) async {
        isLoading = true
        isOwnProfile = userId == currentUserId

        profile = await profileService.fetchProfile(id: userId)

        async let followers = profileService.getFollowerCount(userId: userId)
        async let following = profileService.getFollowingCount(userId: userId)
        async let rsvps = rsvpService.getUserUpcomingRSVPs(userId: userId)

        followerCount = await followers
        followingCount = await following
        upcomingRSVPs = await rsvps

        // Resolve RSVP event IDs to Event objects (batch fetch)
        var allEventIds = upcomingRSVPs.map(\.eventId)

        // Also include locally stored RSVPs (browse-without-account mode)
        let localRSVPs = EventDetailViewModel.localRSVPs()
        for (eventIdString, _) in localRSVPs {
            if let eventId = UUID(uuidString: eventIdString),
               !allEventIds.contains(eventId) {
                allEventIds.append(eventId)
            }
        }

        let events = await eventService.fetchEventsByIds(allEventIds)
        upcomingEvents = events.sorted { $0.startTime < $1.startTime }

        if let currentUserId, !isOwnProfile {
            isFollowing = await profileService.isFollowing(followerId: currentUserId, followingId: userId)
        }

        isLoading = false
    }

    func toggleFollow(currentUserId: UUID, targetUserId: UUID) async {
        if isFollowing {
            try? await profileService.unfollowUser(followerId: currentUserId, followingId: targetUserId)
            isFollowing = false
            followerCount -= 1
        } else {
            try? await profileService.followUser(followerId: currentUserId, followingId: targetUserId)
            isFollowing = true
            followerCount += 1
        }
        HapticManager.impact(.medium)
    }
}
