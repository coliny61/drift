import Foundation
import EventKit
import Supabase

@Observable
final class EventDetailViewModel {
    private let eventService: EventService
    private let rsvpService: RSVPService

    var event: Event?
    var organizer: Organizer?
    var userRSVP: RSVP?
    var attendees: [Profile] = []
    var attendeeCount: Int = 0
    var isLoading = false
    var loadError = false
    var calendarAdded = false
    var showShareSheet = false

    init(eventService: EventService, rsvpService: RSVPService) {
        self.eventService = eventService
        self.rsvpService = rsvpService
    }

    func loadEvent(id: UUID) async {
        isLoading = true
        loadError = false
        event = await eventService.fetchEvent(id: id)
        if let event {
            attendeeCount = event.rsvpCount
        } else {
            loadError = true
        }
        isLoading = false
    }

    func loadUserRSVP(userId: UUID) async {
        guard let event else { return }
        userRSVP = await rsvpService.getUserRSVP(eventId: event.id, userId: userId)
        // Fallback to locally stored RSVP
        if userRSVP == nil, let localStatus = Self.localRSVPs()[event.id.uuidString] {
            userRSVP = RSVP(id: UUID(), eventId: event.id, userId: userId, status: localStatus, createdAt: .now)
        }
    }

    func loadAttendees() async {
        guard let event else { return }
        attendees = await rsvpService.getEventAttendees(eventId: event.id)
        if !attendees.isEmpty {
            attendeeCount = attendees.count
        }
    }

    func toggleRSVP(userId: UUID, status: RSVP.RSVPStatus) async {
        guard let event else { return }

        if let existingRSVP = userRSVP, existingRSVP.status == status.rawValue {
            // Remove RSVP
            try? await rsvpService.removeRSVP(eventId: event.id, userId: userId)
            userRSVP = nil
            attendeeCount = max(0, attendeeCount - 1)
            Self.removeLocalRSVP(eventId: event.id)
        } else {
            // Add/update RSVP
            try? await rsvpService.rsvp(eventId: event.id, userId: userId, status: status)
            if userRSVP == nil { attendeeCount += 1 }
            userRSVP = RSVP(
                id: UUID(),
                eventId: event.id,
                userId: userId,
                status: status.rawValue,
                createdAt: .now
            )
            Self.saveLocalRSVP(eventId: event.id, status: status)
        }

        HapticManager.impact(.medium)
    }

    func checkIn(userId: UUID) async {
        guard let event else { return }
        try? await rsvpService.checkIn(eventId: event.id, userId: userId)
        userRSVP = RSVP(
            id: UUID(),
            eventId: event.id,
            userId: userId,
            status: RSVP.RSVPStatus.checkedIn.rawValue,
            createdAt: .now
        )
        Self.saveLocalRSVP(eventId: event.id, status: .checkedIn)
        HapticManager.notification(.success)
    }

    var canCheckIn: Bool {
        guard let event else { return false }
        let now = Date()
        let checkInStart = event.startTime.addingTimeInterval(-1800) // 30 min before
        let checkInEnd = event.endTime
        return now >= checkInStart && now <= checkInEnd
    }

    /// Check if user is within proximity (~0.5 miles) of the event
    func isNearEvent(locationManager: LocationManager) -> Bool {
        guard let event else { return false }
        guard let distance = locationManager.distanceTo(lat: event.locationLat, lng: event.locationLng) else {
            return true // If no location, allow check-in (don't block)
        }
        return distance <= 0.5
    }

    var isCheckedIn: Bool {
        userRSVP?.isCheckedIn ?? false
    }

    // MARK: - Local RSVP storage (for browse-without-account mode)

    private static let localRSVPKey = "drift_local_rsvps"

    /// Returns locally stored RSVPs as [eventId: status] dictionary
    static func localRSVPs() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: localRSVPKey) as? [String: String] ?? [:]
    }

    static func saveLocalRSVP(eventId: UUID, status: RSVP.RSVPStatus) {
        var rsvps = localRSVPs()
        rsvps[eventId.uuidString] = status.rawValue
        UserDefaults.standard.set(rsvps, forKey: localRSVPKey)
    }

    static func removeLocalRSVP(eventId: UUID) {
        var rsvps = localRSVPs()
        rsvps.removeValue(forKey: eventId.uuidString)
        UserDefaults.standard.set(rsvps, forKey: localRSVPKey)
    }

    func addToCalendar() async {
        guard let event else { return }

        let store = EKEventStore()

        do {
            let granted = try await store.requestFullAccessToEvents()
            guard granted else { return }

            let calendarEvent = EKEvent(eventStore: store)
            calendarEvent.title = event.title
            calendarEvent.startDate = event.startTime
            calendarEvent.endDate = event.endTime
            calendarEvent.location = event.locationAddress
            calendarEvent.notes = event.description
            calendarEvent.calendar = store.defaultCalendarForNewEvents

            try store.save(calendarEvent, span: .thisEvent)
            calendarAdded = true
            HapticManager.notification(.success)
        } catch {
            print("Calendar error: \(error)")
        }
    }

    func shareURL() -> URL? {
        guard let event else { return nil }
        if let externalURL = event.externalUrl {
            return URL(string: externalURL)
        }
        return nil
    }
}
