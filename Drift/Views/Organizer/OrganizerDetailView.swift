import SwiftUI

struct OrganizerDetailView: View {
    let organizerId: UUID
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(OrganizerService.self) private var organizerService

    @State private var organizer: Organizer?
    @State private var events: [Event] = []
    @State private var followerCount = 0
    @State private var isFollowing = false
    @State private var isLoading = true
    @State private var isFollowLoading = false
    @State private var showEventSubmit = false

    private var isOwnOrganizer: Bool {
        guard let organizer else { return false }
        let userId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
        return organizer.profileId == userId
    }

    var body: some View {
        ScrollView {
            if let organizer {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    headerSection(organizer)

                    // Stats bar
                    statsBar(organizer)

                    // About
                    if !organizer.description.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ABOUT")
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(1)
                                .foregroundStyle(AppConstants.Colors.textTertiary)
                            Text(organizer.description)
                                .font(.subheadline)
                                .foregroundStyle(AppConstants.Colors.textSecondary)
                                .lineSpacing(5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    }

                    // Links
                    if organizer.instagramHandle != nil || organizer.website != nil {
                        linksSection(organizer)
                    }

                    // Upcoming events
                    if !events.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("UPCOMING EVENTS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(1)
                                .foregroundStyle(AppConstants.Colors.textTertiary)
                                .padding(.horizontal, 20)

                            LazyVStack(spacing: 18) {
                                ForEach(events) { event in
                                    NavigationLink(value: AppDestination.event(event.id)) {
                                        EventCardView(event: event)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 28)
                    }
                }
                .padding(.bottom, 40)
            } else if isLoading {
                ProgressView()
                    .tint(AppConstants.Colors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 200)
            }
        }
        .background(AppConstants.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(for: AppDestination.self) { destination in
            switch destination {
            case .event(let id): EventDetailView(eventId: id)
            case .organizer(let id): OrganizerDetailView(organizerId: id)
            }
        }
        .toolbar {
            if isOwnOrganizer {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEventSubmit = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Event")
                        }
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(AppConstants.Colors.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showEventSubmit) {
            if let organizer {
                EventSubmitView(organizer: organizer)
            }
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Header

    private func headerSection(_ organizer: Organizer) -> some View {
        VStack(spacing: 16) {
            // Logo
            OrganizerLogoView(organizer: organizer, size: 88)
                .shadow(color: AppConstants.Colors.accent.opacity(0.2), radius: 12, x: 0, y: 4)

            // Name + verification
            HStack(spacing: 6) {
                Text(organizer.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                if organizer.isVerifiedOrganizer {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(AppConstants.Colors.info)
                        .font(.body)
                }
            }

            if let city = organizer.city {
                HStack(spacing: 5) {
                    Image(systemName: "mappin")
                        .font(.system(size: 11))
                    Text(city)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(AppConstants.Colors.textSecondary)
            }

            // Dashboard / Follow buttons
            HStack(spacing: 12) {
                if isOwnOrganizer {
                    NavigationLink {
                        OrganizerDashboardView(organizer: organizer)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chart.bar.fill")
                                .font(.caption)
                            Text("Dashboard")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 11)
                        .background(AppConstants.Colors.accent)
                        .clipShape(Capsule())
                        .shadow(color: AppConstants.Colors.accent.opacity(0.25), radius: 8, x: 0, y: 4)
                    }
                }

                Button {
                    Task { await toggleFollow() }
                } label: {
                    HStack(spacing: 6) {
                        if isFollowLoading {
                            ProgressView()
                                .tint(isFollowing ? AppConstants.Colors.textSecondary : .white)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: isFollowing ? "checkmark" : "plus")
                                .font(.caption)
                        }
                        Text(isFollowing ? "Following" : "Follow")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(isFollowing ? AppConstants.Colors.textSecondary : .white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 11)
                    .background(isFollowing ? AppConstants.Colors.cardBackground : AppConstants.Colors.accent)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(isFollowing ? AppConstants.Colors.secondaryBackground : .clear, lineWidth: 1.5)
                    )
                }
                .disabled(isFollowLoading)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Stats

    private func statsBar(_ organizer: Organizer) -> some View {
        HStack(spacing: 0) {
            statItem(value: "\(followerCount)", label: "Followers")
            Rectangle()
                .fill(AppConstants.Colors.secondaryBackground)
                .frame(width: 1, height: 28)
            statItem(value: "\(events.count)", label: "Events")
            if organizer.isVerifiedOrganizer {
                Rectangle()
                    .fill(AppConstants.Colors.secondaryBackground)
                    .frame(width: 1, height: 28)
                statItem(value: "Verified", label: "Status", color: AppConstants.Colors.info)
            }
        }
        .padding(.vertical, 18)
        .background(AppConstants.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }

    private func statItem(value: String, label: String, color: Color = .white) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(AppConstants.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Links

    private func linksSection(_ organizer: Organizer) -> some View {
        VStack(spacing: 10) {
            if let handle = organizer.instagramHandle, !handle.isEmpty,
               let url = URL(string: "https://instagram.com/\(handle)") {
                Link(destination: url) {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppConstants.Colors.instagram)
                            .frame(width: 34, height: 34)
                            .background(AppConstants.Colors.instagram.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                        Text("@\(handle)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(AppConstants.Colors.textTertiary)
                    }
                    .padding(14)
                    .background(AppConstants.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            if let website = organizer.website, !website.isEmpty,
               let url = URL(string: website) {
                Link(destination: url) {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppConstants.Colors.info)
                            .frame(width: 34, height: 34)
                            .background(AppConstants.Colors.info.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                        Text(website.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: ""))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(AppConstants.Colors.textTertiary)
                    }
                    .padding(14)
                    .background(AppConstants.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    // MARK: - Data

    private func loadData() async {
        isLoading = true
        async let org = organizerService.fetchOrganizer(id: organizerId)
        async let evts = organizerService.fetchOrganizerEvents(organizerId: organizerId)
        async let count = organizerService.getFollowerCount(organizerId: organizerId)

        organizer = await org
        events = await evts
        followerCount = await count

        let userId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
        isFollowing = await organizerService.isFollowing(userId: userId, organizerId: organizerId)
        isLoading = false
    }

    private func toggleFollow() async {
        isFollowLoading = true
        let userId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
        do {
            if isFollowing {
                try await organizerService.unfollowOrganizer(userId: userId, organizerId: organizerId)
                isFollowing = false
                followerCount = max(0, followerCount - 1)
            } else {
                try await organizerService.followOrganizer(userId: userId, organizerId: organizerId)
                isFollowing = true
                followerCount += 1
            }
            HapticManager.selection()
        } catch {
            print("Error toggling follow: \(error)")
        }
        isFollowLoading = false
    }
}
