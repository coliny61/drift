import SwiftUI

struct AttendeeListView: View {
    let attendees: [Profile]

    var body: some View {
        List {
            ForEach(attendees) { attendee in
                HStack(spacing: 12) {
                    AvatarView(url: attendee.avatarUrl, size: 40, fallbackInitials: String(attendee.displayName.prefix(1)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(attendee.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                        Text("@\(attendee.username)")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "9CA3AF"))
                    }

                    Spacer()
                }
                .listRowBackground(Color(hex: "1A1A1A"))
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(hex: "0A0A0A"))
        .navigationTitle("Attendees")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
