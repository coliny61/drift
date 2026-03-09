import Foundation
import Supabase

@Observable
final class DirectMessageService {
    private let client: SupabaseClient
    var conversations: [DMConversation] = []
    var messages: [DirectMessage] = []
    var isLoading = false
    var messageText = ""
    var sendError: String?

    private var realtimeChannel: RealtimeChannelV2?

    var unreadCount: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchConversations(userId: UUID) async {
        isLoading = true
        do {
            // Fetch all DMs involving this user
            let sent: [DirectMessage] = try await client.from("direct_messages")
                .select()
                .eq("sender_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            let received: [DirectMessage] = try await client.from("direct_messages")
                .select()
                .eq("recipient_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            // Group by other user
            var convMap: [UUID: (messages: [DirectMessage], otherUserId: UUID)] = [:]
            for msg in sent {
                convMap[msg.recipientId, default: ([], msg.recipientId)].messages.append(msg)
            }
            for msg in received {
                convMap[msg.senderId, default: ([], msg.senderId)].messages.append(msg)
            }

            // Build conversations
            var result: [DMConversation] = []
            for (otherUserId, data) in convMap {
                guard let latest = data.messages.sorted(by: { $0.createdAt > $1.createdAt }).first else { continue }
                let unread = data.messages.filter { $0.recipientId == userId && $0.readAt == nil }.count

                // Fetch other user's profile
                let profile: Profile? = try? await client.from("profiles")
                    .select()
                    .eq("id", value: otherUserId.uuidString)
                    .single()
                    .execute()
                    .value

                result.append(DMConversation(
                    id: otherUserId,
                    otherUser: profile,
                    lastMessage: latest,
                    unreadCount: unread
                ))
            }

            conversations = result.sorted { $0.lastMessage.createdAt > $1.lastMessage.createdAt }
        } catch {
            print("DirectMessageService: failed to fetch conversations — \(error)")
        }
        isLoading = false
    }

    func fetchThread(userId: UUID, otherUserId: UUID) async {
        isLoading = true
        do {
            let sentMsgs: [DirectMessage] = try await client.from("direct_messages")
                .select()
                .eq("sender_id", value: userId.uuidString)
                .eq("recipient_id", value: otherUserId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value

            let receivedMsgs: [DirectMessage] = try await client.from("direct_messages")
                .select()
                .eq("sender_id", value: otherUserId.uuidString)
                .eq("recipient_id", value: userId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value

            messages = (sentMsgs + receivedMsgs).sorted { $0.createdAt < $1.createdAt }

            // Mark received as read
            let unreadIds = receivedMsgs.filter { $0.readAt == nil }.map(\.id)
            if !unreadIds.isEmpty {
                await markAsRead(messageIds: unreadIds)
            }
        } catch {
            print("DirectMessageService: failed to fetch thread — \(error)")
        }
        isLoading = false
    }

    func sendMessage(senderId: UUID, recipientId: UUID) async {
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        messageText = ""
        sendError = nil

        do {
            try await client.from("direct_messages")
                .insert([
                    "sender_id": senderId.uuidString,
                    "recipient_id": recipientId.uuidString,
                    "content": text
                ] as [String: String])
                .execute()
        } catch {
            sendError = "Failed to send"
            messageText = text
            print("DirectMessageService: failed to send — \(error)")
        }
    }

    func markAsRead(messageIds: [UUID]) async {
        for id in messageIds {
            try? await client.from("direct_messages")
                .update(["read_at": ISO8601DateFormatter().string(from: .now)] as [String: String])
                .eq("id", value: id.uuidString)
                .execute()
        }
    }

    func subscribe(userId: UUID, otherUserId: UUID) async {
        let channel = client.realtimeV2.channel("dm:\(userId.uuidString):\(otherUserId.uuidString)")

        let changes = channel.postgresChange(InsertAction.self, table: "direct_messages")

        await channel.subscribe()

        Task {
            for await change in changes {
                if let msg = try? change.decodeRecord(as: DirectMessage.self, decoder: .init()) {
                    // Only add if it's part of this conversation
                    let isSent = msg.senderId == userId && msg.recipientId == otherUserId
                    let isReceived = msg.senderId == otherUserId && msg.recipientId == userId
                    if isSent || isReceived {
                        await MainActor.run {
                            if !self.messages.contains(where: { $0.id == msg.id }) {
                                self.messages.append(msg)
                            }
                        }
                    }
                }
            }
        }

        realtimeChannel = channel
    }

    func unsubscribe() async {
        if let channel = realtimeChannel {
            await client.realtimeV2.removeChannel(channel)
            realtimeChannel = nil
        }
    }
}
