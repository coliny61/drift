import SwiftUI
import PhotosUI

struct EditOrganizerView: View {
    let organizer: Organizer
    @Environment(OrganizerService.self) private var organizerService
    @Environment(EventService.self) private var eventService
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var selectedCity = "Dallas"
    @State private var instagramHandle = ""
    @State private var website = ""
    @State private var contactEmail = ""
    @State private var isSaving = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var logoData: Data?
    @State private var isUploadingLogo = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo
                    VStack(spacing: 8) {
                        ZStack {
                            if let data = logoData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 88, height: 88)
                                    .clipShape(Circle())
                            } else {
                                OrganizerLogoView(organizer: organizer, size: 88)
                            }

                            if isUploadingLogo {
                                Circle()
                                    .fill(.black.opacity(0.5))
                                    .frame(width: 88, height: 88)
                                    .overlay {
                                        ProgressView()
                                            .tint(.white)
                                    }
                            }
                        }

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Text("Change Logo")
                                .font(.subheadline)
                                .foregroundStyle(AppConstants.Colors.accent)
                        }
                        .disabled(isUploadingLogo)
                    }
                    .padding(.top, 20)

                    // Fields
                    VStack(alignment: .leading, spacing: 16) {
                        fieldLabel("Organization Name")
                        TextField("Name", text: $name)
                            .textFieldStyle(DriftTextFieldStyle())

                        fieldLabel("Description")
                        TextField("What does your organization do?", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(DriftTextFieldStyle())

                        fieldLabel("City")
                        Picker("City", selection: $selectedCity) {
                            ForEach(AppConstants.dfwCities, id: \.self) { city in
                                Text(city).tag(city)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppConstants.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .tint(.white)

                        fieldLabel("Instagram Handle (optional)")
                        TextField("@yourhandle", text: $instagramHandle)
                            .textFieldStyle(DriftTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        fieldLabel("Website (optional)")
                        TextField("https://", text: $website)
                            .textFieldStyle(DriftTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)

                        fieldLabel("Contact Email")
                        TextField("hello@yourorg.com", text: $contactEmail)
                            .textFieldStyle(DriftTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                    }
                    .padding(.horizontal)

                    if let error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(AppConstants.Colors.error)
                            .padding(.horizontal)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppConstants.Colors.background)
            .navigationTitle("Edit Organization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppConstants.Colors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppConstants.Colors.accent)
                    .disabled(isSaving || isUploadingLogo || name.isEmpty)
                }
            }
            .onAppear {
                name = organizer.name
                description = organizer.description
                selectedCity = organizer.city ?? "Dallas"
                instagramHandle = organizer.instagramHandle ?? ""
                website = organizer.website ?? ""
                contactEmail = organizer.contactEmail ?? ""
            }
            .onChange(of: selectedPhoto) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        logoData = data
                        isUploadingLogo = true
                        do {
                            let url = try await StorageService.uploadOrganizerLogo(
                                client: eventService.supabaseClient,
                                organizerId: organizer.id,
                                imageData: data
                            )
                            // URL stored, will be set on the organizer during save
                            _ = url
                        } catch {
                            logoData = nil
                            self.error = "Failed to upload logo"
                        }
                        isUploadingLogo = false
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func save() async {
        isSaving = true
        error = nil

        let cleanHandle = instagramHandle.replacingOccurrences(of: "@", with: "")

        var logoUrl = organizer.logoUrl
        if logoData != nil {
            // Logo was uploaded — construct the URL
            let fileName = "org_\(organizer.id.uuidString).jpg"
            if let url = try? eventService.supabaseClient.storage.from("avatars").getPublicURL(path: fileName) {
                logoUrl = url.absoluteString
            }
        }

        let updated = Organizer(
            id: organizer.id,
            profileId: organizer.profileId,
            name: name,
            slug: organizer.slug,
            description: description,
            logoUrl: logoUrl,
            instagramHandle: cleanHandle.isEmpty ? nil : cleanHandle,
            isVerified: organizer.isVerified,
            verificationStatus: organizer.verificationStatus,
            isFeatured: organizer.isFeatured,
            featuredUntil: organizer.featuredUntil,
            website: website.isEmpty ? nil : website,
            contactEmail: contactEmail.isEmpty ? nil : contactEmail,
            city: selectedCity
        )

        do {
            try await organizerService.updateOrganizer(updated)
            HapticManager.selection()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(AppConstants.Colors.textSecondary)
    }
}
