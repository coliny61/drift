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
                            if let eventId = item.targetEventId {
                                NavigationLink(value: AppDestination.event(eventId)) {
                                    ActivityItemView(item: item)
                                }
                                .buttonStyle(.plain)
                            } else {
                                ActivityItemView(item: item)
                            }
                            Rectangle()
                                .fill(AppConstants.Colors.divider)
                                .frame(height: 0.5)
                                .padding(.leading, 72)
                        }
                    }
                }
            }
            .background(AppConstants.Colors.background)
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .event(let id): EventDetailView(eventId: id)
                case .organizer(let id): OrganizerDetailView(organizerId: id)
                }
            }
            .refreshable {
                let userId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
                await viewModel.refresh(userId: userId)
            }
            .task {
                let userId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
                await viewModel.loadFeed(userId: userId)
                viewModel.startPolling(userId: userId)
            }
            .onDisappear {
                viewModel.stopPolling()
            }
        }
    }
}
