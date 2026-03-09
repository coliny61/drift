import SwiftUI

struct AvatarView: View {
    let url: String?
    let size: CGFloat
    var fallbackInitials: String = "?"

    var body: some View {
        Group {
            if let url, let imageURL = URL(string: url) {
                CachedAsyncImage(url: imageURL) {
                    initialsView
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppConstants.Colors.accent.opacity(0.25), AppConstants.Colors.accent.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(fallbackInitials)
                .font(size > 50 ? .title3 : size > 30 ? .body : .caption)
                .fontWeight(.bold)
                .foregroundStyle(AppConstants.Colors.accent)
        }
    }
}

struct AvatarStackView: View {
    let urls: [String?]
    let size: CGFloat
    let maxDisplay: Int
    let totalCount: Int

    var body: some View {
        HStack(spacing: -(size * 0.3)) {
            ForEach(Array(urls.prefix(maxDisplay).enumerated()), id: \.offset) { index, url in
                AvatarView(url: url, size: size)
                    .overlay(Circle().strokeBorder(AppConstants.Colors.cardBackground, lineWidth: 2))
                    .zIndex(Double(maxDisplay - index))
            }

            if totalCount > maxDisplay {
                Text("+\(totalCount - maxDisplay)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: size, height: size)
                    .background(AppConstants.Colors.accent)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(AppConstants.Colors.cardBackground, lineWidth: 2))
            }
        }
    }
}
