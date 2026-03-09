import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel
    @Environment(BookmarkViewModel.self) private var bookmarkViewModel
    @Environment(EventService.self) private var eventService
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var eventTab: ProfileEventTab = .upcoming
    @State private var bookmarkedEvents: [Event] = []

    enum ProfileEventTab: String, CaseIterable {
        case upcoming = "Upcoming"
        case saved = "Saved"
    }

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

                    // Events tabs
                    VStack(alignment: .leading, spacing: 14) {
                        // Tab picker
                        HStack(spacing: 0) {
                            ForEach(ProfileEventTab.allCases, id: \.self) { tab in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) { eventTab = tab }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(tab.rawValue)
                                            .font(.caption)
                                            .fontWeight(eventTab == tab ? .bold : .medium)
                                        if tab == .saved && !bookmarkViewModel.bookmarkedIds.isEmpty {
                                            Text("\(bookmarkViewModel.bookmarkedIds.count)")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(eventTab == tab ? AppConstants.Colors.cardBackground : AppConstants.Colors.textTertiary)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(eventTab == tab ? AppConstants.Colors.accent : AppConstants.Colors.secondaryBackground)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    .foregroundStyle(eventTab == tab ? .white : AppConstants.Colors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(eventTab == tab ? AppConstants.Colors.secondaryBackground : .clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(3)
                        .background(AppConstants.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)

                        if eventTab == .upcoming {
                            if profileViewModel.upcomingEvents.isEmpty {
                                profileEventEmpty(icon: "calendar", text: "No upcoming events")
                            } else {
                                ForEach(profileViewModel.upcomingEvents) { event in
                                    profileEventRow(event)
                                }
                            }
                        } else {
                            if bookmarkedEvents.isEmpty {
                                profileEventEmpty(icon: "bookmark", text: "No saved events")
                            } else {
                                ForEach(bookmarkedEvents) { event in
                                    profileEventRow(event)
                                }
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
                let ids = Array(bookmarkViewModel.bookmarkedIds)
                bookmarkedEvents = await eventService.fetchEventsByIds(ids)
            }
        }
    }

    // MARK: - Helpers

    private var statDivider: some View {
        Rectangle()
            .fill(AppConstants.Colors.secondaryBackground)
            .frame(width: 1, height: 28)
    }

    private func profileEventRow(_ event: Event) -> some View {
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

    private func profileEventEmpty(icon: String, text: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(AppConstants.Colors.textTertiary)
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(AppConstants.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(AppConstants.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
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
