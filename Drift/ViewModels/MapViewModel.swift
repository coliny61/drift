import Foundation
import MapKit
import SwiftUI

@Observable
final class MapViewModel {
    private let eventService: EventService

    var events: [Event] = []
    var selectedEvent: Event?
    var selectedCategory: Category?
    var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: AppConstants.defaultLatitude,
            longitude: AppConstants.defaultLongitude
        ),
        span: MKCoordinateSpan(
            latitudeDelta: AppConstants.defaultSpan,
            longitudeDelta: AppConstants.defaultSpan
        )
    )
    var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: AppConstants.defaultLatitude,
                longitude: AppConstants.defaultLongitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: AppConstants.defaultSpan,
                longitudeDelta: AppConstants.defaultSpan
            )
        )
    )

    init(eventService: EventService) {
        self.eventService = eventService
    }

    var filteredEvents: [Event] {
        if let category = selectedCategory {
            return events.filter { $0.category == category.slug }
        }
        return events
    }

    func loadEvents() async {
        await eventService.fetchEvents()
        events = eventService.events
    }

    func selectCategory(_ category: Category?) {
        selectedCategory = category
        HapticManager.selection()
    }

    func selectEvent(_ event: Event?) {
        selectedEvent = event
        if let event {
            HapticManager.impact(.light)
            withAnimation {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: event.locationLat, longitude: event.locationLng),
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                )
            }
        }
    }

    func centerOnUser(location: CLLocation?) {
        guard let location else { return }
        cameraPosition = .region(
            MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        )
    }
}
