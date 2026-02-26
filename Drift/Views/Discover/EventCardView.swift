import SwiftUI

struct EventCardView: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover image
            ZStack(alignment: .topLeading) {
                if let urlString = event.coverImageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 180)
                                .clipped()
                        case .failure:
                            gradientPlaceholder
                        case .empty:
                            gradientPlaceholder
                                .overlay {
                                    ProgressView()
                                        .tint(.white.opacity(0.5))
                                }
                        @unknown default:
                            gradientPlaceholder
                        }
                    }
                    .frame(height: 180)
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .clear, Color.black.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                } else {
                    gradientPlaceholder
                }

                // Tags overlay
                HStack(spacing: 6) {
                    // Category pill
                    Text(event.categoryEnum?.displayName ?? event.category)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(categoryColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())

                    if event.isAlcoholFree {
                        Text("Alcohol-Free")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: "34D399"))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    // Price badge
                    Text(event.isFree ? "FREE" : event.priceFormatted)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(event.isFree ? Color(hex: "60A5FA") : Color(hex: "2A2A2A").opacity(0.9))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                // Date and time
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(event.startTime.relativeDescription)
                        .font(.subheadline)
                }
                .foregroundStyle(Color(hex: "9CA3AF"))

                // Location
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption)
                    Text(event.locationName)
                        .font(.subheadline)
                        .lineLimit(1)

                    if !event.neighborhood.isEmpty {
                        Text("\u{00B7}")
                        Text(event.neighborhood)
                            .font(.subheadline)
                    }
                }
                .foregroundStyle(Color(hex: "9CA3AF"))

                // Bottom row: attendees + organizer
                HStack {
                    // RSVP count
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(event.rsvpCount) going")
                            .font(.caption)
                    }
                    .foregroundStyle(Color(hex: "9CA3AF"))

                    Spacer()

                    if let label = event.sponsorDisplayLabel {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                            Text(label)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(Color(hex: "FF6B35"))
                    }
                }
            }
            .padding(14)
        }
        .background(Color(hex: "1A1A1A"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var gradientPlaceholder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [categoryColor.opacity(0.6), categoryColor.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 180)
            .overlay(alignment: .center) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(.white.opacity(0.3))
            }
    }

    private var categoryColor: Color {
        Color(hex: event.categoryEnum?.color ?? "FF6B35")
    }

    private var categoryIcon: String {
        event.categoryEnum?.icon ?? "star"
    }
}
