import Foundation
import Supabase

enum StorageService {
    static func uploadAvatar(client: SupabaseClient, userId: UUID, imageData: Data) async throws -> String {
        let fileName = "\(userId.uuidString).jpg"

        try await client.storage.from("avatars")
            .upload(fileName, data: imageData, options: .init(contentType: "image/jpeg", upsert: true))

        let publicURL = try client.storage.from("avatars").getPublicURL(path: fileName)
        return publicURL.absoluteString
    }

    static func uploadCoverImage(client: SupabaseClient, eventId: UUID, imageData: Data) async throws -> String {
        let fileName = "\(eventId.uuidString).jpg"

        try await client.storage.from("cover-images")
            .upload(fileName, data: imageData, options: .init(contentType: "image/jpeg", upsert: true))

        let publicURL = try client.storage.from("cover-images").getPublicURL(path: fileName)
        return publicURL.absoluteString
    }
}
