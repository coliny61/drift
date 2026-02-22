import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel
    @State private var showSettings = false
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Avatar and stats
                    VStack(spacing: 16) {
                        AvatarView(
                            url: authViewModel.currentProfile?.avatarUrl,
                            size: 80,
                            fallbackInitials: String(authViewModel.currentProfile?.displayName.prefix(1) ?? "?")
                        )

                        Text(authViewModel.currentProfile?.displayName ?? "Drifter")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        if let username = authViewModel.currentProfile?.username {
                            Text("@\(username)")
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: "9CA3AF"))
                        }

                        if let bio = authViewModel.currentProfile?.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.body)
                                .foregroundStyle(Color(hex: "9CA3AF"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                    .padding(.top, 20)

                    // Stats row
                    HStack(spacing: 0) {
                        statItem(value: "\(authViewModel.currentProfile?.eventsAttended ?? 0)", label: "Events")
                        Divider().frame(height: 30).background(Color(hex: "2A2A2A"))
                        statItem(value: "\(profileViewModel.followingCount)", label: "Following")
                        Divider().frame(height: 30).background(Color(hex: "2A2A2A"))
                        statItem(value: "\(profileViewModel.followerCount)", label: "Followers")
                        Divider().frame(height: 30).background(Color(hex: "2A2A2A"))
                        statItem(value: "\(authViewModel.currentProfile?.streakCount ?? 0)🔥", label: "Streak")
                    }
                    .padding(.vertical, 16)
                    .background(Color(hex: "1A1A1A"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Edit Profile button
                    Button {
                        showEditProfile = true
                    } label: {
                        Text("Edit Profile")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: "2A2A2A"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    // Interests
                    if let interests = authViewModel.currentProfile?.interests, !interests.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Interests")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(interests, id: \.self) { interest in
                                        if let category = Category.allCases.first(where: { $0.slug == interest }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: category.icon)
                                                    .font(.caption)
                                                Text(category.displayName)
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color(hex: category.color).opacity(0.15))
                                            .foregroundStyle(Color(hex: category.color))
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Upcoming RSVPs placeholder
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming Events")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal)

                        if profileViewModel.upcomingRSVPs.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: "9CA3AF"))
                                Text("No upcoming events")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(hex: "9CA3AF"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                            .background(Color(hex: "1A1A1A"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .background(Color(hex: "0A0A0A"))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color(hex: "9CA3AF"))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .task {
                if let userId = authViewModel.currentProfile?.id {
                    await profileViewModel.loadProfile(userId: userId, currentUserId: userId)
                }
            }
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color(hex: "9CA3AF"))
        }
        .frame(maxWidth: .infinity)
    }
}
