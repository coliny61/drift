import SwiftUI

struct OrganizerDashboardView: View {
    let organizer: Organizer
    @Environment(EventService.self) private var eventService
    @Environment(OrganizerService.self) private var organizerService

    @State private var events: [Event] = []
    @State private var followerCount = 0
    @State private var isLoading = true
    @State private var showEventSubmit = false
    @State private var editingEvent: Event?
    @State private var cancellingEvent: Event?
    @State private var showEditOrganizer = false

    private var totalRSVPs: Int {
        events.reduce(0) { $0 + $1.rsvpCount }
    }

    private var approvedCount: Int {
        events.filter { $0.isApproved }.count
    }

    private var pendingCount: Int {
        events.filter { $0.isPending }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Edit Profile row
                Button {
                    showEditOrganizer = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppConstants.Colors.accent)
                            .frame(width: 34, height: 34)
                            .background(AppConstants.Colors.accent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                        Text("Edit Organization Profile")
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

                // Analytics cards
                analyticsSection

                // Events by status
                eventsSection
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(AppConstants.Colors.background)
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
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
        .sheet(isPresented: $showEventSubmit) {
            EventSubmitView(organizer: organizer)
        }
        .sheet(item: $editingEvent) { event in
            EventSubmitView(organizer: organizer, editingEvent: event)
        }
        .sheet(isPresented: $showEditOrganizer) {
            Task { await loadData() }
        } content: {
            EditOrganizerView(organizer: organizer)
        }
        .onChange(of: showEventSubmit) { _, showing in
            if !showing { Task { await loadData() } }
        }
        .onChange(of: editingEvent) { old, new in
            if old != nil && new == nil { Task { await loadData() } }
        }
        .alert("Cancel Event", isPresented: .init(
            get: { cancellingEvent != nil },
            set: { if !$0 { cancellingEvent = nil } }
        )) {
            Button("Keep Event", role: .cancel) { cancellingEvent = nil }
            Button("Cancel Event", role: .destructive) {
                if let event = cancellingEvent {
                    Task {
                        try? await eventService.cancelEvent(eventId: event.id)
                        await loadData()
                    }
                }
                cancellingEvent = nil
            }
        } message: {
            Text("This will cancel \"\(cancellingEvent?.title ?? "")\" and remove it from the feed. This cannot be undone.")
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Analytics

    private var analyticsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            analyticsCard(value: "\(events.count)", label: "Total Events", icon: "calendar", color: AppConstants.Colors.accent)
            analyticsCard(value: "\(totalRSVPs)", label: "Total RSVPs", icon: "person.2.fill", color: AppConstants.Colors.info)
            analyticsCard(value: "\(followerCount)", label: "Followers", icon: "heart.fill", color: AppConstants.Colors.pink)
            analyticsCard(value: "\(approvedCount)", label: "Live Events", icon: "checkmark.circle.fill", color: AppConstants.Colors.success)
        }
        .padding(.horizontal)
    }

    private func analyticsCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 11))
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(AppConstants.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(AppConstants.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Events

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if pendingCount > 0 {
                sectionLabel("Pending Review (\(pendingCount))")
                ForEach(events.filter { $0.isPending }) { event in
                    eventRow(event)
                }
            }

            sectionLabel("All Events (\(events.count))")

            if events.isEmpty && !isLoading {
                VStack(spacing: 14) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(AppConstants.Colors.textTertiary)
                    Text("No events yet")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppConstants.Colors.textSecondary)
                    Text("Submit your first event to get started")
                        .font(.caption)
                        .foregroundStyle(AppConstants.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 44)
                .background(AppConstants.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(events) { event in
                    eventRow(event)
                }
            }
        }
        .padding(.horizontal)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundStyle(.white)
    }

    private func eventRow(_ event: Event) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .center, spacing: 2) {
                Text(event.startTime.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(0.5)
                    .foregroundStyle(AppConstants.Colors.accent)
                Text(event.startTime.formatted(.dateTime.day()))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 5) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 10) {
                    HStack(spacing: 3) {
                        Image(systemName: "person.2")
                            .font(.caption2)
                        Text("\(event.rsvpCount)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(AppConstants.Colors.textSecondary)

                    approvalBadge(event)
                }
            }

            Spacer()

            if event.isApproved && !event.isCurrentlyFeatured {
                Button {
                    Task {
                        try? await eventService.requestBoost(eventId: event.id)
                        HapticManager.selection()
                    }
                } label: {
                    Image(systemName: "star")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppConstants.Colors.warning)
                        .frame(width: 32, height: 32)
                        .background(AppConstants.Colors.warning.opacity(0.12))
                        .clipShape(Circle())
                }
            } else if event.isCurrentlyFeatured {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppConstants.Colors.warning)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(16)
        .background(AppConstants.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .contextMenu {
            Button {
                editingEvent = event
            } label: {
                Label("Edit Event", systemImage: "pencil")
            }

            if event.status != "cancelled" {
                Button(role: .destructive) {
                    cancellingEvent = event
                } label: {
                    Label("Cancel Event", systemImage: "xmark.circle")
                }
            }
        }
    }

    private func approvalBadge(_ event: Event) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(approvalColor(event))
                .frame(width: 6, height: 6)
            Text(approvalText(event))
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(approvalColor(event))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(approvalColor(event).opacity(0.12))
        .clipShape(Capsule())
    }

    private func approvalText(_ event: Event) -> String {
        if event.isApproved { return "Live" }
        if event.isPending { return "Pending" }
        if event.isRejected { return "Rejected" }
        return "Draft"
    }

    private func approvalColor(_ event: Event) -> Color {
        if event.isApproved { return AppConstants.Colors.success }
        if event.isPending { return AppConstants.Colors.warning }
        if event.isRejected { return AppConstants.Colors.error }
        return AppConstants.Colors.textTertiary
    }

    // MARK: - Data

    private func loadData() async {
        isLoading = true
        async let evts = eventService.fetchOrganizerEvents(organizerId: organizer.id, includeAll: true)
        async let count = organizerService.getFollowerCount(organizerId: organizer.id)
        events = await evts
        followerCount = await count
        isLoading = false
    }
}
