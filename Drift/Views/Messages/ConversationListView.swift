import SwiftUI

struct ConversationListView: View {
    @Environment(DirectMessageService.self) private var dmService
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(BlockService.self) private var blockService

    var body: some View {
        ScrollView {
            if dmService.isLoading && dmService.conversations.isEmpty {
                ProgressView()
                    .tint(AppConstants.Colors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
            } else if visibleConversations.isEmpty {
                EmptyStateView(
                    icon: "bubble.left.and.bubble.right",
                    title: "No Messages Yet",
                    message: "Visit someone's profile to start a conversation"
                )
                .padding(.top, 60)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(visibleConversations) { conversation in
                        NavigationLink(value: AppDestination.conversation(conversation.id)) {
                            conversationRow(conversation)
                        }
                        .buttonStyle(.plain)

                        Rectangle()
                            .fill(AppConstants.Colors.divider)
                            .frame(height: 0.5)
                            .padding(.leading, 72)
                    }
                }
            }
        }
        .background(AppConstants.Colors.background)
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(for: AppDestination.self) { destination in
            switch destination {
            case .event(let id): EventDetailView(eventId: id)
            case .organizer(let id): OrganizerDetailView(organizerId: id)
            case .conversation(let userId): DMThreadView(otherUserId: userId)
            }
        }
        .refreshable {
            let userId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
            await dmService.fetchConversations(userId: userId)
        }
        .task {
            let userId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
            await dmService.fetchConversations(userId: userId)
        }
    }

    private var visibleConversations: [DMConversation] {
        dmService.conversations.filter { !blockService.isBlocked($0.id) }
    }

    private func conversationRow(_ conversation: DMConversation) -> some View {
        HStack(spacing: 14) {
            AvatarView(
                url: conversation.otherUser?.avatarUrl,
                size: 48,
                fallbackInitials: String(conversation.otherUser?.displayName.prefix(1) ?? "?")
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUser?.displayName ?? "User")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Spacer()

                    Text(conversation.lastMessage.createdAt.relativeDescription)
                        .font(.caption2)
                        .foregroundStyle(AppConstants.Colors.textTertiary)
                }

                HStack {
                    Text(conversation.lastMessage.content)
                        .font(.caption)
                        .foregroundStyle(AppConstants.Colors.textSecondary)
                        .lineLimit(1)

                    Spacer()

                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppConstants.Colors.accent)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}
