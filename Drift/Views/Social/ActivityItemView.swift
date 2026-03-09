import SwiftUI

struct ActivityItemView: View {
    let item: ActivityFeedItem

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(url: item.actor?.avatarUrl, size: 44, fallbackInitials: "?")

            VStack(alignment: .leading, spacing: 4) {
                Text(activityText)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(item.createdAt.relativeDescription)
                    .font(.caption)
                    .foregroundStyle(AppConstants.Colors.textTertiary)
            }

            Spacer()

            Image(systemName: actionIcon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(actionColor)
                .frame(width: 36, height: 36)
                .background(actionColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal)
        .padding(.vertical, 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(activityText.description), \(item.createdAt.relativeDescription)")
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

    private var actionColor: Color {
        switch item.actionType {
        case "rsvp": return AppConstants.Colors.success
        case "follow": return AppConstants.Colors.info
        case "photo_upload": return AppConstants.Colors.pink
        case "new_event": return AppConstants.Colors.accent
        default: return AppConstants.Colors.textSecondary
        }
    }
}
