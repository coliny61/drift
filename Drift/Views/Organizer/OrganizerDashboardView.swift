import SwiftUI

struct OrganizerDashboardView: View {
    let organizer: Organizer
    @Environment(EventService.self) private var eventService
    @Environment(OrganizerService.self) private var organizerService

    @State private var events: [Event] = []
    @State private var followerCount = 0
    @State private var isLoading = true
    @State private var showEventSubmit = false

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
            VStack(spacing: 20) {
                // Analytics cards
                analyticsSection

                // Events by status
                eventsSection
            }
            .padding(.top, 16)
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
                    .fontWeight(.semibold)
                    .foregroundStyle(AppConstants.Colors.accent)
                }
            }
        }
        .sheet(isPresented: $showEventSubmit) {
            EventSubmitView(organizer: organizer)
        }
        .onChange(of: showEventSubmit) { _, showing in
            if !showing { Task { await loadData() } }
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Analytics

    private var analyticsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            analyticsCard(value: "\(events.count)", label: "Total Events", icon: "calendar", color: AppConstants.Colors.accent)
            analyticsCard(value: "\(totalRSVPs)", label: "Total RSVPs", icon: "person.2.fill", color: Color(hex: "60A5FA"))
            analyticsCard(value: "\(followerCount)", label: "Followers", icon: "heart.fill", color: Color(hex: "EC407A"))
            analyticsCard(value: "\(approvedCount)", label: "Live Events", icon: "checkmark.circle.fill", color: AppConstants.Colors.success)
        }
        .padding(.horizontal)
    }

    private func analyticsCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppConstants.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(AppConstants.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Events

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if pendingCount > 0 {
                sectionLabel("Pending Review (\(pendingCount))")
                ForEach(events.filter { $0.isPending }) { event in
                    eventRow(event)
                }
            }

            sectionLabel("All Events (\(events.count))")

            if events.isEmpty && !isLoading {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(AppConstants.Colors.textTertiary)
                    Text("No events yet")
                        .font(.subheadline)
                        .foregroundStyle(AppConstants.Colors.textSecondary)
                    Text("Submit your first event to get started")
                        .font(.caption)
                        .foregroundStyle(AppConstants.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
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
            .foregroundStyle(.white)
    }

    private func eventRow(_ event: Event) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .center, spacing: 2) {
                Text(event.startTime.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppConstants.Colors.accent)
                Text(event.startTime.formatted(.dateTime.day()))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "person.2")
                            .font(.caption2)
                        Text("\(event.rsvpCount)")
                            .font(.caption)
                    }
                    .foregroundStyle(AppConstants.Colors.textSecondary)

                    approvalBadge(event)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(AppConstants.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func approvalBadge(_ event: Event) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(approvalColor(event))
                .frame(width: 6, height: 6)
            Text(approvalText(event))
                .font(.caption2)
                .fontWeight(.medium)
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
        if event.isPending { return Color(hex: "FBBF24") }
        if event.isRejected { return Color(hex: "EF5350") }
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
