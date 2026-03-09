import SwiftUI

struct OtherProfileView: View {
    let userId: UUID
    @Environment(ProfileViewModel.self) private var viewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(BlockService.self) private var blockService
    @State private var showBlockConfirm = false

    var body: some View {
        ScrollView {
            if let profile = viewModel.profile {
                VStack(spacing: 20) {
                    AvatarView(url: profile.avatarUrl, size: 80, fallbackInitials: String(profile.displayName.prefix(1)))
                        .padding(.top, 20)

                    Text(profile.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("@\(profile.username)")
                        .font(.subheadline)
                        .foregroundStyle(AppConstants.Colors.textSecondary)

                    if let bio = profile.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.body)
                            .foregroundStyle(AppConstants.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    // Follow + Message buttons
                    HStack(spacing: 12) {
                        Button {
                            guard let currentUserId = authViewModel.currentProfile?.id else { return }
                            Task {
                                await viewModel.toggleFollow(currentUserId: currentUserId, targetUserId: userId)
                            }
                        } label: {
                            Text(viewModel.isFollowing ? "Following" : "Follow")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(viewModel.isFollowing ? AppConstants.Colors.textSecondary : .white)
                                .frame(width: 120)
                                .padding(.vertical, 12)
                                .background(viewModel.isFollowing ? AppConstants.Colors.secondaryBackground : AppConstants.Colors.accent)
                                .clipShape(Capsule())
                        }

                        NavigationLink(value: AppDestination.conversation(userId)) {
                            HStack(spacing: 6) {
                                Image(systemName: "bubble.left")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Message")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(width: 120)
                            .padding(.vertical, 12)
                            .background(AppConstants.Colors.secondaryBackground)
                            .clipShape(Capsule())
                        }
                    }

                    // Stats
                    HStack(spacing: 0) {
                        statItem(value: "\(profile.eventsAttended)", label: "Events")
                        Divider().frame(height: 30).background(AppConstants.Colors.secondaryBackground)
                        statItem(value: "\(viewModel.followingCount)", label: "Following")
                        Divider().frame(height: 30).background(AppConstants.Colors.secondaryBackground)
                        statItem(value: "\(viewModel.followerCount)", label: "Followers")
                        Divider().frame(height: 30).background(AppConstants.Colors.secondaryBackground)
                        statItem(value: "\(profile.streakCount)🔥", label: "Streak")
                    }
                    .padding(.vertical, 16)
                    .background(AppConstants.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Interests
                    if !profile.interests.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(profile.interests, id: \.self) { interest in
                                    if let category = Category.allCases.first(where: { $0.slug == interest }) {
                                        TagView(text: category.displayName, color: Color(hex: category.color), style: .subtle)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            } else if viewModel.isLoading {
                LoadingView()
            }
        }
        .background(AppConstants.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if blockService.isBlocked(userId) {
                        Button {
                            let currentUserId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
                            Task { await blockService.unblockUser(blockerId: currentUserId, blockedId: userId) }
                        } label: {
                            Label("Unblock User", systemImage: "hand.raised.slash")
                        }
                    } else {
                        Button(role: .destructive) {
                            showBlockConfirm = true
                        } label: {
                            Label("Block User", systemImage: "hand.raised")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(AppConstants.Colors.textSecondary)
                }
            }
        }
        .alert("Block User", isPresented: $showBlockConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Block", role: .destructive) {
                let currentUserId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
                Task {
                    await blockService.blockUser(blockerId: currentUserId, blockedId: userId)
                    if viewModel.isFollowing {
                        await viewModel.toggleFollow(currentUserId: currentUserId, targetUserId: userId)
                    }
                }
            }
        } message: {
            Text("They won't be able to message you, and their activity will be hidden from your feed.")
        }
        .task {
            await viewModel.loadProfile(userId: userId, currentUserId: authViewModel.currentProfile?.id)
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline).fontWeight(.bold).foregroundStyle(.white)
            Text(label).font(.caption).foregroundStyle(AppConstants.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
