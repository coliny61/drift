import SwiftUI

struct NotificationPrefsView: View {
    @Environment(SettingsViewModel.self) private var viewModel

    var body: some View {
        List {
            Section {
                Toggle("New Events Near You", isOn: Bindable(viewModel).notifyNewEvents)
                Toggle("Friend Activity", isOn: Bindable(viewModel).notifyFriendActivity)
                Toggle("Event Reminders (1hr before)", isOn: Bindable(viewModel).notifyEventReminders)
                Toggle("Chat Messages", isOn: Bindable(viewModel).notifyChatMessages)
            }
            .tint(AppConstants.Colors.accent)
            .foregroundStyle(.white)
            .listRowBackground(AppConstants.Colors.cardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(AppConstants.Colors.background)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: viewModel.notifyNewEvents) { _, _ in viewModel.saveNotificationPrefs() }
        .onChange(of: viewModel.notifyFriendActivity) { _, _ in viewModel.saveNotificationPrefs() }
        .onChange(of: viewModel.notifyEventReminders) { _, _ in viewModel.saveNotificationPrefs() }
        .onChange(of: viewModel.notifyChatMessages) { _, _ in viewModel.saveNotificationPrefs() }
    }
}
