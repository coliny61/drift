import SwiftUI

struct AttendanceHistoryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                EmptyStateView(
                    icon: "calendar.badge.clock",
                    title: "No Past Events",
                    message: "Events you attend will appear here"
                )
            }
        }
        .background(AppConstants.Colors.background)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
