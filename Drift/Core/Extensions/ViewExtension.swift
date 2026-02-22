import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .background(AppConstants.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius))
    }

    func chipStyle(isSelected: Bool = false, color: Color = AppConstants.Colors.accent) -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? color.opacity(0.2) : AppConstants.Colors.secondaryBackground)
            .foregroundStyle(isSelected ? color : AppConstants.Colors.textSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? color.opacity(0.5) : Color.clear, lineWidth: 1)
            )
    }
}
