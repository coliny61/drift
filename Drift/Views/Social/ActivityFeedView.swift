import SwiftUI

struct ActivityFeedView: View {
    @Environment(ActivityFeedViewModel.self) private var viewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(BlockService.self) private var blockService

    private var visibleItems: [ActivityFeedItem] {
        viewModel.feedItems.filter { !blockService.isBlocked($0.actorId) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if visibleItems.isEmpty {
                    ContentUnavailableView(
                        "No Activity Yet",
                        systemImage: "bell",
                        description: Text("Follow friends and organizers to see their activity here")
                    )
                } else {
                    List {
                        ForEach(visibleItems) { item in
                            if let eventId = item.targetEventId {
                                NavigationLink(value: AppDestination.event(eventId)) {
                                    ActivityItemView(item: item)
                                }
                            } else {
                                ActivityItemView(item: item)
                            }
                        }
                        .listRowBackground(AppConstants.Colors.background)
                        .listRowSeparatorTint(AppConstants.Colors.divider)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
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
                case .conversation(let id): DMThreadView(otherUserId: id)
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
                viewModel.markAsRead()
            }
            .onDisappear {
                viewModel.stopPolling()
            }
        }
    }
}
