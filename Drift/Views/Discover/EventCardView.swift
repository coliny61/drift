import SwiftUI

struct EventCardView: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover image
            ZStack(alignment: .topLeading) {
                if let urlString = event.coverImageUrl, let url = URL(string: urlString) {
                    CachedAsyncImage(url: url) {
                        gradientPlaceholder
                    }
                    .frame(height: 200)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [.black.opacity(0.15), .clear, .black.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                } else {
                    gradientPlaceholder
                }

                // Tags overlay
                VStack {
                    HStack(spacing: 6) {
                        // Category pill
                        HStack(spacing: 4) {
                            Image(systemName: categoryIcon)
                                .font(.system(size: 9, weight: .bold))
                            Text(event.categoryEnum?.displayName ?? event.category)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .textCase(.uppercase)
                                .tracking(0.3)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial)
                        .background(categoryColor.opacity(0.4))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())

                        if event.isAlcoholFree {
                            Text("AF")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(.ultraThinMaterial)
                                .background(AppConstants.Colors.alcoholFreeBadge.opacity(0.4))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }

                        Spacer()

                        // Price badge
                        Text(event.isFree ? "FREE" : event.priceFormatted)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .tracking(0.5)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial)
                            .background(event.isFree ? AppConstants.Colors.freeBadge.opacity(0.4) : Color.black.opacity(0.3))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    .padding(12)

                    Spacer()

                    // Bottom date overlay on image
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11, weight: .semibold))
                            Text(event.startTime.relativeDescription)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)

                        Spacer()

                        if event.rsvpCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 10))
                                Text("\(event.rsvpCount)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
                }
            }
            .frame(height: 200)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16))

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.system(.headline, design: .default, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                // Location
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(categoryColor)
                    Text(event.locationName)
                        .font(.subheadline)
                        .lineLimit(1)

                    if !event.neighborhood.isEmpty {
                        Text("\u{00B7}")
                            .fontWeight(.bold)
                        Text(event.neighborhood)
                            .font(.subheadline)
                    }
                }
                .foregroundStyle(AppConstants.Colors.textSecondary)

                // Sponsor label
                if let label = event.sponsorDisplayLabel {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                        Text(label)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }
                    .foregroundStyle(AppConstants.Colors.accent)
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(AppConstants.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityCardLabel)
    }

    private var accessibilityCardLabel: String {
        var parts = [event.title]
        if let cat = event.categoryEnum { parts.append(cat.displayName) }
        parts.append(event.startTime.relativeDescription)
        parts.append(event.locationName)
        if !event.neighborhood.isEmpty { parts.append(event.neighborhood) }
        parts.append(event.isFree ? "Free" : event.priceFormatted)
        if event.isAlcoholFree { parts.append("Alcohol free") }
        if event.rsvpCount > 0 { parts.append("\(event.rsvpCount) going") }
        return parts.joined(separator: ", ")
    }

    private var gradientPlaceholder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [categoryColor.opacity(0.7), categoryColor.opacity(0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 200)
            .overlay {
                Image(systemName: categoryIcon)
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.2))
            }
    }

    private var categoryColor: Color {
        Color(hex: event.categoryEnum?.color ?? "FF6B35")
    }

    private var categoryIcon: String {
        event.categoryEnum?.icon ?? "star"
    }
}
