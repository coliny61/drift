import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.08),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = UIScreen.main.bounds.width
                    }
                }
            }
            .clipped()
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

/// Skeleton placeholder that mimics an EventCardView
struct SkeletonEventCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image area
            Rectangle()
                .fill(AppConstants.Colors.secondaryBackground)
                .frame(height: 200)
                .shimmer()
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16))

            // Content area
            VStack(alignment: .leading, spacing: 8) {
                // Title
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppConstants.Colors.secondaryBackground)
                    .frame(height: 18)
                    .frame(maxWidth: 220)
                    .shimmer()

                // Location
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppConstants.Colors.secondaryBackground)
                    .frame(height: 14)
                    .frame(maxWidth: 160)
                    .shimmer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(AppConstants.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// Loading skeleton for the Discover feed
struct SkeletonFeedView: View {
    var body: some View {
        LazyVStack(spacing: 20) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonEventCard()
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
}
