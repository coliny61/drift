import SwiftUI

struct ActivityFeedView: View {
    @Environment(ActivityFeedViewModel.self) private var viewModel
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.feedItems.isEmpty {
                    EmptyStateView(
                        icon: "bell",
                        title: "No Activity Yet",
                        message: "Follow friends and organizers to see their activity here"
                    )
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.feedItems) { item in
                            ActivityItemView(item: item)
                            Divider().background(Color(hex: "2A2A2A"))
                        }
                    }
                }
            }
            .background(Color(hex: "0A0A0A"))
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .refreshable {
                if let userId = authViewModel.currentProfile?.id {
                    await viewModel.loadFeed(userId: userId)
                }
            }
            .task {
                if let userId = authViewModel.currentProfile?.id {
                    await viewModel.loadFeed(userId: userId)
                }
            }
        }
    }
}
