import Foundation
import Supabase
import Realtime

@Observable
final class ChatService {
    private let client: SupabaseClient
    private var channel: RealtimeChannelV2?

    var messages: [ChatMessage] = []
    var isLoading = false

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchMessages(eventId: UUID) async {
        isLoading = true
        do {
            let response: [ChatMessage] = try await client.from("chat_messages")
                .select()
                .eq("event_id", value: eventId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value
            messages = response
        } catch {
            print("Error fetching messages: \(error)")
        }
        isLoading = false
    }

    func sendMessage(eventId: UUID, senderId: UUID, content: String) async throws {
        let message = [
            "event_id": eventId.uuidString,
            "sender_id": senderId.uuidString,
            "content": content
        ]
        try await client.from("chat_messages")
            .insert(message)
            .execute()
    }

    func subscribeToMessages(eventId: UUID) async {
        let channel = client.realtimeV2.channel("chat:\(eventId.uuidString)")

        let insertions = channel.postgresChange(InsertAction.self, table: "chat_messages")

        await channel.subscribe()
        self.channel = channel

        for await insertion in insertions {
            do {
                let message = try insertion.decodeRecord(as: ChatMessage.self, decoder: JSONDecoder())
                await MainActor.run {
                    self.messages.append(message)
                }
            } catch {
                print("Error decoding message: \(error)")
            }
        }
    }

    func unsubscribe() async {
        if let channel {
            await client.realtimeV2.removeChannel(channel)
        }
        channel = nil
    }
}
