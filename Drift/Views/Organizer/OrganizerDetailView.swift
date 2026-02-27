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
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(organizer.description)
                                .font(.subheadline)
                                .foregroundStyle(AppConstants.Colors.textSecondary)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }

                    // Links
                    if organizer.instagramHandle != nil || organizer.website != nil {
                        linksSection(organizer)
                    }

                    // Upcoming events
                    if !events.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Upcoming Events")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)

                            LazyVStack(spacing: 16) {
                                ForEach(events) { event in
                                    NavigationLink(value: event.id) {
                                        EventCardView(event: event)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 24)
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
        .navigationDestination(for: UUID.self) { eventId in
            EventDetailView(eventId: eventId)
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
                        .fontWeight(.semibold)
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
            if let logoUrl = organizer.logoUrl, let url = URL(string: logoUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    default:
                        logoPlaceholder(organizer)
                    }
                }
            } else {
                logoPlaceholder(organizer)
            }

            // Name + verification
            HStack(spacing: 6) {
                Text(organizer.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                if organizer.isVerifiedOrganizer {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color(hex: "60A5FA"))
                        .font(.body)
                }
            }

            if let city = organizer.city {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption)
                    Text(city)
                        .font(.subheadline)
                }
                .foregroundStyle(AppConstants.Colors.textSecondary)
            }

            // Dashboard / Follow buttons
            if isOwnOrganizer {
                NavigationLink {
                    OrganizerDashboardView(organizer: organizer)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption)
                        Text("Dashboard")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(AppConstants.Colors.accent)
                    .clipShape(Capsule())
                }
            }

            Button {
                Task { await toggleFollow() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isFollowing ? "checkmark" : "plus")
                        .font(.caption)
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(isFollowing ? AppConstants.Colors.textSecondary : .white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(isFollowing ? AppConstants.Colors.cardBackground : AppConstants.Colors.accent)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isFollowing ? AppConstants.Colors.secondaryBackground : .clear, lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    private func logoPlaceholder(_ organizer: Organizer) -> some View {
        Circle()
            .fill(AppConstants.Colors.accent.opacity(0.2))
            .frame(width: 80, height: 80)
            .overlay {
                Text(String(organizer.name.prefix(1)))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(AppConstants.Colors.accent)
            }
    }

    // MARK: - Stats

    private func statsBar(_ organizer: Organizer) -> some View {
        HStack(spacing: 0) {
            statItem(value: "\(followerCount)", label: "Followers")
            Divider()
                .frame(height: 30)
                .background(AppConstants.Colors.secondaryBackground)
            statItem(value: "\(events.count)", label: "Events")
            if organizer.isVerifiedOrganizer {
                Divider()
                    .frame(height: 30)
                    .background(AppConstants.Colors.secondaryBackground)
                statItem(value: "Verified", label: "Status", color: Color(hex: "60A5FA"))
            }
        }
        .padding(.vertical, 16)
        .background(AppConstants.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                .foregroundStyle(AppConstants.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Links

    private func linksSection(_ organizer: Organizer) -> some View {
        VStack(spacing: 10) {
            if let handle = organizer.instagramHandle, !handle.isEmpty,
               let url = URL(string: "https://instagram.com/\(handle)") {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("@\(handle)")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "E1306C"))
                    .padding()
                    .background(AppConstants.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            if let website = organizer.website, !website.isEmpty,
               let url = URL(string: website) {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "globe")
                        Text(website.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: ""))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "60A5FA"))
                    .padding()
                    .background(AppConstants.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
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
    }
}
