import SwiftUI

struct RSVPButtonView: View {
    let isGoing: Bool
    let isInterested: Bool
    let attendeeCount: Int
    let onGoing: () -> Void
    let onInterested: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: onGoing) {
                    HStack(spacing: 6) {
                        Image(systemName: isGoing ? "checkmark.circle.fill" : "hand.raised.fill")
                        Text(isGoing ? "Going!" : "I'm Going")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isGoing ? Color(hex: "34D399") : Color(hex: "FF6B35"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: onInterested) {
                    HStack(spacing: 6) {
                        Image(systemName: isInterested ? "star.fill" : "star")
                        Text("Interested")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isInterested ? Color(hex: "FFD54F") : Color(hex: "9CA3AF"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "2A2A2A"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isInterested ? Color(hex: "FFD54F").opacity(0.5) : .clear, lineWidth: 1)
                    )
                }
            }

            if attendeeCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                    Text("\(attendeeCount) going")
                        .font(.caption)
                }
                .foregroundStyle(Color(hex: "9CA3AF"))
            }
        }
    }
}
