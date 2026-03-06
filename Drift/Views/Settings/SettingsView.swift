import SwiftUI

struct SettingsView: View {
    @Environment(SettingsViewModel.self) private var viewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSignOutAlert = false
    @State private var showDeleteAlert = false

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
                    .listRowBackground(AppConstants.Colors.cardBackground)
                    .foregroundStyle(.white)
                } header: {
                    Text("Appearance").foregroundStyle(AppConstants.Colors.textSecondary)
                }

                // Notifications
                Section {
                    notificationToggle("New Events Nearby", isOn: Bindable(viewModel).notifyNewEvents)
                    notificationToggle("Friend Activity", isOn: Bindable(viewModel).notifyFriendActivity)
                    notificationToggle("Event Reminders", isOn: Bindable(viewModel).notifyEventReminders)
                    notificationToggle("Chat Messages", isOn: Bindable(viewModel).notifyChatMessages)
                } header: {
                    Text("Notifications").foregroundStyle(AppConstants.Colors.textSecondary)
                }

                // About
                Section {
                    HStack {
                        Text("Version")
                            .foregroundStyle(.white)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(AppConstants.Colors.textSecondary)
                    }
                    .listRowBackground(AppConstants.Colors.cardBackground)
                } header: {
                    Text("About").foregroundStyle(AppConstants.Colors.textSecondary)
                }

                // Legal
                Section {
                    Link(destination: URL(string: "https://driftdfw.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(AppConstants.Colors.textTertiary)
                        }
                    }
                    .listRowBackground(AppConstants.Colors.cardBackground)

                    Link(destination: URL(string: "https://driftdfw.com/terms")!) {
                        HStack {
                            Text("Terms of Service")
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(AppConstants.Colors.textTertiary)
                        }
                    }
                    .listRowBackground(AppConstants.Colors.cardBackground)
                } header: {
                    Text("Legal").foregroundStyle(AppConstants.Colors.textSecondary)
                }

                // Account
                Section {
                    Button {
                        showSignOutAlert = true
                    } label: {
                        Text("Sign Out")
                            .foregroundStyle(AppConstants.Colors.accent)
                    }
                    .listRowBackground(AppConstants.Colors.cardBackground)

                    Button {
                        showDeleteAlert = true
                    } label: {
                        Text("Delete Account")
                            .foregroundStyle(AppConstants.Colors.error)
                    }
                    .listRowBackground(AppConstants.Colors.cardBackground)
                } header: {
                    Text("Account").foregroundStyle(AppConstants.Colors.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppConstants.Colors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppConstants.Colors.accent)
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
            .alert("Delete Account", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await authViewModel.deleteAccount()
                        dismiss()
                    }
                }
            } message: {
                Text("This will permanently delete your account and all associated data. This action cannot be undone.")
            }
        }
        .preferredColorScheme(.dark)
    }

    private func notificationToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .tint(AppConstants.Colors.accent)
            .foregroundStyle(.white)
            .listRowBackground(AppConstants.Colors.cardBackground)
            .onChange(of: isOn.wrappedValue) { _, _ in
                viewModel.saveNotificationPrefs()
            }
    }
}
