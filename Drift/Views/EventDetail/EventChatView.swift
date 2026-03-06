import SwiftUI

struct EventChatView: View {
    let eventId: UUID
    @Environment(ChatViewModel.self) private var viewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var isSending = false

    private var currentUserId: UUID {
        authViewModel.currentProfile?.id ?? authViewModel.localUserId
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    if viewModel.messages.isEmpty && !viewModel.isLoading {
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 36, weight: .light))
                                .foregroundStyle(AppConstants.Colors.textTertiary)
                            Text("No messages yet")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Be the first to say something!")
                                .font(.subheadline)
                                .foregroundStyle(AppConstants.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                chatBubble(message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let last = viewModel.messages.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider().background(AppConstants.Colors.secondaryBackground)

            // Send error
            if let sendError = viewModel.sendError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(sendError)
                }
                .font(.caption)
                .foregroundStyle(AppConstants.Colors.error)
                .padding(.horizontal)
                .padding(.top, 6)
                .onTapGesture { viewModel.sendError = nil }
            }

            // Input
            HStack(spacing: 12) {
                TextField("Message...", text: Bindable(viewModel).messageText)
                    .padding(12)
                    .background(AppConstants.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .foregroundStyle(.white)

                Button {
                    isSending = true
                    Task {
                        await viewModel.sendMessage(eventId: eventId, senderId: currentUserId)
                        isSending = false
                    }
                } label: {
                    if isSending {
                        ProgressView()
                            .tint(AppConstants.Colors.accent)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                viewModel.messageText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? AppConstants.Colors.textSecondary : AppConstants.Colors.accent
                            )
                    }
                }
                .disabled(viewModel.messageText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(AppConstants.Colors.background)
        }
        .background(AppConstants.Colors.background)
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
        let isOwn = message.senderId == currentUserId
        return HStack {
            if isOwn { Spacer() }

            VStack(alignment: isOwn ? .trailing : .leading, spacing: 4) {
                if !isOwn {
                    Text(message.sender?.displayName ?? "User")
                        .font(.caption)
                        .foregroundStyle(AppConstants.Colors.accent)
                }
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(isOwn ? AppConstants.Colors.accent : AppConstants.Colors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .contextMenu {
                        if isOwn {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteMessage(messageId: message.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }

                Text(message.createdAt.timeOnly)
                    .font(.caption2)
                    .foregroundStyle(AppConstants.Colors.textTertiary)
            }

            if !isOwn { Spacer() }
        }
    }
}
