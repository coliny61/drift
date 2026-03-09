import SwiftUI

struct MyOrganizersView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(OrganizerService.self) private var organizerService

    @State private var organizers: [Organizer] = []
    @State private var isLoading = true
    @State private var showRegistration = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
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
            .padding(.bottom, 32)
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
            case .conversation(let id): DMThreadView(otherUserId: id)
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
        VStack(spacing: 18) {
            Spacer().frame(height: 40)

            ZStack {
                Circle()
                    .fill(AppConstants.Colors.accent.opacity(0.06))
                    .frame(width: 100, height: 100)
                Image(systemName: "building.2")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(AppConstants.Colors.textTertiary)
            }

            Text("No organizations yet")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Register as an organizer to start hosting wellness events in DFW")
                .font(.subheadline)
                .foregroundStyle(AppConstants.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 32)

            Button {
                showRegistration = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Register Organization")
                }
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 13)
                .background(AppConstants.Colors.accent)
                .clipShape(Capsule())
                .shadow(color: AppConstants.Colors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 4)
        }
    }

    private func organizerCard(_ org: Organizer) -> some View {
        HStack(spacing: 14) {
            // Logo placeholder
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppConstants.Colors.accent.opacity(0.25), AppConstants.Colors.accent.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)
                .overlay {
                    Text(String(org.name.prefix(1)))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppConstants.Colors.accent)
                }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(org.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    if org.isVerifiedOrganizer {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(AppConstants.Colors.info)
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statusBadge(_ org: Organizer) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(statusColor(org))
                .frame(width: 6, height: 6)
            Text(statusText(org))
                .font(.caption)
                .fontWeight(.semibold)
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
        if org.isPendingVerification { return AppConstants.Colors.warning }
        return AppConstants.Colors.textTertiary
    }

    private func loadOrganizers() async {
        isLoading = true
        let profileId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
        organizers = await organizerService.fetchMyOrganizers(profileId: profileId)
        isLoading = false
    }
}
