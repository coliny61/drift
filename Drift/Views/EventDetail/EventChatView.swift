import SwiftUI

struct EventChatView: View {
    let eventId: UUID
    @Environment(ChatViewModel.self) private var viewModel
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        chatBubble(message)
                    }
                }
                .padding()
            }

            Divider().background(Color(hex: "2A2A2A"))

            // Input
            HStack(spacing: 12) {
                TextField("Message...", text: Bindable(viewModel).messageText)
                    .padding(12)
                    .background(Color(hex: "1A1A1A"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .foregroundStyle(.white)

                Button {
                    guard let userId = authViewModel.currentProfile?.id else { return }
                    Task { await viewModel.sendMessage(eventId: eventId, senderId: userId) }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            viewModel.messageText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color(hex: "9CA3AF") : Color(hex: "FF6B35")
                        )
                }
                .disabled(viewModel.messageText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(hex: "0A0A0A"))
        }
        .background(Color(hex: "0A0A0A"))
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.loadMessages(eventId: eventId)
            await viewModel.subscribe(eventId: eventId)
        }
        .onDisappear {
            Task { await viewModel.unsubscribe() }
        }
    }

    private func chatBubble(_ message: ChatMessage) -> some View {
        let isOwn = message.senderId == authViewModel.currentProfile?.id
        return HStack {
            if isOwn { Spacer() }

            VStack(alignment: isOwn ? .trailing : .leading, spacing: 4) {
                if !isOwn {
                    Text(message.sender?.displayName ?? "User")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "FF6B35"))
                }
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(isOwn ? Color(hex: "FF6B35") : Color(hex: "2A2A2A"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(message.createdAt.timeOnly)
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "9CA3AF"))
            }

            if !isOwn { Spacer() }
        }
    }
}
