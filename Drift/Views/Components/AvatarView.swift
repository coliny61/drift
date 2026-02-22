import SwiftUI

struct AvatarView: View {
    let url: String?
    let size: CGFloat
    var fallbackInitials: String = "?"

    var body: some View {
        Group {
            if let url, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    initialsView
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "2A2A2A"))
            Text(fallbackInitials)
                .font(size > 30 ? .body : .caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color(hex: "9CA3AF"))
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
                    .overlay(Circle().strokeBorder(Color(hex: "1A1A1A"), lineWidth: 2))
                    .zIndex(Double(maxDisplay - index))
            }

            if totalCount > maxDisplay {
                Text("+\(totalCount - maxDisplay)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: size, height: size)
                    .background(Color(hex: "FF6B35"))
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color(hex: "1A1A1A"), lineWidth: 2))
            }
        }
    }
}
