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
                        .foregroundStyle(Color(hex: "9CA3AF"))

                    if let bio = profile.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.body)
                            .foregroundStyle(Color(hex: "9CA3AF"))
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
                            .foregroundStyle(viewModel.isFollowing ? Color(hex: "9CA3AF") : .white)
                            .frame(width: 140)
                            .padding(.vertical, 12)
                            .background(viewModel.isFollowing ? Color(hex: "2A2A2A") : Color(hex: "FF6B35"))
                            .clipShape(Capsule())
                    }

                    // Stats
                    HStack(spacing: 0) {
                        statItem(value: "\(profile.eventsAttended)", label: "Events")
                        Divider().frame(height: 30).background(Color(hex: "2A2A2A"))
                        statItem(value: "\(viewModel.followingCount)", label: "Following")
                        Divider().frame(height: 30).background(Color(hex: "2A2A2A"))
                        statItem(value: "\(viewModel.followerCount)", label: "Followers")
                        Divider().frame(height: 30).background(Color(hex: "2A2A2A"))
                        statItem(value: "\(profile.streakCount)🔥", label: "Streak")
                    }
                    .padding(.vertical, 16)
                    .background(Color(hex: "1A1A1A"))
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
        .background(Color(hex: "0A0A0A"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.loadProfile(userId: userId, currentUserId: authViewModel.currentProfile?.id)
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline).fontWeight(.bold).foregroundStyle(.white)
            Text(label).font(.caption).foregroundStyle(Color(hex: "9CA3AF"))
        }
        .frame(maxWidth: .infinity)
    }
}
