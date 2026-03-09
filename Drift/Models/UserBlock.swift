import Foundation

struct UserBlock: Codable, Identifiable {
    let id: UUID
    let blockerId: UUID
    let blockedId: UUID
    let createdAt: Date
}
