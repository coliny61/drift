import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppConstants.Colors.accent.opacity(0.06))
                    .frame(width: 100, height: 100)
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(AppConstants.Colors.textTertiary)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppConstants.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 40)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 13)
                        .background(AppConstants.Colors.accent)
                        .clipShape(Capsule())
                        .shadow(color: AppConstants.Colors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
