import SwiftUI

struct MapEventCardView: View {
    let event: Event

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 56, height: 56)
                Image(systemName: event.categoryEnum?.icon ?? "star")
                    .font(.title2)
                    .foregroundStyle(categoryColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(event.startTime.relativeDescription)
                    .font(.caption)
                    .foregroundStyle(Color(hex: "9CA3AF"))

                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                    Text(event.locationName)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundStyle(Color(hex: "9CA3AF"))
            }

            Spacer()

            // RSVP count + arrow
            VStack(spacing: 4) {
                Text("\(event.rsvpCount)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(categoryColor)
                Text("going")
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "9CA3AF"))
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color(hex: "9CA3AF"))
        }
        .padding(14)
        .background(Color(hex: "1A1A1A"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }

    private var categoryColor: Color {
        Color(hex: event.categoryEnum?.color ?? "FF6B35")
    }
}
