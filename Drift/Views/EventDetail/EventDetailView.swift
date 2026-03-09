import SwiftUI
import MapKit
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct EventDetailView: View {
    let eventId: UUID
    @Environment(EventDetailViewModel.self) private var viewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(OrganizerService.self) private var organizerService
    @Environment(LocationManager.self) private var locationManager
    @Environment(BookmarkViewModel.self) private var bookmarkViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var organizer: Organizer?
    @State private var showTicketSafari = false

    var body: some View {
        ScrollView {
            if viewModel.isLoading && viewModel.event == nil {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(AppConstants.Colors.accent)
                    Text("Loading event...")
                        .font(.subheadline)
                        .foregroundStyle(AppConstants.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 120)
            } else if viewModel.loadError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(AppConstants.Colors.textTertiary)
                    Text("Event not found")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("This event may have been removed or is no longer available.")
                        .font(.subheadline)
                        .foregroundStyle(AppConstants.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                    Button("Go Back") { dismiss() }
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(AppConstants.Colors.accent)
                }
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity)
                .padding(.top, 120)
            } else if let event = viewModel.event {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero image
                    ZStack(alignment: .topLeading) {
                        if let urlString = event.coverImageUrl, let url = URL(string: urlString) {
                            CachedAsyncImage(url: url) {
                                heroGradientPlaceholder(event: event)
                            }
                            .frame(height: 300)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [.black.opacity(0.3), .clear, .black.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        } else {
                            heroGradientPlaceholder(event: event)
                        }

                        // Tags overlay
                        VStack {
                            HStack(spacing: 6) {
                                // Category pill
                                HStack(spacing: 4) {
                                    Image(systemName: event.categoryEnum?.icon ?? "star")
                                        .font(.system(size: 10, weight: .bold))
                                    Text(event.categoryEnum?.displayName ?? event.category)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .textCase(.uppercase)
                                        .tracking(0.3)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .background(categoryColor.opacity(0.4))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())

                                if event.isAlcoholFree {
                                    Text("AF")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.ultraThinMaterial)
                                        .background(AppConstants.Colors.alcoholFreeBadge.opacity(0.4))
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                }

                                ForEach(event.tags.filter { $0 != "alcohol-free" }.prefix(2), id: \.self) { tag in
                                    Text(tag.replacingOccurrences(of: "-", with: " ").capitalized)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.ultraThinMaterial)
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding()
                            .padding(.top, 44)

                            Spacer()

                            // Bottom overlay — price badge
                            HStack {
                                Spacer()
                                Text(event.isFree ? "FREE" : event.priceFormatted)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .tracking(0.5)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(.ultraThinMaterial)
                                    .background(event.isFree ? AppConstants.Colors.freeBadge.opacity(0.4) : Color.black.opacity(0.3))
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                            .padding(16)
                        }
                    }
                    .frame(height: 300)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(event.title), \(event.categoryEnum?.displayName ?? event.category), \(event.isFree ? "Free" : event.priceFormatted)")

                    // Content
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text(event.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.top, 4)

                        // Date & Time + Add to Calendar
                        HStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "calendar")
                                    .font(.body)
                                    .foregroundStyle(AppConstants.Colors.accent)
                                    .frame(width: 22)
                                Text(event.startTime.relativeDescription)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                            Button {
                                Task { await viewModel.addToCalendar() }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: viewModel.calendarAdded ? "checkmark.circle.fill" : "plus.circle")
                                    Text(viewModel.calendarAdded ? "Added" : "Add to Cal")
                                }
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(viewModel.calendarAdded ? AppConstants.Colors.success : AppConstants.Colors.accent)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    (viewModel.calendarAdded ? AppConstants.Colors.success : AppConstants.Colors.accent).opacity(0.12)
                                )
                                .clipShape(Capsule())
                            }
                        }

                        // Location
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                Image(systemName: "mappin")
                                    .font(.body)
                                    .foregroundStyle(AppConstants.Colors.accent)
                                    .frame(width: 22)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.locationName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                    Text(event.locationAddress)
                                        .font(.caption)
                                        .foregroundStyle(AppConstants.Colors.textSecondary)
                                }
                            }

                            Button {
                                openMaps(event: event)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.turn.up.right.diamond")
                                    Text("Get Directions")
                                }
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppConstants.Colors.accent)
                                .padding(.leading, 32)
                            }
                        }

                        // Map snippet
                        Map {
                            Marker(event.locationName, coordinate: CLLocationCoordinate2D(
                                latitude: event.locationLat,
                                longitude: event.locationLng
                            ))
                            .tint(categoryColor)
                        }
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .allowsHitTesting(false)
                        .accessibilityLabel("Map showing \(event.locationName)")

                        // Price & Attendees row
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PRICE")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .tracking(0.8)
                                    .foregroundStyle(AppConstants.Colors.textTertiary)
                                Text(event.isFree ? "Free" : event.priceFormatted)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(event.isFree ? AppConstants.Colors.freeBadge : .white)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("ATTENDING")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .tracking(0.8)
                                    .foregroundStyle(AppConstants.Colors.textTertiary)
                                HStack(spacing: 6) {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 14))
                                    Text("\(viewModel.attendeeCount)")
                                }
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(categoryColor)
                            }
                        }
                        .padding(16)
                        .background(AppConstants.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Ticket button
                        if let ticketUrlString = event.ticketUrl, let ticketUrl = URL(string: ticketUrlString) {
                            Button {
                                showTicketSafari = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "ticket.fill")
                                        .font(.system(size: 16))
                                    Text("Get Tickets")
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text(event.isFree ? "Free" : event.priceFormatted)
                                        .fontWeight(.bold)
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                }
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .padding(16)
                                .background(AppConstants.Colors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: AppConstants.Colors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .fullScreenCover(isPresented: $showTicketSafari) {
                                let userId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
                                Task { await viewModel.toggleRSVP(userId: userId, status: .going) }
                            } content: {
                                SafariView(url: ticketUrl)
                                    .ignoresSafeArea()
                            }
                        }

                        // Organizer
                        if let organizer {
                            NavigationLink(value: AppDestination.organizer(organizer.id)) {
                                HStack(spacing: 14) {
                                    OrganizerLogoView(organizer: organizer, size: 48)

                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 5) {
                                            Text(organizer.name)
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                            if organizer.isVerifiedOrganizer {
                                                Image(systemName: "checkmark.seal.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(AppConstants.Colors.info)
                                            }
                                        }
                                        Text("Organizer")
                                            .font(.caption)
                                            .foregroundStyle(AppConstants.Colors.textTertiary)
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
                            .buttonStyle(.plain)
                        }

                        // About
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ABOUT")
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(1)
                                .foregroundStyle(AppConstants.Colors.textTertiary)

                            Text(event.description)
                                .font(.body)
                                .foregroundStyle(AppConstants.Colors.textSecondary)
                                .lineSpacing(5)
                        }

                        // External link
                        if let urlString = event.externalUrl, let url = URL(string: urlString) {
                            Link(destination: url) {
                                HStack(spacing: 10) {
                                    Image(systemName: "link")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("View on organizer's site")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                }
                                .font(.subheadline)
                                .foregroundStyle(AppConstants.Colors.accent)
                                .padding(16)
                                .background(AppConstants.Colors.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }

                        // Photo Recap & Chat
                        VStack(spacing: 10) {
                            NavigationLink {
                                EventRecapView(eventId: event.id)
                            } label: {
                                detailActionRow(icon: "photo.on.rectangle.angled", title: "Photo Recap", color: AppConstants.Colors.pink)
                            }

                            NavigationLink {
                                EventChatView(eventId: event.id)
                            } label: {
                                detailActionRow(icon: "bubble.left.and.bubble.right.fill", title: "Event Chat", color: AppConstants.Colors.info)
                            }
                        }

                        // Share
                        ShareLink(
                            item: event.externalUrl ?? "Check out \(event.title) on Drift!",
                            preview: SharePreview(event.title)
                        ) {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Share Event")
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(AppConstants.Colors.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Check-in
                        if viewModel.canCheckIn {
                            let nearEvent = viewModel.isNearEvent(locationManager: locationManager)
                            Button {
                                let userId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
                                Task { await viewModel.checkIn(userId: userId) }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: viewModel.isCheckedIn ? "checkmark.circle.fill" : (nearEvent ? "location.fill" : "location.slash"))
                                    Text(viewModel.isCheckedIn ? "Checked In" : (nearEvent ? "Check In" : "Too far to check in"))
                                        .fontWeight(.bold)
                                }
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(viewModel.isCheckedIn ? AppConstants.Colors.success : (nearEvent ? AppConstants.Colors.purple : AppConstants.Colors.secondaryBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(
                                    color: (viewModel.isCheckedIn ? AppConstants.Colors.success : AppConstants.Colors.purple).opacity(nearEvent ? 0.3 : 0),
                                    radius: 8, x: 0, y: 4
                                )
                            }
                            .disabled(viewModel.isCheckedIn || !nearEvent)
                        }

                        // RSVP
                        RSVPButtonView(
                            isGoing: viewModel.userRSVP?.status == RSVP.RSVPStatus.going.rawValue,
                            isInterested: viewModel.userRSVP?.status == RSVP.RSVPStatus.interested.rawValue,
                            attendeeCount: viewModel.attendeeCount,
                            onGoing: {
                                let userId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
                                Task { await viewModel.toggleRSVP(userId: userId, status: .going) }
                            },
                            onInterested: {
                                let userId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
                                Task { await viewModel.toggleRSVP(userId: userId, status: .interested) }
                            }
                        )
                    }
                    .padding(20)
                    .padding(.bottom, 16)
                }
            } else if viewModel.isLoading {
                ProgressView()
                    .tint(AppConstants.Colors.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 200)
            }
        }
        .background(AppConstants.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    bookmarkViewModel.toggle(eventId)
                } label: {
                    Image(systemName: bookmarkViewModel.isBookmarked(eventId) ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(bookmarkViewModel.isBookmarked(eventId) ? AppConstants.Colors.accent : AppConstants.Colors.textSecondary)
                }
                .accessibilityLabel(bookmarkViewModel.isBookmarked(eventId) ? "Remove bookmark" : "Bookmark this event")
            }
        }
        .navigationDestination(for: AppDestination.self) { destination in
            switch destination {
            case .event(let id): EventDetailView(eventId: id)
            case .organizer(let id): OrganizerDetailView(organizerId: id)
            }
        }
        .task {
            await viewModel.loadEvent(id: eventId)
            let userId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
            await viewModel.loadUserRSVP(userId: userId)
            await viewModel.loadAttendees()
            if let event = viewModel.event {
                organizer = await organizerService.fetchOrganizer(id: event.organizerId)
            }
        }
    }

    // MARK: - Helpers

    private func detailActionRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 9))
            Text(title)
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

    private func heroGradientPlaceholder(event: Event) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [categoryColor.opacity(0.7), categoryColor.opacity(0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 300)
            .overlay {
                Image(systemName: event.categoryEnum?.icon ?? "star")
                    .font(.system(size: 64, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.15))
            }
    }

    private func infoRow(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(AppConstants.Colors.accent)
                .frame(width: 22)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
    }

    private func openMaps(event: Event) {
        let coordinate = CLLocationCoordinate2D(latitude: event.locationLat, longitude: event.locationLng)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = event.locationName
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    private var categoryColor: Color {
        Color(hex: viewModel.event?.categoryEnum?.color ?? "FF6B35")
    }
}
