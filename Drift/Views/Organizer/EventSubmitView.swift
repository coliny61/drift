import SwiftUI
import PhotosUI

struct EventSubmitView: View {
    let organizer: Organizer
    @Environment(EventService.self) private var eventService
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: Category = .runClub
    @State private var tags: Set<String> = []
    @State private var startDate = Date().addingTimeInterval(86400)
    @State private var endDate = Date().addingTimeInterval(86400 + 7200)
    @State private var locationName = ""
    @State private var locationAddress = ""
    @State private var neighborhood = ""
    @State private var city = "Dallas"
    @State private var priceCents = 0
    @State private var isFree = true
    @State private var priceText = ""
    @State private var externalUrl = ""
    @State private var ticketUrl = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var coverImageData: Data?
    @State private var isSubmitting = false
    @State private var error: String?
    @State private var showSuccess = false

    private let totalSteps = 4

    var body: some View {
        NavigationStack {
            ZStack {
                AppConstants.Colors.background.ignoresSafeArea()

                if showSuccess {
                    successView
                } else {
                    VStack(spacing: 0) {
                        ProgressView(value: Double(step + 1), total: Double(totalSteps))
                            .tint(AppConstants.Colors.accent)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        TabView(selection: $step) {
                            detailsStep.tag(0)
                            locationStep.tag(1)
                            mediaStep.tag(2)
                            reviewStep.tag(3)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .animation(.easeInOut(duration: 0.3), value: step)
                    }
                }
            }
            .navigationTitle("Submit Event")
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

    // MARK: - Step 1: Details

    private var detailsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                sectionHeader("Event Details")

                fieldLabel("Title")
                TextField("e.g. Tuesday Night Run Club", text: $title)
                    .textFieldStyle(DriftTextFieldStyle())

                fieldLabel("Description")
                TextField("Tell people what to expect...", text: $description, axis: .vertical)
                    .lineLimit(3...8)
                    .textFieldStyle(DriftTextFieldStyle())

                fieldLabel("Category")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(Category.allCases, id: \.self) { cat in
                        let isSelected = selectedCategory == cat
                        Button {
                            selectedCategory = cat
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: cat.icon).font(.caption)
                                Text(cat.displayName).font(.caption).fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? Color(hex: cat.color).opacity(0.2) : AppConstants.Colors.secondaryBackground)
                            .foregroundStyle(isSelected ? Color(hex: cat.color) : AppConstants.Colors.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }

                fieldLabel("Start")
                DatePicker("", selection: $startDate, in: Date()...)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(AppConstants.Colors.accent)

                fieldLabel("End")
                DatePicker("", selection: $endDate, in: startDate...)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(AppConstants.Colors.accent)

                fieldLabel("Price")
                Toggle("Free Event", isOn: $isFree)
                    .tint(AppConstants.Colors.accent)
                    .foregroundStyle(.white)

                if !isFree {
                    TextField("Price in dollars (e.g. 25)", text: $priceText)
                        .textFieldStyle(DriftTextFieldStyle())
                        .keyboardType(.decimalPad)
                }

                Spacer(minLength: 40)
                navButtons(canProceed: !title.isEmpty && !description.isEmpty) { step = 1 }
            }
            .padding(20)
        }
    }

    // MARK: - Step 2: Location

    private var locationStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                sectionHeader("Location")

                fieldLabel("Venue Name")
                TextField("e.g. Katy Trail", text: $locationName)
                    .textFieldStyle(DriftTextFieldStyle())

                fieldLabel("Address")
                TextField("Full street address", text: $locationAddress)
                    .textFieldStyle(DriftTextFieldStyle())

                fieldLabel("Neighborhood")
                TextField("e.g. Uptown, Deep Ellum", text: $neighborhood)
                    .textFieldStyle(DriftTextFieldStyle())

                fieldLabel("City")
                Picker("City", selection: $city) {
                    ForEach(AppConstants.dfwCities, id: \.self) { c in
                        Text(c).tag(c)
                    }
                }
                .pickerStyle(.menu)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppConstants.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .tint(.white)

                fieldLabel("External Link (optional)")
                TextField("https://", text: $externalUrl)
                    .textFieldStyle(DriftTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)

                fieldLabel("Ticket Link (optional)")
                TextField("https://", text: $ticketUrl)
                    .textFieldStyle(DriftTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)

