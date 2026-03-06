import Foundation

@Observable
final class ChatViewModel {
    private let chatService: ChatService

    var messages: [ChatMessage] { chatService.messages }
    var isLoading: Bool { chatService.isLoading }
    var messageText = ""
    var isSubscribed = false
    var sendError: String?

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    func loadMessages(eventId: UUID) async {
        await chatService.fetchMessages(eventId: eventId)
    }

    func sendMessage(eventId: UUID, senderId: UUID) async {
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        let savedText = messageText
        messageText = ""
        sendError = nil
        do {
            try await chatService.sendMessage(eventId: eventId, senderId: senderId, content: content)
            HapticManager.impact(.light)
        } catch {
            messageText = savedText
            sendError = "Failed to send message. Try again."
            HapticManager.notification(.error)
        }
    }

    func deleteMessage(messageId: UUID) async {
        try? await chatService.deleteMessage(messageId: messageId)
    }

    func subscribe(eventId: UUID) async {
        isSubscribed = true
        await chatService.subscribeToMessages(eventId: eventId)
    }

    func unsubscribe() async {
        isSubscribed = false
        await chatService.unsubscribe()
    }
}
