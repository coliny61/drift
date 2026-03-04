import Foundation
import Supabase

@Observable
final class PhotoService {
    private let client: SupabaseClient

    var photos: [EventPhoto] = []
    var isLoading = false

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchPhotos(eventId: UUID) async {
        isLoading = true
        do {
            let response: [EventPhoto] = try await client.from("event_photos")
                .select()
                .eq("event_id", value: eventId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            photos = response
        } catch {
            print("Error fetching photos: \(error)")
        }
        isLoading = false
    }

    func uploadPhoto(eventId: UUID, userId: UUID, imageData: Data, caption: String?) async throws -> EventPhoto {
        let fileName = "\(eventId.uuidString)/\(UUID().uuidString).jpg"

        try await client.storage.from("event-photos")
            .upload(fileName, data: imageData, options: .init(contentType: "image/jpeg"))

        let publicURL = try client.storage.from("event-photos").getPublicURL(path: fileName)

        var photoEntry: [String: String] = [
            "event_id": eventId.uuidString,
            "uploaded_by": userId.uuidString,
            "photo_url": publicURL.absoluteString
        ]
        if let caption {
            photoEntry["caption"] = caption
        }

        let photo: EventPhoto = try await client.from("event_photos")
            .insert(photoEntry)
            .select()
            .single()
            .execute()
            .value

        return photo
    }

    func deletePhoto(photoId: UUID) async throws {
        try await client.from("event_photos")
            .delete()
            .eq("id", value: photoId.uuidString)
            .execute()
        photos.removeAll { $0.id == photoId }
    }

    func addReaction(photoId: UUID, userId: UUID, reactionType: String) async throws {
        try await client.from("photo_reactions")
            .upsert([
                "photo_id": photoId.uuidString,
                "user_id": userId.uuidString,
                "reaction_type": reactionType
            ])
            .execute()
    }
}
