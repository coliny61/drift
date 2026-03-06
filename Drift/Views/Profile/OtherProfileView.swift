import SwiftUI

struct OtherProfileView: View {
    let userId: UUID
    @Environment(ProfileViewModel.self) private var viewModel
    @Environment(AuthViewModel.self) private var authViewModel

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

                    // Follow button
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
                            .frame(width: 140)
                            .padding(.vertical, 12)
                            .background(viewModel.isFollowing ? AppConstants.Colors.secondaryBackground : AppConstants.Colors.accent)
                            .clipShape(Capsule())
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
