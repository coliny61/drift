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
    @Environment(\.dismiss) private var dismiss
    @State private var organizer: Organizer?
    @State private var showTicketSafari = false

    var body: some View {
        ScrollView {
            if let event = viewModel.event {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero image
                    ZStack(alignment: .topLeading) {
                        if let urlString = event.coverImageUrl, let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 260)
                                        .clipped()
                                case .failure:
                                    heroGradientPlaceholder(event: event)
                                case .empty:
                                    heroGradientPlaceholder(event: event)
                                        .overlay {
                                            ProgressView()
                                                .tint(.white.opacity(0.5))
                                        }
                                @unknown default:
                                    heroGradientPlaceholder(event: event)
                                }
                            }
                            .frame(height: 260)
                            .overlay(
                                LinearGradient(
                                    colors: [.black.opacity(0.3), .clear, .black.opacity(0.4)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        } else {
                            heroGradientPlaceholder(event: event)
                        }

                        // Tags
                        HStack(spacing: 6) {
                            Text(event.categoryEnum?.displayName ?? event.category)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(categoryColor)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())

                            if event.isAlcoholFree {
                                Text("Alcohol-Free")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: "34D399"))
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }

                            ForEach(event.tags.filter { $0 != "alcohol-free" }.prefix(2), id: \.self) { tag in
                                Text(tag.replacingOccurrences(of: "-", with: " ").capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: "2A2A2A").opacity(0.8))
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding()
                        .padding(.top, 40)
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        Text(event.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        // Date & Time
                        HStack(spacing: 12) {
                            infoRow(icon: "calendar", title: event.startTime.relativeDescription)
                            Spacer()
                            // Add to Calendar
                            Button {
                                Task { await viewModel.addToCalendar() }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: viewModel.calendarAdded ? "checkmark.circle.fill" : "plus.circle")
                                    Text(viewModel.calendarAdded ? "Added" : "Add to Calendar")
                                }
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(viewModel.calendarAdded ? Color(hex: "34D399") : Color(hex: "FF6B35"))
                            }
                        }

                        // Location
                        VStack(alignment: .leading, spacing: 8) {
                            infoRow(icon: "mappin", title: event.locationName)
                            Text(event.locationAddress)
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: "9CA3AF"))
                                .padding(.leading, 28)

                            // Get Directions button
                            Button {
                                openMaps(event: event)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.turn.up.right.diamond")
                                    Text("Get Directions")
                                }
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Color(hex: "FF6B35"))
                                .padding(.leading, 28)
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
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .allowsHitTesting(false)

                        Divider()
                            .background(Color(hex: "2A2A2A"))

                        // Price & Attendees
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Price")
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: "9CA3AF"))
                                Text(event.isFree ? "Free" : event.priceFormatted)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(event.isFree ? Color(hex: "60A5FA") : .white)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Attending")
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: "9CA3AF"))
                                HStack(spacing: 4) {
                                    Image(systemName: "person.2.fill")
                                    Text("\(viewModel.attendeeCount)")
                                }
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(categoryColor)
                            }
                        }

                        // Ticket button
                        if let ticketUrlString = event.ticketUrl, let ticketUrl = URL(string: ticketUrlString) {
                            Button {
                                showTicketSafari = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "ticket.fill")
                                    Text("Get Tickets")
                                        .fontWeight(.semibold)
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
                            }
                            .fullScreenCover(isPresented: $showTicketSafari) {
                                // Auto-RSVP on dismiss
                                let userId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
                                Task { await viewModel.toggleRSVP(userId: userId, status: .going) }
                            } content: {
                                SafariView(url: ticketUrl)
                                    .ignoresSafeArea()
                            }
                        }

                        // Organizer
                        if let organizer {
                            Divider()
                                .background(Color(hex: "2A2A2A"))

                            NavigationLink(value: organizer.id) {
                                HStack(spacing: 12) {
                                    if let logoUrl = organizer.logoUrl, let url = URL(string: logoUrl) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 44, height: 44)
                                                    .clipShape(Circle())
                                            default:
                                                organizerLogoPlaceholder(organizer)
                                            }
                                        }
                                    } else {
                                        organizerLogoPlaceholder(organizer)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 4) {
                                            Text(organizer.name)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.white)
                                            if organizer.isVerifiedOrganizer {
                                                Image(systemName: "checkmark.seal.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(Color(hex: "60A5FA"))
                                            }
                                        }
                                        Text("Organizer")
                                            .font(.caption)
                                            .foregroundStyle(Color(hex: "9CA3AF"))
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Color(hex: "9CA3AF"))
                                }
                                .padding(14)
                                .background(Color(hex: "1A1A1A"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }

                        Divider()
                            .background(Color(hex: "2A2A2A"))

                        // Description
                        Text("About")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text(event.description)
                            .font(.body)
                            .foregroundStyle(Color(hex: "9CA3AF"))
                            .lineSpacing(4)

                        // External link
                        if let urlString = event.externalUrl, let url = URL(string: urlString) {
                            Link(destination: url) {
                                HStack {
                                    Image(systemName: "link")
                                    Text("View on organizer's site")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                }
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: "FF6B35"))
                                .padding()
                                .background(Color(hex: "2A2A2A"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        // Share button
                        ShareLink(
                            item: event.externalUrl ?? "Check out \(event.title) on Drift!",
                            preview: SharePreview(event.title)
                        ) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Event")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "2A2A2A"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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
                }
            } else if viewModel.isLoading {
                ProgressView()
                    .tint(Color(hex: "FF6B35"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 200)
            }
        }
        .background(Color(hex: "0A0A0A"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(for: UUID.self) { id in
            OrganizerDetailView(organizerId: id)
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

    private func heroGradientPlaceholder(event: Event) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [categoryColor.opacity(0.7), categoryColor.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 260)
            .overlay {
                Image(systemName: event.categoryEnum?.icon ?? "star")
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.2))
            }
    }

    private func infoRow(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color(hex: "FF6B35"))
                .frame(width: 20)
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
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

    private func organizerLogoPlaceholder(_ organizer: Organizer) -> some View {
        Circle()
            .fill(AppConstants.Colors.accent.opacity(0.2))
            .frame(width: 44, height: 44)
            .overlay {
                Text(String(organizer.name.prefix(1)))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(AppConstants.Colors.accent)
            }
    }

    private var categoryColor: Color {
        Color(hex: viewModel.event?.categoryEnum?.color ?? "FF6B35")
    }
}
