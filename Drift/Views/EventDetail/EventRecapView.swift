import SwiftUI
import PhotosUI

struct EventRecapView: View {
    let eventId: UUID
    @Environment(PhotoService.self) private var photoService
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploading = false
    @State private var selectedImage: EventPhoto?

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    private var currentUserId: UUID {
        authViewModel.currentProfile?.id ?? authViewModel.localUserId
    }

    var body: some View {
        ScrollView {
            if photoService.photos.isEmpty && !isUploading {
                EmptyStateView(
                    icon: "photo.on.rectangle.angled",
                    title: "No Photos Yet",
                    message: "Be the first to share a photo from this event"
                )
                .padding(.top, 60)
            } else {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(photoService.photos) { photo in
                        Button {
                            selectedImage = photo
                        } label: {
                            AsyncImage(url: URL(string: photo.photoUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Rectangle()
                                    .fill(AppConstants.Colors.secondaryBackground)
                            }
                            .frame(height: 120)
                            .clipped()
                        }
                    }
                }
            }
        }
        .background(AppConstants.Colors.background)
        .navigationTitle("Recap (\(photoService.photos.count))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppConstants.Colors.accent)
                }
            }
        }
        .overlay {
            if isUploading {
                Color.black.opacity(0.5).ignoresSafeArea()
                ProgressView("Uploading...")
                    .tint(.white)
                    .foregroundStyle(.white)
            }
        }
        .sheet(item: $selectedImage) { photo in
            PhotoDetailSheet(photo: photo, currentUserId: currentUserId)
        }
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else { return }
            Task { await uploadPhoto(item: newItem) }
        }
        .task {
            await photoService.fetchPhotos(eventId: eventId)
        }
    }

    private func uploadPhoto(item: PhotosPickerItem) async {
        isUploading = true
        defer { isUploading = false }

        guard let data = try? await item.loadTransferable(type: Data.self) else { return }

        do {
            let photo = try await photoService.uploadPhoto(
                eventId: eventId,
                userId: currentUserId,
                imageData: data,
                caption: nil
            )
            photoService.photos.insert(photo, at: 0)
            HapticManager.notification(.success)
        } catch {
            print("Upload failed: \(error)")
        }

        selectedPhoto = nil
    }
}

// MARK: - Photo Detail Sheet

struct PhotoDetailSheet: View {
    let photo: EventPhoto
    let currentUserId: UUID
    @Environment(PhotoService.self) private var photoService
    @Environment(\.dismiss) private var dismiss

    private let reactions = ["fire", "heart", "clap", "camera", "star"]
    private let reactionEmojis: [String: String] = [
        "fire": "🔥",
        "heart": "❤️",
        "clap": "👏",
        "camera": "📸",
        "star": "⭐"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AsyncImage(url: URL(string: photo.photoUrl)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    Rectangle()
                        .fill(AppConstants.Colors.secondaryBackground)
                        .frame(height: 300)
                }

                if let caption = photo.caption, !caption.isEmpty {
                    Text(caption)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding()
                }

                // Reactions
                HStack(spacing: 16) {
                    ForEach(reactions, id: \.self) { reaction in
                        Button {
                            Task {
                                try? await photoService.addReaction(
                                    photoId: photo.id,
                                    userId: currentUserId,
                                    reactionType: reaction
                                )
                                HapticManager.impact(.light)
                            }
                        } label: {
                            Text(reactionEmojis[reaction] ?? "")
                                .font(.title2)
                                .padding(10)
                                .background(AppConstants.Colors.cardBackground)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.top, 16)

                Text(photo.createdAt.relativeDescription)
                    .font(.caption)
                    .foregroundStyle(AppConstants.Colors.textSecondary)
                    .padding(.top, 12)

                // Delete button for own photos
                if photo.uploadedBy == currentUserId {
                    Button(role: .destructive) {
                        Task {
                            try? await photoService.deletePhoto(photoId: photo.id)
                            dismiss()
                        }
                    } label: {
                        Label("Delete Photo", systemImage: "trash")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(hex: "EF5350"))
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "EF5350").opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }

                Spacer()
            }
            .background(AppConstants.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppConstants.Colors.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
