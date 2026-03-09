import Foundation
import Supabase

@Observable
final class BlockService {
    private let client: SupabaseClient
    var blockedIds: Set<UUID> = []

    init(client: SupabaseClient) {
        self.client = client
    }

    func loadBlockedUsers(userId: UUID) async {
        do {
            let blocks: [UserBlock] = try await client.from("user_blocks")
                .select()
                .eq("blocker_id", value: userId.uuidString)
                .execute()
                .value
            blockedIds = Set(blocks.map(\.blockedId))
        } catch {
            print("BlockService: failed to load blocks — \(error)")
        }
    }

    func blockUser(blockerId: UUID, blockedId: UUID) async {
        do {
            try await client.from("user_blocks")
                .insert([
                    "blocker_id": blockerId.uuidString,
                    "blocked_id": blockedId.uuidString
                ] as [String: String])
                .execute()
            blockedIds.insert(blockedId)
            HapticManager.impact(.medium)
        } catch {
            print("BlockService: failed to block — \(error)")
        }
    }

    func unblockUser(blockerId: UUID, blockedId: UUID) async {
        do {
            try await client.from("user_blocks")
                .delete()
                .eq("blocker_id", value: blockerId.uuidString)
                .eq("blocked_id", value: blockedId.uuidString)
                .execute()
            blockedIds.remove(blockedId)
            HapticManager.selection()
        } catch {
            print("BlockService: failed to unblock — \(error)")
        }
    }

    func isBlocked(_ userId: UUID) -> Bool {
        blockedIds.contains(userId)
    }
}
