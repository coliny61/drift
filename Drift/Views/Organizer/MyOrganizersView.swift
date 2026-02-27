import SwiftUI

struct MyOrganizersView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(OrganizerService.self) private var organizerService

    @State private var organizers: [Organizer] = []
    @State private var isLoading = true
    @State private var showRegistration = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView()
                        .tint(AppConstants.Colors.accent)
                        .padding(.top, 60)
                } else if organizers.isEmpty {
                    emptyState
                } else {
                    ForEach(organizers) { org in
                        NavigationLink(value: AppDestination.organizer(org.id)) {
                            organizerCard(org)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
        .background(AppConstants.Colors.background)
        .navigationTitle("My Organizations")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showRegistration = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(AppConstants.Colors.accent)
                }
            }
        }
        .navigationDestination(for: AppDestination.self) { destination in
            switch destination {
            case .event(let id): EventDetailView(eventId: id)
            case .organizer(let id): OrganizerDetailView(organizerId: id)
            }
        }
        .sheet(isPresented: $showRegistration) {
            OrganizerRegistrationView()
        }
        .task {
            await loadOrganizers()
        }
        .onChange(of: showRegistration) { _, showing in
            if !showing {
                Task { await loadOrganizers() }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)

            Image(systemName: "building.2")
                .font(.system(size: 48))
                .foregroundStyle(AppConstants.Colors.textTertiary)

            Text("No organizations yet")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Register as an organizer to start hosting wellness events in DFW")
                .font(.subheadline)
                .foregroundStyle(AppConstants.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showRegistration = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Register Organization")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(AppConstants.Colors.accent)
                .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
    }

    private func organizerCard(_ org: Organizer) -> some View {
        HStack(spacing: 14) {
            // Logo placeholder
            Circle()
                .fill(AppConstants.Colors.accent.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(String(org.name.prefix(1)))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppConstants.Colors.accent)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(org.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    if org.isVerifiedOrganizer {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "60A5FA"))
                    }
                }

                statusBadge(org)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppConstants.Colors.textTertiary)
        }
        .padding(16)
        .background(AppConstants.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func statusBadge(_ org: Organizer) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor(org))
                .frame(width: 6, height: 6)
            Text(statusText(org))
                .font(.caption)
                .foregroundStyle(statusColor(org))
        }
    }

    private func statusText(_ org: Organizer) -> String {
        if org.isVerifiedOrganizer { return "Verified" }
        if org.isPendingVerification { return "Under Review" }
        return "Not Verified"
    }

    private func statusColor(_ org: Organizer) -> Color {
        if org.isVerifiedOrganizer { return AppConstants.Colors.success }
        if org.isPendingVerification { return Color(hex: "FBBF24") }
        return AppConstants.Colors.textTertiary
    }

    private func loadOrganizers() async {
        isLoading = true
        let profileId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
        organizers = await organizerService.fetchMyOrganizers(profileId: profileId)
        isLoading = false
    }
}
