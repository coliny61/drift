import SwiftUI

struct RSVPButtonView: View {
    let isGoing: Bool
    let isInterested: Bool
    let attendeeCount: Int
    let onGoing: () -> Void
    let onInterested: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                // Going button
                Button(action: onGoing) {
                    HStack(spacing: 8) {
                        Image(systemName: isGoing ? "checkmark.circle.fill" : "hand.raised.fill")
                            .font(.system(size: 15, weight: .semibold))
                        Text(isGoing ? "Going!" : "I'm Going")
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        isGoing
                            ? AppConstants.Colors.success
                            : AppConstants.Colors.accent
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(
                        color: (isGoing ? AppConstants.Colors.success : AppConstants.Colors.accent).opacity(0.3),
                        radius: 8, x: 0, y: 4
                    )
                }
                .accessibilityLabel(isGoing ? "Going" : "RSVP as going")
                .accessibilityAddTraits(isGoing ? .isSelected : [])

                // Interested button
                Button(action: onInterested) {
                    HStack(spacing: 6) {
                        Image(systemName: isInterested ? "star.fill" : "star")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Interested")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(isInterested ? AppConstants.Colors.interested : AppConstants.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppConstants.Colors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(isInterested ? AppConstants.Colors.interested.opacity(0.4) : .clear, lineWidth: 1.5)
                    )
                }
                .accessibilityLabel(isInterested ? "Interested" : "Mark as interested")
                .accessibilityAddTraits(isInterested ? .isSelected : [])
            }

            if attendeeCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                    Text("\(attendeeCount) going")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(AppConstants.Colors.textSecondary)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(attendeeCount) people going")
            }
        }
    }
}
