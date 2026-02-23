import SwiftUI

struct EditProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var selectedInterests: Set<Category> = []
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar
                    VStack(spacing: 8) {
                        AvatarView(
                            url: authViewModel.currentProfile?.avatarUrl,
                            size: 80,
                            fallbackInitials: String(displayName.prefix(1))
                        )
                        Button("Change Photo") {}
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: "FF6B35"))
                    }
                    .padding(.top, 20)

                    // Fields
                    VStack(spacing: 16) {
                        fieldRow(title: "Display Name", text: $displayName)
                        fieldRow(title: "Username", text: $username)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bio")
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: "9CA3AF"))
                            TextEditor(text: $bio)
                                .frame(height: 80)
                                .padding(8)
                                .background(Color(hex: "1A1A1A"))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.white)
                                .scrollContentBackground(.hidden)
                        }
                    }
                    .padding(.horizontal)

                    // Interests
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Interests")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(Category.allCases, id: \.self) { category in
                                let isSelected = selectedInterests.contains(category)
                                Button {
                                    if isSelected { selectedInterests.remove(category) }
                                    else { selectedInterests.insert(category) }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: category.icon)
                                            .font(.caption)
                                        Text(category.displayName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(isSelected ? Color(hex: category.color).opacity(0.2) : Color(hex: "2A2A2A"))
                                    .foregroundStyle(isSelected ? Color(hex: category.color) : Color(hex: "9CA3AF"))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .background(Color(hex: "0A0A0A"))
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color(hex: "9CA3AF"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
                            guard let existing = authViewModel.currentProfile else { return }
                            isSaving = true
                            let updated = Profile(
                                id: existing.id,
                                username: username,
                                displayName: displayName,
                                bio: bio.isEmpty ? nil : bio,
                                avatarUrl: existing.avatarUrl,
                                interests: selectedInterests.map(\.slug),
                                locationLat: existing.locationLat,
                                locationLng: existing.locationLng,
                                neighborhood: existing.neighborhood,
                                streakCount: existing.streakCount,
                                eventsAttended: existing.eventsAttended,
                                createdAt: existing.createdAt
                            )
                            try? await authViewModel.updateProfile(updated)
                            isSaving = false
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: "FF6B35"))
                    .disabled(isSaving)
                }
            }
            .onAppear {
                if let profile = authViewModel.currentProfile {
                    displayName = profile.displayName
                    username = profile.username
                    bio = profile.bio ?? ""
                    selectedInterests = Set(Category.allCases.filter { profile.interests.contains($0.slug) })
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func fieldRow(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color(hex: "9CA3AF"))
            TextField(title, text: text)
                .padding(12)
                .background(Color(hex: "1A1A1A"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)
        }
    }
}
