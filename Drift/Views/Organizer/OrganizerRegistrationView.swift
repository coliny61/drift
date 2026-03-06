import SwiftUI

struct OrganizerRegistrationView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(OrganizerService.self) private var organizerService
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var name = ""
    @State private var slug = ""
    @State private var description = ""
    @State private var instagramHandle = ""
    @State private var website = ""
    @State private var contactEmail = ""
    @State private var selectedCity = "Dallas"
    @State private var isSubmitting = false
    @State private var error: String?
    @State private var showSuccess = false

    private let totalSteps = 3

    var body: some View {
        NavigationStack {
            ZStack {
                AppConstants.Colors.background.ignoresSafeArea()

                if showSuccess {
                    successView
                } else {
                    VStack(spacing: 0) {
                        // Progress bar
                        ProgressView(value: Double(step + 1), total: Double(totalSteps))
                            .tint(AppConstants.Colors.accent)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        TabView(selection: $step) {
                            basicInfoStep.tag(0)
                            linksStep.tag(1)
                            reviewStep.tag(2)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .animation(.easeInOut(duration: 0.3), value: step)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Register as Organizer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppConstants.Colors.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Step 1: Basic Info

    private var basicInfoStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader("Tell us about your organization", subtitle: "This info will appear on your public profile")

                fieldLabel("Organization Name")
                TextField("e.g. 214 Run Club", text: $name)
                    .textFieldStyle(DriftTextFieldStyle())
                    .onChange(of: name) { _, newVal in
                        slug = newVal.lowercased()
                            .replacingOccurrences(of: " ", with: "-")
                            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
                    }

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

                Spacer(minLength: 40)

                PrimaryButtonView(title:"Next") {
                    step = 1
                }
                .disabled(name.isEmpty || description.isEmpty)
                .opacity(name.isEmpty || description.isEmpty ? 0.4 : 1)
            }
            .padding(20)
        }
    }

    // MARK: - Step 2: Links

    private var linksStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader("Links & Contact", subtitle: "Help people find and connect with you")

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

                Spacer(minLength: 40)

                HStack(spacing: 12) {
                    Button {
                        step = 0
                    } label: {
                        Text("Back")
                            .font(.headline)
                            .foregroundStyle(AppConstants.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppConstants.Colors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    PrimaryButtonView(title:"Next") {
                        step = 2
                    }
                    .disabled(contactEmail.isEmpty)
                    .opacity(contactEmail.isEmpty ? 0.4 : 1)
                }
            }
            .padding(20)
        }
    }

    // MARK: - Step 3: Review

    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader("Review & Submit", subtitle: "Your org will be reviewed before going live")

                reviewRow("Name", value: name)
                reviewRow("City", value: selectedCity)
                reviewRow("Description", value: description)
                if !instagramHandle.isEmpty {
                    reviewRow("Instagram", value: "@\(instagramHandle.replacingOccurrences(of: "@", with: ""))")
                }
                if !website.isEmpty {
                    reviewRow("Website", value: website)
                }
                reviewRow("Contact", value: contactEmail)

                // Vetting notice
                HStack(spacing: 12) {
                    Image(systemName: "shield.checkered")
                        .font(.title3)
                        .foregroundStyle(AppConstants.Colors.info)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Verification Required")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Text("Our team will review your application. You'll be able to submit events once verified.")
                            .font(.caption)
                            .foregroundStyle(AppConstants.Colors.textSecondary)
                    }
                }
                .padding(14)
                .background(AppConstants.Colors.info.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(AppConstants.Colors.error)
                }

                Spacer(minLength: 40)

                HStack(spacing: 12) {
                    Button {
                        step = 1
                    } label: {
                        Text("Back")
                            .font(.headline)
                            .foregroundStyle(AppConstants.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppConstants.Colors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    PrimaryButtonView(title:"Submit") {
                        Task { await submit() }
                    }
                    .disabled(isSubmitting)
                    .opacity(isSubmitting ? 0.6 : 1)
                    .overlay {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppConstants.Colors.success)

            Text("Application Submitted!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("We'll review your organizer profile and get back to you. You'll be notified once verified.")
                .font(.subheadline)
                .foregroundStyle(AppConstants.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            PrimaryButtonView(title:"Done") {
                dismiss()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Submit

    private func submit() async {
        let profileId = authViewModel.currentProfile?.id ?? authViewModel.localUserId

        isSubmitting = true
        error = nil

        let cleanHandle = instagramHandle.replacingOccurrences(of: "@", with: "")

        let organizer = Organizer(
            id: UUID(),
            profileId: profileId,
            name: name,
            slug: slug,
            description: description,
            logoUrl: nil,
            instagramHandle: cleanHandle.isEmpty ? nil : cleanHandle,
            isVerified: false,
            verificationStatus: "pending",
            isFeatured: false,
            featuredUntil: nil,
            website: website.isEmpty ? nil : website,
            contactEmail: contactEmail,
            city: selectedCity
        )

        do {
            try await organizerService.createOrganizer(organizer)
            showSuccess = true
            HapticManager.selection()
        } catch {
            self.error = error.localizedDescription
        }
        isSubmitting = false
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppConstants.Colors.textSecondary)
        }
        .padding(.bottom, 4)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(AppConstants.Colors.textSecondary)
    }

    private func reviewRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppConstants.Colors.textTertiary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppConstants.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

}

// MARK: - Text Field Style

struct DriftTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(14)
            .background(AppConstants.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
    }
}
