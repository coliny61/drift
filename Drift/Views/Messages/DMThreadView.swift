import SwiftUI

struct DMThreadView: View {
    let otherUserId: UUID
    @Environment(DirectMessageService.self) private var dmService
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(BlockService.self) private var blockService
    @State private var isSending = false

    private var currentUserId: UUID {
        authViewModel.currentProfile?.id ?? authViewModel.localUserId
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    if dmService.messages.isEmpty && !dmService.isLoading {
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 36, weight: .light))
                                .foregroundStyle(AppConstants.Colors.textTertiary)
                            Text("No messages yet")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Say hello!")
                                .font(.subheadline)
                                .foregroundStyle(AppConstants.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(dmService.messages) { message in
                                messageBubble(message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: dmService.messages.count) { _, _ in
                    if let last = dmService.messages.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider().background(AppConstants.Colors.secondaryBackground)

            // Send error
            if let sendError = dmService.sendError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(sendError)
                }
                .font(.caption)
                .foregroundStyle(AppConstants.Colors.error)
                .padding(.horizontal)
                .padding(.top, 6)
                .onTapGesture { dmService.sendError = nil }
            }

            // Input — hidden if blocked
            if !blockService.isBlocked(otherUserId) {
                HStack(spacing: 12) {
                    TextField("Message...", text: Bindable(dmService).messageText)
                        .padding(12)
                        .background(AppConstants.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .foregroundStyle(.white)

                    Button {
                        isSending = true
                        Task {
                            await dmService.sendMessage(senderId: currentUserId, recipientId: otherUserId)
                            await dmService.fetchThread(userId: currentUserId, otherUserId: otherUserId)
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
                                    dmService.messageText.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? AppConstants.Colors.textSecondary : AppConstants.Colors.accent
                                )
                        }
                    }
                    .accessibilityLabel("Send message")
                    .disabled(dmService.messageText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(AppConstants.Colors.background)
            }
        }
        .background(AppConstants.Colors.background)
        .navigationTitle("Message")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await dmService.fetchThread(userId: currentUserId, otherUserId: otherUserId)
            await dmService.subscribe(userId: currentUserId, otherUserId: otherUserId)
        }
        .onDisappear {
            Task { await dmService.unsubscribe() }
        }
    }

    private func messageBubble(_ message: DirectMessage) -> some View {
        let isOwn = message.senderId == currentUserId
        return HStack {
            if isOwn { Spacer() }

            VStack(alignment: isOwn ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(isOwn ? AppConstants.Colors.accent : AppConstants.Colors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .contextMenu {
                        if !isOwn {
                            Button(role: .destructive) {
                                Task { await blockService.blockUser(blockerId: currentUserId, blockedId: message.senderId) }
                            } label: {
                                Label("Block User", systemImage: "hand.raised")
                            }
                        }
                    }

                Text(message.createdAt.timeOnly)
                    .font(.caption2)
                    .foregroundStyle(AppConstants.Colors.textTertiary)
            }

            if !isOwn { Spacer() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(isOwn ? "You" : "Them"): \(message.content), \(message.createdAt.timeOnly)")
    }
}
