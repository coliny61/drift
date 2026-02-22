import SwiftUI

struct ActivityItemView: View {
    let item: ActivityFeedItem

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(url: item.actor?.avatarUrl, size: 40, fallbackInitials: "?")

            VStack(alignment: .leading, spacing: 4) {
                Text(activityText)
                    .font(.subheadline)
                    .foregroundStyle(.white)

                Text(item.createdAt.relativeDescription)
                    .font(.caption)
                    .foregroundStyle(Color(hex: "9CA3AF"))
            }

            Spacer()

            Image(systemName: actionIcon)
                .foregroundStyle(Color(hex: "FF6B35"))
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var activityText: AttributedString {
        var result = AttributedString(item.actor?.displayName ?? "Someone")
        result.font = .subheadline.bold()

        switch item.actionType {
        case "rsvp":
            result += AttributedString(" is going to ")
            var eventName = AttributedString(item.targetEvent?.title ?? "an event")
            eventName.font = .subheadline.bold()
            result += eventName
        case "follow":
            result += AttributedString(" started following someone")
        case "photo_upload":
            result += AttributedString(" shared a photo")
        case "new_event":
            result += AttributedString(" posted a new event")
        default:
            result += AttributedString(" did something")
        }

        return result
    }

    private var actionIcon: String {
        switch item.actionType {
        case "rsvp": return "hand.thumbsup.fill"
        case "follow": return "person.badge.plus"
        case "photo_upload": return "photo"
        case "new_event": return "calendar.badge.plus"
        default: return "bell"
        }
    }
}
