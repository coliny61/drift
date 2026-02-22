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
    var calendarAdded = false
    var showShareSheet = false

    init(eventService: EventService, rsvpService: RSVPService) {
        self.eventService = eventService
        self.rsvpService = rsvpService
    }

    func loadEvent(id: UUID) async {
        isLoading = true
        event = await eventService.fetchEvent(id: id)
        if let event {
            attendeeCount = event.rsvpCount
        }
        isLoading = false
    }

    func toggleRSVP(userId: UUID, status: RSVP.RSVPStatus) async {
        guard let event else { return }

        if let existingRSVP = userRSVP, existingRSVP.status == status.rawValue {
            // Remove RSVP
            try? await rsvpService.removeRSVP(eventId: event.id, userId: userId)
            userRSVP = nil
            attendeeCount = max(0, attendeeCount - 1)
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
        }

        HapticManager.impact(.medium)
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
