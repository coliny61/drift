import SwiftUI

struct SettingsView: View {
    @Environment(SettingsViewModel.self) private var viewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            List {
                // Appearance
                Section {
                    Picker("Appearance", selection: Bindable(viewModel).appearance) {
                        ForEach(SettingsViewModel.Appearance.allCases, id: \.self) { appearance in
                            Text(appearance.rawValue).tag(appearance)
                        }
                    }
                    .listRowBackground(Color(hex: "1A1A1A"))
                    .foregroundStyle(.white)
                } header: {
                    Text("Appearance").foregroundStyle(Color(hex: "9CA3AF"))
                }

                // Notifications
                Section {
                    notificationToggle("New Events Nearby", isOn: Bindable(viewModel).notifyNewEvents)
                    notificationToggle("Friend Activity", isOn: Bindable(viewModel).notifyFriendActivity)
                    notificationToggle("Event Reminders", isOn: Bindable(viewModel).notifyEventReminders)
                    notificationToggle("Chat Messages", isOn: Bindable(viewModel).notifyChatMessages)
                } header: {
                    Text("Notifications").foregroundStyle(Color(hex: "9CA3AF"))
                }

                // About
                Section {
                    HStack {
                        Text("Version")
                            .foregroundStyle(.white)
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(Color(hex: "9CA3AF"))
                    }
                    .listRowBackground(Color(hex: "1A1A1A"))
                } header: {
                    Text("About").foregroundStyle(Color(hex: "9CA3AF"))
                }

                // Account
                Section {
                    Button {
                        showSignOutAlert = true
                    } label: {
                        Text("Sign Out")
                            .foregroundStyle(Color(hex: "EF5350"))
                    }
                    .listRowBackground(Color(hex: "1A1A1A"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: "0A0A0A"))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(hex: "FF6B35"))
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
        .preferredColorScheme(.dark)
    }

    private func notificationToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .tint(Color(hex: "FF6B35"))
            .foregroundStyle(.white)
            .listRowBackground(Color(hex: "1A1A1A"))
            .onChange(of: isOn.wrappedValue) { _, _ in
                viewModel.saveNotificationPrefs()
            }
    }
}