                Spacer(minLength: 40)
                HStack(spacing: 12) {
                    backButton { step = 0 }
                    navButtons(canProceed: !locationName.isEmpty && !locationAddress.isEmpty) { step = 2 }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Step 3: Media

    private var mediaStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                sectionHeader("Cover Image (optional)")

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    if let data = coverImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 36))
                                .foregroundStyle(AppConstants.Colors.textTertiary)
                            Text("Tap to add a cover image")
                                .font(.subheadline)
                                .foregroundStyle(AppConstants.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(AppConstants.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .onChange(of: selectedPhoto) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            coverImageData = data
                        }
                    }
                }

                fieldLabel("Tags (optional)")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 8) {
                    ForEach(AppConstants.availableTags, id: \.self) { tag in
                        let isSelected = tags.contains(tag)
                        Button {
                            if isSelected { tags.remove(tag) } else { tags.insert(tag) }
                        } label: {
                            Text(tag.replacingOccurrences(of: "-", with: " ").capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(isSelected ? AppConstants.Colors.accent.opacity(0.2) : AppConstants.Colors.secondaryBackground)
                                .foregroundStyle(isSelected ? AppConstants.Colors.accent : AppConstants.Colors.textSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }

                Spacer(minLength: 40)
                HStack(spacing: 12) {
                    backButton { step = 1 }
                    navButtons(canProceed: true) { step = 3 }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Step 4: Review

    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                sectionHeader("Review & Submit")

                reviewRow("Title", value: title)
                reviewRow("Category", value: selectedCategory.displayName)
                reviewRow("Date", value: startDate.formatted(date: .abbreviated, time: .shortened))
                reviewRow("Venue", value: locationName)
                reviewRow("Address", value: locationAddress)
                reviewRow("City", value: city)
                reviewRow("Price", value: isFree ? "Free" : "$\(priceText)")

                HStack(spacing: 12) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.title3)
                        .foregroundStyle(Color(hex: "FBBF24"))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Under Review")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Text("Your event will be visible after approval.")
                            .font(.caption)
                            .foregroundStyle(AppConstants.Colors.textSecondary)
                    }
                }
                .padding(14)
                .background(Color(hex: "FBBF24").opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color(hex: "EF5350"))
                }

                Spacer(minLength: 40)
                HStack(spacing: 12) {
                    backButton { step = 2 }
                    primaryButton("Submit Event") {
                        Task { await submitEvent() }
                    }
                    .disabled(isSubmitting)
                    .opacity(isSubmitting ? 0.6 : 1)
                    .overlay {
                        if isSubmitting { ProgressView().tint(.white) }
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
            Text("Event Submitted!")
                .font(.title2).fontWeight(.bold).foregroundStyle(.white)
            Text("Your event is under review. You'll be notified once it's approved and visible to the community.")
                .font(.subheadline)
                .foregroundStyle(AppConstants.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            primaryButton("Done") { dismiss() }
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
        }
    }

    // MARK: - Submit

    private func submitEvent() async {
        isSubmitting = true
        error = nil

        let cents = isFree ? 0 : Int((Double(priceText) ?? 0) * 100)

        let event = Event(
            id: UUID(),
            organizerId: organizer.id,
            title: title,
            description: description,
            shortDescription: String(description.prefix(100)),
            coverImageUrl: nil,
            category: selectedCategory.slug,
            tags: Array(tags),
            startTime: startDate,
            endTime: endDate,
            recurrenceRule: nil,
            locationName: locationName,
            locationAddress: locationAddress,
            locationLat: AppConstants.defaultLatitude,
            locationLng: AppConstants.defaultLongitude,
            neighborhood: neighborhood,
            maxCapacity: nil,
            priceCents: cents,
            externalUrl: externalUrl.isEmpty ? nil : externalUrl,
            isFeatured: false,
            rsvpCount: 0,
            status: "upcoming",
            approvalStatus: "pending",
            submittedBy: authViewModel.currentProfile?.id,
            city: city,
            ticketUrl: ticketUrl.isEmpty ? nil : ticketUrl
        )

        do {
            try await eventService.createEvent(event)
            showSuccess = true
            HapticManager.selection()
        } catch {
            self.error = error.localizedDescription
        }
        isSubmitting = false
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(.white)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(AppConstants.Colors.textSecondary)
    }

    private func reviewRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(AppConstants.Colors.textTertiary)
            Text(value).font(.subheadline).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppConstants.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func navButtons(canProceed: Bool, action: @escaping () -> Void) -> some View {
        primaryButton("Next", action: action)
            .disabled(!canProceed)
            .opacity(canProceed ? 1 : 0.4)
    }

    private func backButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Back")
                .font(.headline)
                .foregroundStyle(AppConstants.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppConstants.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppConstants.Colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
