import SwiftUI

struct EventPinView: View {
    let event: Event
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(categoryColor)
                    .frame(width: isSelected ? 44 : 32, height: isSelected ? 44 : 32)
                    .shadow(color: categoryColor.opacity(0.4), radius: isSelected ? 8 : 4)

                Image(systemName: event.categoryEnum?.icon ?? "star")
                    .font(isSelected ? .body : .caption)
                    .foregroundStyle(.white)
            }

            // Triangle pointer
            Triangle()
                .fill(categoryColor)
                .frame(width: 12, height: 6)
        }
        .animation(.spring(duration: 0.2), value: isSelected)
    }

    private var categoryColor: Color {
        Color(hex: event.categoryEnum?.color ?? "FF6B35")
    }
}

struct ClusterPinView: View {
    let count: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(AppConstants.Colors.accent)
                .frame(width: 40, height: 40)
                .shadow(color: AppConstants.Colors.accent.opacity(0.4), radius: 6)

            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
        }
    }
}
