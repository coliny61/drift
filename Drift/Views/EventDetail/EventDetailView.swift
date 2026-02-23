import SwiftUI
import MapKit

struct EventDetailView: View {
    let eventId: UUID
    @Environment(EventDetailViewModel.self) private var viewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            if let event = viewModel.event {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero image
                    ZStack(alignment: .topLeading) {
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
        .task {
            await viewModel.loadEvent(id: eventId)
            let userId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
            await viewModel.loadUserRSVP(userId: userId)
            await viewModel.loadAttendees()
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

    private var categoryColor: Color {
        Color(hex: viewModel.event?.categoryEnum?.color ?? "FF6B35")
    }
}
