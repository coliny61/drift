import Foundation
import SwiftUI

@Observable
final class SettingsViewModel {
    var appearance: Appearance {
        didSet { saveAppearance() }
    }
    var notifyNewEvents = true
    var notifyFriendActivity = true
    var notifyEventReminders = true
    var notifyChatMessages = true

    enum Appearance: String, CaseIterable {
        case dark = "Dark"
        case light = "Light"
        case system = "System"
    }

    init() {
        // Register defaults so toggles start ON
        UserDefaults.standard.register(defaults: [
            "drift_notify_events": true,
            "drift_notify_friends": true,
            "drift_notify_reminders": true,
            "drift_notify_chat": true
        ])
        let saved = UserDefaults.standard.string(forKey: "drift_appearance") ?? "dark"
        appearance = Appearance(rawValue: saved) ?? .dark
        notifyNewEvents = UserDefaults.standard.bool(forKey: "drift_notify_events")
        notifyFriendActivity = UserDefaults.standard.bool(forKey: "drift_notify_friends")
        notifyEventReminders = UserDefaults.standard.bool(forKey: "drift_notify_reminders")
        notifyChatMessages = UserDefaults.standard.bool(forKey: "drift_notify_chat")
    }

    var colorScheme: ColorScheme? {
        switch appearance {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }

    private func saveAppearance() {
        UserDefaults.standard.set(appearance.rawValue, forKey: "drift_appearance")
    }

    func saveNotificationPrefs() {
        UserDefaults.standard.set(notifyNewEvents, forKey: "drift_notify_events")
        UserDefaults.standard.set(notifyFriendActivity, forKey: "drift_notify_friends")
        UserDefaults.standard.set(notifyEventReminders, forKey: "drift_notify_reminders")
        UserDefaults.standard.set(notifyChatMessages, forKey: "drift_notify_chat")
    }
}
