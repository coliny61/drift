import SwiftUI

struct AttendanceHistoryView: View {
    var body: some View {
        ContentUnavailableView(
            "No Past Events",
            systemImage: "calendar.badge.clock",
            description: Text("Events you attend will appear here")
        )
        .background(AppConstants.Colors.background)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
