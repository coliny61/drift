import SwiftUI

struct EventRecapView: View {
    let eventId: UUID
    @Environment(PhotoService.self) private var photoService

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            if photoService.photos.isEmpty {
                EmptyStateView(
                    icon: "photo.on.rectangle.angled",
                    title: "No Photos Yet",
                    message: "Be the first to share a photo from this event"
                )
                .padding(.top, 60)
            } else {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(photoService.photos) { photo in
                        AsyncImage(url: URL(string: photo.photoUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color(hex: "2A2A2A"))
                        }
                        .frame(height: 120)
                        .clipped()
                    }
                }
            }
        }
        .background(Color(hex: "0A0A0A"))
        .navigationTitle("Recap")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await photoService.fetchPhotos(eventId: eventId)
        }
    }
}
