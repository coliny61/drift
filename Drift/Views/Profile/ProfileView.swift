import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel
    @State private var showSettings = false
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar and info
                    VStack(spacing: 14) {
                        AvatarView(
                            url: authViewModel.currentProfile?.avatarUrl,
                            size: 88,
                            fallbackInitials: String(authViewModel.currentProfile?.displayName.prefix(1) ?? "?")
                        )
                        .shadow(color: AppConstants.Colors.accent.opacity(0.2), radius: 12, x: 0, y: 4)

                        Text(authViewModel.currentProfile?.displayName ?? "Drifter")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        if let username = authViewModel.currentProfile?.username {
                            Text("@\(username)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(AppConstants.Colors.textTertiary)
                        }

                        if let bio = authViewModel.currentProfile?.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.body)
                                .foregroundStyle(AppConstants.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                                .padding(.horizontal, 40)
                        }
                    }
                    .padding(.top, 20)

                    // Stats row
                    HStack(spacing: 0) {
                        statItem(value: "\(authViewModel.currentProfile?.eventsAttended ?? 0)", label: "Events")
                        statDivider
                        statItem(value: "\(profileViewModel.followingCount)", label: "Following")
                        statDivider
                        statItem(value: "\(profileViewModel.followerCount)", label: "Followers")
                        statDivider
                        statItem(value: "\(authViewModel.currentProfile?.streakCount ?? 0)", label: "Streak", accent: true)
                    }
                    .padding(.vertical, 18)
                    .background(AppConstants.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Edit Profile button
                    Button {
                        showEditProfile = true
                    } label: {
                        Text("Edit Profile")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(AppConstants.Colors.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    // My Organizations
                    NavigationLink {
                        MyOrganizersView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "building.2")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppConstants.Colors.accent)
                                .frame(width: 34, height: 34)
                                .background(AppConstants.Colors.accent.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 9))
                            Text("My Organizations")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AppConstants.Colors.textTertiary)
                        }
                        .padding(14)
                        .background(AppConstants.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)

                    // Interests
                    if let interests = authViewModel.currentProfile?.interests, !interests.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("INTERESTS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(1)
                                .foregroundStyle(AppConstants.Colors.textTertiary)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(interests, id: \.self) { interest in
                                        if let category = Category.allCases.first(where: { $0.slug == interest }) {
                                            HStack(spacing: 5) {
                                                Image(systemName: category.icon)
                                                    .font(.system(size: 11, weight: .semibold))
                                                Text(category.displayName)
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                            }
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(Color(hex: category.color).opacity(0.12))
                                            .foregroundStyle(Color(hex: category.color))
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Upcoming Events
                    VStack(alignment: .leading, spacing: 14) {
                        Text("UPCOMING EVENTS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .tracking(1)
                            .foregroundStyle(AppConstants.Colors.textTertiary)
                            .padding(.horizontal)

                        if profileViewModel.upcomingEvents.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 28, weight: .light))
                                    .foregroundStyle(AppConstants.Colors.textTertiary)
                                Text("No upcoming events")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppConstants.Colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 36)
                            .background(AppConstants.Colors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        } else {
                            ForEach(profileViewModel.upcomingEvents) { event in
                                NavigationLink(value: AppDestination.event(event.id)) {
                                    HStack(spacing: 14) {
                                        VStack(alignment: .center, spacing: 2) {
                                            Text(event.startTime.formatted(.dateTime.month(.abbreviated)).uppercased())
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .tracking(0.5)
                                                .foregroundStyle(AppConstants.Colors.accent)
                                            Text(event.startTime.formatted(.dateTime.day()))
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                        }
                                        .frame(width: 48)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(event.title)
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                                .lineLimit(1)
                                            HStack(spacing: 4) {
                                                Image(systemName: "mappin")
                                                    .font(.system(size: 9))
                                                Text(event.locationName)
                                                    .font(.caption)
                                            }
                                            .foregroundStyle(AppConstants.Colors.textSecondary)
                                            .lineLimit(1)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(AppConstants.Colors.textTertiary)
                                    }
                                    .padding(14)
                                    .background(AppConstants.Colors.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .background(AppConstants.Colors.background)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(AppConstants.Colors.textSecondary)
                    }
                }
            }
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .event(let id): EventDetailView(eventId: id)
                case .organizer(let id): OrganizerDetailView(organizerId: id)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .refreshable {
                let userId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
                await profileViewModel.loadProfile(userId: userId, currentUserId: userId)
            }
            .task {
                let userId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
                await profileViewModel.loadProfile(userId: userId, currentUserId: userId)
            }
        }
    }

    // MARK: - Helpers

    private var statDivider: some View {
        Rectangle()
            .fill(AppConstants.Colors.secondaryBackground)
            .frame(width: 1, height: 28)
    }

    private func statItem(value: String, label: String, accent: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(accent ? AppConstants.Colors.accent : .white)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(AppConstants.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
