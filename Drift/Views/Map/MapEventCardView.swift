import SwiftUI

struct MapEventCardView: View {
    let event: Event

    var body: some View {
        HStack(spacing: 14) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: event.categoryEnum?.icon ?? "star")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(categoryColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 9))
                    Text(event.startTime.relativeDescription)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(AppConstants.Colors.textSecondary)

                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 9))
                    Text(event.locationName)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundStyle(AppConstants.Colors.textTertiary)
            }

            Spacer()

            // RSVP count
            VStack(spacing: 3) {
                Text("\(event.rsvpCount)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(categoryColor)
                Text("going")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(AppConstants.Colors.textTertiary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppConstants.Colors.textTertiary)
        }
        .padding(16)
        .background(AppConstants.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }

    private var categoryColor: Color {
        Color(hex: event.categoryEnum?.color ?? "FF6B35")
    }
}
