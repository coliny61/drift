import Foundation
import MapKit
import SwiftUI

struct EventCluster: Identifiable {
    let id = UUID()
    let events: [Event]
    let centerLat: Double
    let centerLng: Double

    var isSingle: Bool { events.count == 1 }
    var event: Event? { events.first }
    var count: Int { events.count }
}

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

    /// Groups of events that are too close together at the current zoom level
    var clusters: [EventCluster] {
        let threshold = clusterThreshold
        var used = Set<UUID>()
        var result: [EventCluster] = []

        let evts = filteredEvents
        for event in evts {
            guard !used.contains(event.id) else { continue }
            var group = [event]
            used.insert(event.id)

            for other in evts where !used.contains(other.id) {
                let latDiff = abs(event.locationLat - other.locationLat)
                let lngDiff = abs(event.locationLng - other.locationLng)
                if latDiff < threshold && lngDiff < threshold {
                    group.append(other)
                    used.insert(other.id)
                }
            }

            let avgLat = group.map(\.locationLat).reduce(0, +) / Double(group.count)
            let avgLng = group.map(\.locationLng).reduce(0, +) / Double(group.count)
            result.append(EventCluster(events: group, centerLat: avgLat, centerLng: avgLng))
        }
        return result
    }

    /// Clustering distance threshold based on current zoom span
    private var clusterThreshold: Double {
        // When zoomed out (large span), cluster more aggressively
        switch region.span.latitudeDelta {
        case 0..<0.02: return 0.001   // Very zoomed in — almost no clustering
        case 0.02..<0.05: return 0.005
        case 0.05..<0.15: return 0.01
        default: return 0.02           // Zoomed out — cluster within ~1 mile
        }
    }

    func loadEvents() async {
        // Show cached pins instantly
        if events.isEmpty, let cached = EventCacheService.load() {
            events = cached
        }
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

    func updateRegion(_ region: MKCoordinateRegion) {
        self.region = region
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
