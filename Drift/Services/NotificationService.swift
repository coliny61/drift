import Foundation
import UserNotifications

@Observable
final class NotificationService {
    var isAuthorized = false

    init() {
        Task { await checkAuthorization() }
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Event Reminders

    func scheduleEventReminder(event: Event, minutesBefore: Int = 60) async {
        guard UserDefaults.standard.bool(forKey: "drift_notify_reminders") else { return }
        if !isAuthorized {
            let granted = await requestPermission()
            guard granted else { return }
        }

        let content = UNMutableNotificationContent()
        content.title = "Event Starting Soon"
        content.body = "\(event.title) starts in \(minutesBefore) minutes at \(event.locationName)"
        content.sound = .default
        content.userInfo = ["eventId": event.id.uuidString]

        let triggerDate = event.startTime.addingTimeInterval(-Double(minutesBefore * 60))
        guard triggerDate > Date() else { return }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "event-reminder-\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    func cancelEventReminder(eventId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["event-reminder-\(eventId.uuidString)"]
        )
    }

    // MARK: - RSVP Confirmation

    func sendRSVPConfirmation(event: Event) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "You're going!"
        content.body = "You RSVP'd to \(event.title). We'll remind you before it starts."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "rsvp-confirm-\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Device Token

    func saveDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(tokenString, forKey: "drift_device_token")
    }
}
